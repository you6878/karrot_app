import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";
import * as dotenv from "dotenv";
import * as path from "path";

// .env 파일 로드 (functions 폴더 기준)
dotenv.config({ path: path.resolve(__dirname, "../.env") });

// Firebase Admin 초기화
admin.initializeApp();

const db = admin.firestore();

// 토스페이먼츠 시크릿 키 (환경변수에서 가져오기)
const TOSS_SECRET_KEY = process.env.TOSS_SECRET_KEY || "";

// 디버그: 환경변수 로드 확인 (배포 후 삭제 권장)
functions.logger.info("TOSS_SECRET_KEY loaded:", TOSS_SECRET_KEY ? "Yes (length: " + TOSS_SECRET_KEY.length + ")" : "No");

interface PaymentConfirmRequest {
  paymentKey: string;
  orderId: string;
  amount: number;
}

interface MembershipData {
  userId: string;
  planType: "monthly" | "yearly";
  amount: number;
  paymentKey: string;
  orderId: string;
  startDate: admin.firestore.Timestamp;
  endDate: admin.firestore.Timestamp;
  status: "active" | "expired" | "cancelled";
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

/**
 * 토스페이먼츠 결제 승인 Cloud Function
 * 클라이언트에서 결제 완료 후 호출하여 서버에서 최종 승인
 */
export const confirmPayment = functions
  .region("asia-northeast3")
  .https.onCall(async (data: PaymentConfirmRequest, context) => {
    // 인증 확인
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }

    const {paymentKey, orderId, amount} = data;

    // 필수 파라미터 검증
    if (!paymentKey || !orderId || !amount) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "필수 파라미터가 누락되었습니다."
      );
    }

    // 시크릿 키 검증
    if (!TOSS_SECRET_KEY) {
      functions.logger.error("TOSS_SECRET_KEY가 설정되지 않았습니다.");
      throw new functions.https.HttpsError(
        "internal",
        "결제 설정 오류가 발생했습니다."
      );
    }

    try {
      // 토스페이먼츠 결제 승인 API 호출
      const secretKeyBase64 = Buffer
        .from(TOSS_SECRET_KEY + ":")
        .toString("base64");

      const response = await axios.post(
        "https://api.tosspayments.com/v1/payments/confirm",
        {
          paymentKey,
          orderId,
          amount,
        },
        {
          headers: {
            "Authorization": `Basic ${secretKeyBase64}`,
            "Content-Type": "application/json",
          },
        }
      );

      const paymentResult = response.data;

      functions.logger.info("결제 승인 성공:", {
        orderId,
        paymentKey,
        amount,
        userId: context.auth.uid,
      });

      return {
        success: true,
        data: paymentResult,
      };
    } catch (error) {
      functions.logger.error("결제 승인 실패:", error);

      if (axios.isAxiosError(error) && error.response) {
        const tossError = error.response.data;
        throw new functions.https.HttpsError(
          "aborted",
          tossError.message || "결제 승인에 실패했습니다."
        );
      }

      throw new functions.https.HttpsError(
        "internal",
        "결제 처리 중 오류가 발생했습니다."
      );
    }
  });

/**
 * 멤버십 가입 처리 Cloud Function
 * 결제 승인 후 멤버십 정보를 Firestore에 저장
 */
export const createMembership = functions
  .region("asia-northeast3")
  .https.onCall(async (data, context) => {
    // 인증 확인
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }

    const {paymentKey, orderId, amount, planType} = data;
    const userId = context.auth.uid;

    // 필수 파라미터 검증
    if (!paymentKey || !orderId || !amount || !planType) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "필수 파라미터가 누락되었습니다."
      );
    }

    try {
      const now = admin.firestore.Timestamp.now();
      const startDate = now;
      let endDate: admin.firestore.Timestamp;

      // 플랜 타입에 따른 종료일 계산
      if (planType === "monthly") {
        const endDateJs = new Date();
        endDateJs.setMonth(endDateJs.getMonth() + 1);
        endDate = admin.firestore.Timestamp.fromDate(endDateJs);
      } else if (planType === "yearly") {
        const endDateJs = new Date();
        endDateJs.setFullYear(endDateJs.getFullYear() + 1);
        endDate = admin.firestore.Timestamp.fromDate(endDateJs);
      } else {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "유효하지 않은 플랜 타입입니다."
        );
      }

      // 기존 활성 멤버십 확인
      const existingMembership = await db
        .collection("memberships")
        .where("userId", "==", userId)
        .where("status", "==", "active")
        .get();

      // 기존 멤버십이 있으면 만료 처리
      const batch = db.batch();
      existingMembership.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: "expired",
          updatedAt: now,
        });
      });

      // 새 멤버십 생성
      const membershipData: MembershipData = {
        userId,
        planType,
        amount,
        paymentKey,
        orderId,
        startDate,
        endDate,
        status: "active",
        createdAt: now,
        updatedAt: now,
      };

      const membershipRef = db.collection("memberships").doc();
      batch.set(membershipRef, membershipData);

      // 사용자 문서에 멤버십 상태 업데이트
      const userRef = db.collection("users").doc(userId);
      batch.update(userRef, {
        isMember: true,
        membershipId: membershipRef.id,
        membershipEndDate: endDate,
        updatedAt: now,
      });

      await batch.commit();

      functions.logger.info("멤버십 생성 성공:", {
        membershipId: membershipRef.id,
        userId,
        planType,
      });

      return {
        success: true,
        membershipId: membershipRef.id,
        endDate: endDate.toDate().toISOString(),
      };
    } catch (error) {
      functions.logger.error("멤버십 생성 실패:", error);
      throw new functions.https.HttpsError(
        "internal",
        "멤버십 생성 중 오류가 발생했습니다."
      );
    }
  });

/**
 * 멤버십 상태 확인 Cloud Function
 */
export const checkMembershipStatus = functions
  .region("asia-northeast3")
  .https.onCall(async (data, context) => {
    // 인증 확인
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }

    const userId = context.auth.uid;

    try {
      const membershipSnapshot = await db
        .collection("memberships")
        .where("userId", "==", userId)
        .where("status", "==", "active")
        .orderBy("createdAt", "desc")
        .limit(1)
        .get();

      if (membershipSnapshot.empty) {
        return {
          isMember: false,
          membership: null,
        };
      }

      const membership = membershipSnapshot.docs[0].data();
      const endDate = membership.endDate.toDate();
      const now = new Date();

      // 만료 확인
      if (endDate < now) {
        // 만료된 멤버십 상태 업데이트
        await membershipSnapshot.docs[0].ref.update({
          status: "expired",
          updatedAt: admin.firestore.Timestamp.now(),
        });

        await db.collection("users").doc(userId).update({
          isMember: false,
          updatedAt: admin.firestore.Timestamp.now(),
        });

        return {
          isMember: false,
          membership: null,
        };
      }

      return {
        isMember: true,
        membership: {
          id: membershipSnapshot.docs[0].id,
          planType: membership.planType,
          startDate: membership.startDate.toDate().toISOString(),
          endDate: endDate.toISOString(),
          status: membership.status,
        },
      };
    } catch (error) {
      functions.logger.error("멤버십 상태 확인 실패:", error);
      throw new functions.https.HttpsError(
        "internal",
        "멤버십 상태 확인 중 오류가 발생했습니다."
      );
    }
  });

/**
 * 결제 취소 Cloud Function
 */
export const cancelPayment = functions
  .region("asia-northeast3")
  .https.onCall(async (data, context) => {
    // 인증 확인
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }

    const {paymentKey, cancelReason} = data;

    if (!paymentKey || !cancelReason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "필수 파라미터가 누락되었습니다."
      );
    }

    if (!TOSS_SECRET_KEY) {
      throw new functions.https.HttpsError(
        "internal",
        "결제 설정 오류가 발생했습니다."
      );
    }

    try {
      const secretKeyBase64 = Buffer
        .from(TOSS_SECRET_KEY + ":")
        .toString("base64");

      const response = await axios.post(
        `https://api.tosspayments.com/v1/payments/${paymentKey}/cancel`,
        {
          cancelReason,
        },
        {
          headers: {
            "Authorization": `Basic ${secretKeyBase64}`,
            "Content-Type": "application/json",
          },
        }
      );

      functions.logger.info("결제 취소 성공:", {
        paymentKey,
        userId: context.auth.uid,
      });

      return {
        success: true,
        data: response.data,
      };
    } catch (error) {
      functions.logger.error("결제 취소 실패:", error);

      if (axios.isAxiosError(error) && error.response) {
        throw new functions.https.HttpsError(
          "aborted",
          error.response.data.message || "결제 취소에 실패했습니다."
        );
      }

      throw new functions.https.HttpsError(
        "internal",
        "결제 취소 중 오류가 발생했습니다."
      );
    }
  });


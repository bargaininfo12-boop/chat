/**
 * File: functions/src/index.ts
 * Version: 1.0.10
 * Date: 2025-03-15
 * Description: Cloud Functions for updating user online status (Realtime Database trigger)
 *              and sending notifications on new messages (Firestore trigger),
 *              both deployed in region us-central1.
 */

import * as admin from "firebase-admin";
// Import v1 API explicitly
import * as functions from "firebase-functions/v1";

admin.initializeApp();

/**
 * onUserStatusChanged:
 * Realtime Database trigger jo "/status/{userId}" par update hone par,
 * Firestore mein user ka online status update karta hai.
 */
export const onUserStatusChanged = functions
  .region("us-central1")
  .database.ref("/status/{userId}")
  .onUpdate(async (
    change: functions.Change<admin.database.DataSnapshot>,
    context: any  // Using 'any' for EventContext to bypass type errors
  ) => {
    const userId = context.params.userId;
    const status = change.after.val();
    const isOnline = status.isOnline;

    try {
      const userDocRef = admin.firestore().collection("users").doc(userId);
      const userDoc = await userDocRef.get();

      if (userDoc.exists) {
        const currentLastSeen = userDoc.data()?.lastSeen;
        const shouldUpdate =
          isOnline ||
          currentLastSeen == null ||
          status.lastSeen.toString().localeCompare(currentLastSeen.toString()) > 0;

        if (shouldUpdate) {
          await userDocRef.update({
            isOnline: isOnline,
            lastSeen: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      } else {
        await userDocRef.set({
          isOnline: isOnline,
          lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      console.log(`User status updated for user: ${userId}`);
    } catch (error) {
      console.error("Error updating user status in Firestore:", error);
    }
  });

/**
 * sendNotificationOnNewMessage:
 * Firestore trigger jo "conversations/{conversationId}/messages/{messageId}" document ke creation par,
 * receiver ke FCM token par notification bhejta hai.
 */
export const sendNotificationOnNewMessage = functions
  .region("us-central1")
  .firestore.document("conversations/{conversationId}/messages/{messageId}")
  .onCreate(async (
    snapshot: functions.firestore.DocumentSnapshot,
    context: any  // Using 'any' for EventContext to bypass type errors
  ) => {
    const messageData = snapshot.data();
    if (!messageData) {
      console.log("No message data found.");
      return null;
    }
    const { conversationId, messageId } = context.params;
    const receiverId: string = messageData.receiverId;
    const senderId: string = messageData.senderId;

    if (!receiverId) {
      console.log("No receiverId in message data.");
      return null;
    }

    try {
      const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
      if (!userDoc.exists) {
        console.log(`User document for receiver (${receiverId}) does not exist.`);
        return null;
      }
      const userData = userDoc.data();
      const fcmToken: string | undefined = userData?.fcmToken;
      if (!fcmToken) {
        console.log(`No FCM token available for receiver: ${receiverId}`);
        return null;
      }

      const payload = {
        notification: {
          title: "New Message",
          body: messageData.message || "You have received a new message",
          sound: "default",
        },
        data: {
          conversationId: conversationId,
          messageId: messageId,
          senderId: senderId || "",
        },
      };

      const response = await admin.messaging().sendToDevice(fcmToken, payload);
      console.log(`Notification sent to receiver ${receiverId}:`, response);
      return response;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  });

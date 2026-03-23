#!/usr/bin/env python3
"""Insert sendCommentLikeNotification function into index.js"""

fn_code = """
/**
 * Envia notificacao quando alguem curte um comentario
 *
 * Trigger: onUpdate em posts/{postId}/comments/{commentId}
 * Detecta novas curtidas comparando likedBy antes/depois.
 * Cria notificacao in-app + push notification para o autor do comentario.
 */
exports.sendCommentLikeNotification = functions
  .runWith({
    memory: "128MB",
    timeoutSeconds: 30,
  })
  .region("southamerica-east1")
  .firestore.document("posts/{postId}/comments/{commentId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const postId = context.params.postId;
    const commentId = context.params.commentId;

    const beforeLikedBy = before.likedBy || [];
    const afterLikedBy = after.likedBy || [];

    const beforeSet = new Set(beforeLikedBy);
    const newLikers = afterLikedBy.filter((id) => !beforeSet.has(id));

    if (newLikers.length === 0) {
      return null;
    }

    const commentAuthorProfileId = (after.authorProfileId || "").trim();
    const commentAuthorUid = (after.authorUid || "").trim();

    if (!commentAuthorProfileId || !commentAuthorUid) {
      console.log(
        "Comment like notification skipped: missing authorProfileId or authorUid",
      );
      return null;
    }

    for (const likerProfileId of newLikers) {
      if (likerProfileId === commentAuthorProfileId) {
        continue;
      }

      const rateLimitCheck = await checkRateLimit(
        likerProfileId,
        "commentLikes",
        200,
        24 * 60 * 60 * 1000,
      );
      if (!rateLimitCheck.allowed) {
        console.log(
          "Rate limit: " + likerProfileId + " excedeu limite de curtidas",
        );
        continue;
      }

      const [likerBlocksAuthor, authorBlocksLiker] = await Promise.all([
        isBlockedByProfile(
          likerProfileId,
          commentAuthorProfileId,
          "commentLike:" + commentId,
        ),
        isBlockedByProfile(
          commentAuthorProfileId,
          likerProfileId,
          "commentLike:" + commentId,
        ),
      ]);

      if (likerBlocksAuthor || authorBlocksLiker) {
        continue;
      }

      const authorProfileDoc = await db
        .collection("profiles")
        .doc(commentAuthorProfileId)
        .get();
      if (!authorProfileDoc.exists) continue;

      const authorProfileData = authorProfileDoc.data() || {};
      const authorUid = (authorProfileData.uid || "").trim();
      if (!authorUid) continue;

      const notifyComments = authorProfileData.notifyComments ?? true;
      if (!notifyComments) continue;

      const likerProfileDoc = await db
        .collection("profiles")
        .doc(likerProfileId)
        .get();
      const likerName = likerProfileDoc.exists
        ? likerProfileDoc.data().name || "Alguem"
        : "Alguem";
      const likerPhoto = likerProfileDoc.exists
        ? likerProfileDoc.data().photoUrl || null
        : null;

      const commentText = after.text || "";
      const commentPreview =
        commentText.length > 80
          ? commentText.substring(0, 80) + "..."
          : commentText;

      const notificationTitle = likerName + " curtiu seu comentario";
      const notificationBody = commentPreview;

      await db.collection("notifications").add({
        recipientProfileId: commentAuthorProfileId,
        recipientUid: authorUid,
        profileUid: commentAuthorProfileId,
        type: "comment_like",
        priority: "low",
        title: notificationTitle,
        body: notificationBody,
        actionType: "viewPost",
        actionData: {
          postId: postId,
          commentId: commentId,
          likerProfileId: likerProfileId,
          likerName: likerName,
        },
        senderName: likerName,
        senderPhoto: likerPhoto,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        ),
      });

      await sendPushToProfile(
        commentAuthorProfileId,
        authorUid,
        { title: notificationTitle, body: notificationBody },
        {
          type: "comment_like",
          postId: postId,
          commentId: commentId,
          likerProfileId: likerProfileId,
          recipientProfileId: commentAuthorProfileId,
        },
      );

      console.log(
        "Notificacao de curtida enviada: " +
          likerName +
          " -> " +
          commentAuthorProfileId,
      );
    }

    return null;
  });
"""

with open("index.js", "r") as f:
    lines = f.readlines()

# Insert after line 1047 (the `});` closing sendMessageNotification)
insert_idx = 1047
lines.insert(insert_idx, fn_code + "\n")

with open("index.js", "w") as f:
    f.writelines(lines)

print("Done. New line count:", sum(1 for _ in open("index.js")))

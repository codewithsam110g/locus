import {
  SignJWT,
  importPKCS8,
} from "https://deno.land/x/jose@v4.14.4/index.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

interface PrivateMessage {
  message: string;
  sent_by: string;
  chat_id: string;
}

interface WebhookPayload {
  type: "UPDATE";
  table: string;
  record: PrivateMessage;
  schema: "public";
  old_record: null | PrivateMessage;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

/**
 * Helper function that forwards log messages to the provided endpoint.
 */
// async function sendLog(message: string, data: any = {}): Promise<void> {
//   const logUrl = Deno.env.get("LOGGER_URL");
//   try {
//     await fetch(
//       logUrl,
//       {
//         method: "POST",
//         headers: { "Content-Type": "application/json" },
//         body: JSON.stringify({ log: message, data: data }),
//       },
//     );
//   } catch (error) {
//     // Fallback: if sending the log fails, output it to the local console.
//     console.error("Failed to send log:", error);
//   }
// }

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json();
    //await sendLog("Received webhook payload", payload);

    const { data: chat_data, error: chat_error } = await supabase
      .from("chats")
      .select("*")
      .eq("id", payload.record.chat_id)
      .single();

    //await sendLog("Retrieved chat data", { chat_data, chat_error });

    if (chat_error) {
      //await sendLog("Error fetching chat data", chat_error);
      return new Response(JSON.stringify({ error: "Chat not found" }), {
        status: 400,
      });
    }

    if (!chat_data || !chat_data.is_active) {
      //await sendLog("Chat is not active", { chat_id: payload.record.chat_id });
      return new Response(JSON.stringify({ message: "Chat is not active" }), {
        status: 200,
      });
    }

    const uid_1 = chat_data.uid_1;
    const uid_2 = chat_data.uid_2;

    let otherId = "";
    if (uid_1 == payload.record.sent_by) {
      otherId = uid_2;
    } else {
      otherId = uid_1;
    }

    // await sendLog("Identified message participants", {
    //   sender: payload.record.sent_by,
    //   receiver: otherId,
    // });

    const { data, error } = await supabase
      .from("profile")
      .select("user_id, fcm_token, name")
      .or(`user_id.eq.${payload.record.sent_by},user_id.eq.${otherId}`);

    //await sendLog("Retrieved profile data", { profiles: data, error });

    if (error) {
      //await sendLog("Error fetching profiles", error);
      return new Response(
        JSON.stringify({ error: "Failed to get user profiles" }),
        { status: 500 },
      );
    }

    if (!data || data.length !== 2) {
      //await sendLog("Unexpected profile data count", { count: data?.length });
      return new Response(JSON.stringify({ error: "Invalid profile data" }), {
        status: 500,
      });
    }

    // Correctly identify sender and receiver profiles
    const senderProfile = data.find(
      (profile) => profile.user_id === payload.record.sent_by,
    );
    const receiverProfile = data.find((profile) => profile.user_id === otherId);

    // await sendLog("Identified sender and receiver profiles", {
    //   sender: senderProfile,
    //   receiver: receiverProfile,
    // });

    if (!senderProfile || !receiverProfile) {
      // await sendLog("Could not identify sender or receiver", {
      //   data,
      //   sent_by: payload.record.sent_by,
      //   otherId,
      // });
      return new Response(
        JSON.stringify({ error: "User profiles not found" }),
        { status: 500 },
      );
    }

    if (!receiverProfile.fcm_token) {
      // await sendLog("Receiver has no FCM token", {
      //   receiver_id: receiverProfile.user_id,
      // });
      return new Response(
        JSON.stringify({ message: "No FCM token for receiver" }),
        { status: 200 },
      );
    }

    const email = Deno.env.get("FCM_EMAIL");
    const fcm_key = Deno.env.get("FCM_PRIVATE_KEY");
    const formattedKey = fcm_key.replace(/\\n/g, "\n");

    // await sendLog("Requesting FCM access token", { email });

    const accessToken = await getAccessToken({
      clientEmail: email,
      privateKey: formattedKey,
    });

    // await sendLog("Received FCM access token", {
    //   token_length: accessToken.length,
    // });

    const notificationPayload = {
      message: {
        token: receiverProfile.fcm_token,
        notification: {
          title: `${senderProfile.name} Sent you a Message`,
          body: payload.record.message,
        },
      },
    };

    // await sendLog("Preparing to send FCM notification", {
    //   receiver_token: receiverProfile.fcm_token.substring(0, 10) + "...",
    //   notification_title: `${senderProfile.name} Sent you a Message`,
    // });

    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/locus-d5ba9/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(notificationPayload),
      },
    );

    const fcmResponseBody = await fcmResponse.text();

    // await sendLog("FCM notification response", {
    //   status: fcmResponse.status,
    //   ok: fcmResponse.ok,
    //   body: fcmResponseBody,
    // });

    if (!fcmResponse.ok) {
      // await sendLog("FCM error", {
      //   status: fcmResponse.status,
      //   body: fcmResponseBody,
      // });
      return new Response(
        JSON.stringify({ error: "Failed to send notification" }),
        { status: 500 },
      );
    }

    // await sendLog("Successfully sent notification", {
    //   chat_id: payload.record.chat_id,
    // });
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (err) {
    // await sendLog("Error processing webhook", {
    //   error: err.toString(),
    //   stack: err.stack,
    // });
    console.error("Error processing webhook:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
    });
  }
});

/**
 * Fetch an OAuth2 access token for Firebase Cloud Messaging.
 */
const getAccessToken = async ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string;
  privateKey: string;
}): Promise<string> => {
  try {
    const now = Math.floor(Date.now() / 1000);
    const jwtPayload = {
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    };

    // await sendLog("Creating JWT for FCM authentication", {
    //   clientEmail,
    //   iat: now,
    //   exp: now + 3600,
    // });

    const jwt = await new SignJWT(jwtPayload)
      .setProtectedHeader({ alg: "RS256", typ: "JWT" })
      .sign(await importPKCS8(privateKey, "RS256"));

    //await sendLog("JWT created successfully", { jwt_length: jwt.length });

    const params = new URLSearchParams();
    params.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
    params.append("assertion", jwt);

    // await sendLog("Requesting OAuth token", {
    //   url: "https://oauth2.googleapis.com/token",
    // });

    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params.toString(),
    });

    const tokenJson = await tokenRes.json();

    // await sendLog("OAuth token response", {
    //   status: tokenRes.status,
    //   ok: tokenRes.ok,
    //   has_access_token: !!tokenJson.access_token,
    // });

    if (!tokenRes.ok) {
      // await sendLog("Failed to get access token", tokenJson);
      throw new Error(
        `Failed to get access token: ${JSON.stringify(tokenJson)}`,
      );
    }

    return tokenJson.access_token;
  } catch (error) {
    // await sendLog("Error in getAccessToken", {
    //   error: error.toString(),
    //   stack: error.stack,
    // });
    throw error;
  }
};

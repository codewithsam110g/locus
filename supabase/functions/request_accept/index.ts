import {
  SignJWT,
  importPKCS8,
} from "https://deno.land/x/jose@v4.14.4/index.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
interface _Request {
  status: string;
  requested_uid: string;
  reciever_uid: string;
}
interface WebhookPayload {
  type: "UPDATE";
  table: string;
  record: _Request;
  schema: "public";
  old_record: null | _Message;
}
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json();
    
    // Get requester's profile (the one who sent the request)
    const { data: requesterData, error: requesterError } = await supabase
      .from("profile")
      .select("fcm_token, name")
      .eq("user_id", payload.record.requested_uid)
      .single();
    
    // Get receiver's profile (the one who accepted the request)
    const { data: receiverData, error: receiverError } = await supabase
      .from("profile")
      .select("fcm_token, name")
      .eq("user_id", payload.record.reciever_uid)
      .single();
    
    const email = Deno.env.get("FCM_EMAIL");
    const fcm_key = Deno.env.get("FCM_PRIVATE_KEY");
    const formattedKey = fcm_key.replace(/\\n/g, "\n");
    const accessToken = await getAccessToken({
      clientEmail: email,
      privateKey: formattedKey
    });
    
    if(payload.record.status == "accept"){
      await fetch(
        `https://fcm.googleapis.com/v1/projects/locus-d5ba9/messages:send`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token: requesterData.fcm_token,
              notification: {
                title: "Request Accepted",
                body: `Your Request has been accepted by ${receiverData.name}`,
              },
            },
          }),
        },
      );
    }
  }
  catch(err){
    
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
  const now = Math.floor(Date.now() / 1000);
  const jwtPayload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const jwt = await new SignJWT(jwtPayload)
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .sign(await importPKCS8(privateKey, "RS256"));
  const params = new URLSearchParams();
  params.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
  params.append("assertion", jwt);
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params.toString(),
  });
  const tokenJson = await tokenRes.json();
  if (!tokenRes.ok) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenJson)}`);
  }
  return tokenJson.access_token;
};
import {
  SignJWT,
  importPKCS8,
} from "https://deno.land/x/jose@v4.14.4/index.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

interface Message {
  user_id: string;
  message: string;
  location: {
    lat: string;
    lng: string;
  };
}

interface WebhookPayload {
  type: "INSERT";
  table: string;
  record: Message;
  schema: "public";
  old_record: null | Message;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

/**
 * Helper function that forwards log messages to the provided endpoint.
 */
async function sendLog(message: string): Promise<void> {
  // try {
  //   await fetch(
  //     "https://1608-2409-40f0-31c5-25c3-9d43-9917-a4a6-4346.ngrok-free.app",
  //     {
  //       method: "POST",
  //       headers: { "Content-Type": "application/json" },
  //       body: JSON.stringify({ log: message }),
  //     },
  //   );
  // } catch (error) {
  //   // Fallback: if sending the log fails, output it to the local console.
  //   console.error("Failed to send log:", error);
  // }
}

Deno.serve(async (req) => {
  try {
    // Parse the incoming JSON payload.
    const payload: WebhookPayload = await req.json();
    await sendLog("Received payload: " + JSON.stringify(payload));

    const { lat, lng } = payload.record.location;

    // Fetch all users with their last location, range, and name.
    const { data, error } = await supabase
      .from("profile")
      .select("fcm_token, last_loc, range, name")
      .neq("user_id", payload.record.user_id);

    if (error) {
      throw new Error(`Supabase error: ${error.message}`);
    }

    // Log the output from the database pull for testing.
    await sendLog("Fetched profiles: " + JSON.stringify(data));
    await sendLog("Fetched profiles successfully.");

    // Filter users whose last location is within their range.
    const nearbyUsers = data.filter((user) => {
      // Ensure both last_loc and range are present.
      if (!user.last_loc || !user.range) return false;
      // Use the correct property names: "lat" and "long"
      const userLat = parseFloat(user.last_loc.lat);
      const userLng = parseFloat(user.last_loc.long); // <-- changed from lng to long
      const userRange = parseFloat(user.range);
      const messageLat = parseFloat(lat);
      const messageLng = parseFloat(lng);
      const distance = getDistance(messageLat, messageLng, userLat, userLng);
      // Optionally log the computed distance for debugging:
      sendLog(
        `Computed distance for ${user.name || user.fcm_token}: ${distance.toFixed(2)} meters (range: ${userRange})`,
      );
      return distance <= userRange;
    });
    await sendLog(`Found ${nearbyUsers.length} nearby users.`);

    if (nearbyUsers.length === 0) {
      return new Response(
        JSON.stringify({ message: "No nearby users found." }),
        { headers: { "Content-Type": "application/json" } },
      );
    }
    const email = Deno.env.get("FCM_EMAIL");
    const fcm_key = Deno.env.get("FCM_PRIVATE_KEY");
    const formattedKey = fcm_key.replace(/\\n/g, "\n");
    const accessToken = await getAccessToken({
      clientEmail:
        email,
      privateKey:formattedKey});

    await sendLog("Obtained access token, sending notifications.");

    // Send FCM message to all nearby users and log their distance.
    for (const user of nearbyUsers) {
      // Use the correct property name "long" from the database.
      const userLat = parseFloat(user.last_loc.lat);
      const userLng = parseFloat(user.last_loc.long);
      const messageLat = parseFloat(lat);
      const messageLng = parseFloat(lng);
      const distance = getDistance(messageLat, messageLng, userLat, userLng);
      const userName = user.name || user.fcm_token;
      await sendLog(`User ${userName} is ${distance.toFixed(2)} meters away.`);

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
              token: user.fcm_token,
              notification: {
                title: "Nearby Message",
                body: payload.record.message,
              },
            },
          }),
        },
      );
      await sendLog("Notification sent to user: " + user.fcm_token);
    }

    await sendLog("All notifications sent successfully.");
    return new Response(JSON.stringify({ message: "Notifications sent." }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    const errorMessage =
      "Error in function: " +
      (err instanceof Error ? err.message : String(err));
    await sendLog(errorMessage);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : err }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
});

/**
 * Calculate distance between two lat/lng points using the Haversine formula.
 */
const getDistance = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number => {
  const R = 6371; // Earth's radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c * 1000; // Distance in meters
};

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

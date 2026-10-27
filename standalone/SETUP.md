# Setting up Been There Atlas with free accounts and photos

This takes about 15 minutes. You do it once; after that your friends just visit the website, make an account, and start adding trips.

You need two free services:

- **Supabase** keeps everyone's accounts, trips and photos.
- **Netlify** puts the app on the internet so friends can open it.

## 1. Make a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up (free, no card needed).
2. Click **New project**. Give it a name like `been-there-atlas`, make up a database password (save it somewhere), and pick the region closest to you.
3. Wait a minute or two while it starts.

## 2. Create the tables and photo storage

1. In your project, open **SQL Editor** in the left menu and click **New query**.
2. Open the file `supabase-setup.sql` from this folder, copy everything in it, and paste it in.
3. Click **Run**. It should say "Success. No rows returned".

This sets up profiles, follow requests, trips, and two photo stores: private trip and country photos, and public profile pictures. It's safe to run again. If you update the app later and `supabase-setup.sql` has changed, paste and run the new version the same way.

## 3. Connect the app to your project

1. In Supabase, open **Project Settings → API** (on some versions it's under **Data API** or **API Keys**).
2. Copy the **Project URL** and the **anon public** key. Never use the key labelled `service_role` or `secret`.
3. Open `config.js` in this folder with any text editor and paste them between the quotes:

   ```js
   window.ATLAS_CONFIG = {
     supabaseUrl: "https://abcdefgh.supabase.co",
     supabaseAnonKey: "eyJhbGciOi..."
   };
   ```

4. Save the file.

## 4. Let people sign up without an email check

Supabase's built-in email sending is very limited on the free plan, so turn off the confirmation email:

1. Go to **Authentication → Sign In / Providers** (or **Providers → Email** on older versions).
2. Make sure **Email** is enabled, and switch **Confirm email** off.
3. Save.

Friends then sign up with an email and password and can use the app straight away. The catch: there's no "forgot password" email. If someone forgets theirs, you can delete their account in Supabase (**Authentication → Users**) so they can sign up again, but this also deletes their trips. To send real emails later, connect a free email service under **Authentication → Emails → SMTP Settings**.

## 5. Put it on the internet

1. Go to [app.netlify.com/drop](https://app.netlify.com/drop) and sign up (free).
2. Drag this whole `standalone` folder onto the page.
3. Netlify gives you a web address like `https://lucky-otter-123.netlify.app`. That's the link to send your friends. You can rename it under **Site configuration → Change site name**.

To update the app later, drag the folder onto your site's **Deploys** page again.

## What's free, and the limits

- **Supabase free plan:** 1 GB of photos, roughly 1,000 to 2,000 photos at the size the app saves them; 500 MB for trip data, which is plenty; up to 50,000 users.
- **One thing to know:** Supabase pauses a free project after a week with nobody using it. Nothing is lost. Log in to Supabase and click **Restore project** to bring it back.
- **The street map** comes from OpenStreetMap. It's free for light use like a group of friends, and the app shows the credit it asks for.

## How friends and privacy work

- Everyone makes a profile with a username in the **Friends** tab. Friends find each other by name or @username.
- Following works by request: you see someone's shared trips only after they **approve** you. They can remove you as a follower at any time.
- Each trip has a **Who can see this** setting:
  - **Only me:** nobody else sees it.
  - **Followers** (the default): approved followers see it.
  - **Everyone:** anyone signed in to your site sees it.
- Visited countries and cities are shown to approved followers, except places that only appear in "Only me" trips. Those stay private.
- Photos follow the trip or country they belong to. A follower can see a trip's photos only if they can see the trip.
- These rules are enforced by Supabase on its servers, so they hold even though the app's code is public.

## What works where

| | Website version | Claude version |
|---|---|---|
| Accounts | Yes, email and password | Your Claude account |
| Following friends and a feed | Yes | No |
| Trip photos | Yes | No |
| Country photo fills | Yes | Yes, saved small, inside your map data |
| Transport for each step | Yes | Yes |
| Street map | Yes | No (Claude blocks outside map images) |
| AI trip chat | No (only works inside Claude) | Yes |

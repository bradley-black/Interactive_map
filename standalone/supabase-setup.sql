-- Been There Atlas: database and photo storage setup.
-- Paste all of this into Supabase > SQL Editor > New query, then press Run.
-- Safe to run more than once, including over an earlier version of this file.

-- 1. Profiles: the username and name friends search for.
create table if not exists public.profiles (
  id           uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  username     text not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null default '' check (char_length(display_name) <= 40),
  avatar_path  text,
  created_at   timestamptz not null default now()
);
alter table public.profiles enable row level security;

drop policy if exists "Signed-in people see profiles" on public.profiles;
drop policy if exists "Create own profile"            on public.profiles;
drop policy if exists "Change own profile"            on public.profiles;
drop policy if exists "Delete own profile"            on public.profiles;
create policy "Signed-in people see profiles" on public.profiles for select to authenticated using (true);
create policy "Create own profile" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "Change own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "Delete own profile" on public.profiles for delete to authenticated using (id = auth.uid());

-- 2. Follows: a request starts as 'pending' and only the person being followed can accept it.
create table if not exists public.follows (
  follower   uuid not null default auth.uid() references auth.users (id) on delete cascade,
  followee   uuid not null references auth.users (id) on delete cascade,
  status     text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  primary key (follower, followee),
  check (follower <> followee)
);
alter table public.follows enable row level security;

drop policy if exists "See own follows"           on public.follows;
drop policy if exists "Ask to follow"             on public.follows;
drop policy if exists "Approve requests to me"    on public.follows;
drop policy if exists "Unfollow or remove"        on public.follows;
create policy "See own follows" on public.follows for select to authenticated
  using (auth.uid() in (follower, followee));
create policy "Ask to follow" on public.follows for insert to authenticated
  with check (follower = auth.uid() and status = 'pending');
create policy "Approve requests to me" on public.follows for update to authenticated
  using (followee = auth.uid()) with check (followee = auth.uid() and status = 'accepted');
create policy "Unfollow or remove" on public.follows for delete to authenticated
  using (auth.uid() in (follower, followee));
-- Approving may only change the status, never who is following whom.
revoke update on public.follows from authenticated;
grant update (status) on public.follows to authenticated;

-- 3. Saved things (visited countries, cities, trips), each owned by one person.
create table if not exists public.docs (
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id         text not null,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);
alter table public.docs add column if not exists kind text;
alter table public.docs add column if not exists visibility text not null default 'private';
alter table public.docs drop constraint if exists docs_visibility_check;
alter table public.docs add constraint docs_visibility_check check (visibility in ('private', 'followers', 'public'));
create index if not exists docs_feed_idx on public.docs (kind, user_id, updated_at desc);
alter table public.docs enable row level security;

-- You see your own things, anything marked 'public', and 'followers' things of people who approved you.
drop policy if exists "Read own docs"           on public.docs;
drop policy if exists "Read own or shared docs" on public.docs;
drop policy if exists "Add own docs"            on public.docs;
drop policy if exists "Change own docs"         on public.docs;
drop policy if exists "Delete own docs"         on public.docs;
create policy "Read own or shared docs" on public.docs for select to authenticated using (
  auth.uid() = user_id
  or visibility = 'public'
  or (visibility = 'followers' and exists (
    select 1 from public.follows f
    where f.follower = auth.uid() and f.followee = docs.user_id and f.status = 'accepted'))
);
create policy "Add own docs"    on public.docs for insert to authenticated with check (auth.uid() = user_id);
create policy "Change own docs" on public.docs for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Delete own docs" on public.docs for delete to authenticated using (auth.uid() = user_id);

-- 4. Trip and country photos (private bucket). Files live at <owner id>/<trip or country id>/<file>.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "Read own photos"           on storage.objects;
drop policy if exists "Read own or shared photos" on storage.objects;
drop policy if exists "Add own photos"            on storage.objects;
drop policy if exists "Delete own photos"         on storage.objects;
-- A photo is readable by whoever can read the trip or country it belongs to (the rules in step 3 decide).
create policy "Read own or shared photos" on storage.objects for select to authenticated using (
  bucket_id = 'photos' and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (select 1 from public.docs d
               where d.user_id::text = (storage.foldername(name))[1] and d.id = (storage.foldername(name))[2]))
);
create policy "Add own photos" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Delete own photos" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- 5. Profile pictures (public bucket, so they show in search results). 2 MB cap.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "Add own avatar"    on storage.objects;
drop policy if exists "Delete own avatar" on storage.objects;
create policy "Add own avatar" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Delete own avatar" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

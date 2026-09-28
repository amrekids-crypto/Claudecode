-- Leaderboard table for Finance Midterm Trainer (run in Supabase SQL editor)
create table if not exists public.leaderboard (
  player_id  text primary key check (char_length(player_id) between 8 and 64),
  name       text not null check (char_length(name) between 1 and 24),
  score      integer not null default 0 check (score between 0 and 1000000),
  best_day   integer not null default 0 check (best_day between 0 and 10000),
  medals     integer not null default 0 check (medals between 0 and 10000),
  correct    integer not null default 0 check (correct >= 0),
  answered   integer not null default 0 check (answered >= correct),
  earned     integer not null default 0,
  updated_at timestamptz not null default now()
);

create index if not exists leaderboard_score_idx on public.leaderboard (score desc);

alter table public.leaderboard enable row level security;

-- Everyone (anon key) can read the top list
drop policy if exists "leaderboard read" on public.leaderboard;
create policy "leaderboard read" on public.leaderboard
  for select using (true);

-- Anyone can add their own row
drop policy if exists "leaderboard insert" on public.leaderboard;
create policy "leaderboard insert" on public.leaderboard
  for insert with check (true);

-- Rows can be updated (the game upserts by player_id).
-- Note: without login there is no real ownership check, so this is a
-- trust-based classroom leaderboard, like the battleship one.
drop policy if exists "leaderboard update" on public.leaderboard;
create policy "leaderboard update" on public.leaderboard
  for update using (true) with check (true);

-- =====================================================================
-- Cloud saves: progress, profile, album, achievements, tests, cards.
-- Account = nickname + PIN. The table is closed to the anon key; the
-- game only talks to it through the three functions below.
-- Safe to run again (idempotent).
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.cloud_saves (
  name_key     text primary key,                       -- lower(trim(name))
  name         text not null check (char_length(name) between 1 and 24),
  pin_hash     text not null,
  token        text not null unique,
  player_id    text not null check (char_length(player_id) between 8 and 64),
  data         jsonb not null default '{}'::jsonb,
  fails        integer not null default 0,
  locked_until timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.cloud_saves enable row level security;
-- No policies on purpose: direct reads/writes with the anon key are denied.
revoke all on public.cloud_saves from anon, authenticated;

-- Log in, or create the account if the nickname is free.
create or replace function public.cloud_login(p_name text, p_pin text, p_player_id text)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare
  r public.cloud_saves;
  n text := trim(coalesce(p_name, ''));
  k text := lower(trim(coalesce(p_name, '')));
begin
  if char_length(n) not between 1 and 24 then raise exception 'bad_name'; end if;
  if coalesce(p_pin, '') !~ '^[0-9]{4,12}$' then raise exception 'bad_pin_format'; end if;

  select * into r from public.cloud_saves where name_key = k for update;
  if not found then
    insert into public.cloud_saves (name_key, name, pin_hash, token, player_id)
    values (k, n, crypt(p_pin, gen_salt('bf')), encode(gen_random_bytes(24), 'hex'),
            case when char_length(coalesce(p_player_id, '')) between 8 and 64 then p_player_id
                 else encode(gen_random_bytes(12), 'hex') end)
    returning * into r;
    return jsonb_build_object('token', r.token, 'player_id', r.player_id, 'name', r.name,
                              'data', r.data, 'updated_at', r.updated_at, 'created', true);
  end if;

  if r.locked_until is not null and r.locked_until > now() then raise exception 'locked'; end if;

  if r.pin_hash <> crypt(p_pin, r.pin_hash) then
    -- 5 wrong PINs in a row lock the account for 15 minutes
    update public.cloud_saves
       set fails = case when fails + 1 >= 5 then 0 else fails + 1 end,
           locked_until = case when fails + 1 >= 5 then now() + interval '15 minutes' else locked_until end
     where name_key = k;
    return jsonb_build_object('error', 'bad_pin');
  end if;

  update public.cloud_saves set fails = 0, locked_until = null where name_key = k;
  return jsonb_build_object('token', r.token, 'player_id', r.player_id, 'name', r.name,
                            'data', r.data, 'updated_at', r.updated_at, 'created', false);
end $$;

-- Save the whole progress snapshot (up to ~1 MB).
create or replace function public.cloud_save(p_token text, p_data jsonb)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare t timestamptz;
begin
  if p_data is null or jsonb_typeof(p_data) <> 'object' then raise exception 'bad_data'; end if;
  if pg_column_size(p_data) > 1000000 then raise exception 'too_big'; end if;
  update public.cloud_saves set data = p_data, updated_at = now()
   where token = p_token returning updated_at into t;
  if t is null then raise exception 'bad_token'; end if;
  return jsonb_build_object('updated_at', t);
end $$;

-- Load the latest snapshot.
create or replace function public.cloud_load(p_token text)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare r public.cloud_saves;
begin
  select * into r from public.cloud_saves where token = p_token;
  if not found then raise exception 'bad_token'; end if;
  return jsonb_build_object('name', r.name, 'player_id', r.player_id, 'data', r.data, 'updated_at', r.updated_at);
end $$;

revoke all on function public.cloud_login(text, text, text) from public;
revoke all on function public.cloud_save(text, jsonb) from public;
revoke all on function public.cloud_load(text) from public;
grant execute on function public.cloud_login(text, text, text) to anon, authenticated;
grant execute on function public.cloud_save(text, jsonb) to anon, authenticated;
grant execute on function public.cloud_load(text) to anon, authenticated;

-- =====================================================================
-- Hardening (v2): nobody can write someone else's leaderboard row or
-- read player ids. Leaderboard writes go only through lb_submit with the
-- secret account token; the public can read names and scores only.
-- =====================================================================
drop policy if exists "leaderboard insert" on public.leaderboard;
drop policy if exists "leaderboard update" on public.leaderboard;
revoke all on public.leaderboard from anon, authenticated;
grant select (name, score, best_day, medals, correct, answered, updated_at) on public.leaderboard to anon, authenticated;

create or replace function public.lb_submit(p_token text, p_best_day integer, p_medals integer,
                                            p_correct integer, p_answered integer, p_earned integer)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare r public.cloud_saves; sc integer;
begin
  select * into r from public.cloud_saves where token = p_token;
  if not found then raise exception 'bad_token'; end if;
  if p_best_day not between 0 and 10000 or p_medals not between 0 and 10000
     or p_correct < 0 or p_answered < p_correct or p_answered > 1000000 then raise exception 'bad_stats'; end if;
  sc := least(1000000, p_medals * 100 + p_best_day * 25 + p_correct * 5);
  insert into public.leaderboard (player_id, name, score, best_day, medals, correct, answered, earned, updated_at)
  values (r.player_id, r.name, sc, p_best_day, p_medals, p_correct, p_answered, greatest(0, coalesce(p_earned, 0)), now())
  on conflict (player_id) do update set name = excluded.name, score = excluded.score, best_day = excluded.best_day,
    medals = excluded.medals, correct = excluded.correct, answered = excluded.answered, earned = excluded.earned, updated_at = now();
  return jsonb_build_object('score', sc);
end $$;
revoke all on function public.lb_submit(text, integer, integer, integer, integer, integer) from public;
grant execute on function public.lb_submit(text, integer, integer, integer, integer, integer) to anon, authenticated;

-- Safety net: every cloud save keeps the previous version (last 20 per player),
-- so a bad update or a wrong choice on another device can always be rolled back.
create table if not exists public.cloud_saves_history (
  id         bigserial primary key,
  name_key   text not null,
  data       jsonb not null,
  saved_at   timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists cloud_saves_history_key_idx on public.cloud_saves_history (name_key, id desc);
alter table public.cloud_saves_history enable row level security;
revoke all on public.cloud_saves_history from anon, authenticated;

create or replace function public.cloud_saves_keep_history() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.data is distinct from new.data and old.data <> '{}'::jsonb then
    insert into public.cloud_saves_history (name_key, data, saved_at) values (old.name_key, old.data, old.updated_at);
    delete from public.cloud_saves_history
     where name_key = old.name_key
       and id not in (select id from public.cloud_saves_history where name_key = old.name_key order by id desc limit 20);
  end if;
  return new;
end $$;
drop trigger if exists cloud_saves_history_trg on public.cloud_saves;
create trigger cloud_saves_history_trg before update of data on public.cloud_saves
  for each row execute function public.cloud_saves_keep_history();

-- Restore example (run by the owner in SQL Editor):
--   update public.cloud_saves set data = (select data from public.cloud_saves_history
--     where name_key = 'ник в нижнем регистре' order by id desc limit 1) where name_key = 'ник в нижнем регистре';

-- Gyvenimas Vilniuje: leaderboard + cloud saves (run in Supabase SQL Editor).
-- Safe to run again. Every object has the ltv_ prefix, so this works in the
-- same Supabase project as Finance Midterm Trainer without touching its tables.
create extension if not exists pgcrypto with schema extensions;

-- =====================================================================
-- Leaderboard: the public can read names and scores only.
-- Rows are written only by ltv_lb_submit with the secret account token.
-- =====================================================================
create table if not exists public.ltv_leaderboard (
  player_id  text primary key check (char_length(player_id) between 8 and 64),
  name       text not null check (char_length(name) between 1 and 24),
  score      integer not null default 0 check (score between 0 and 1000000),
  best_day   integer not null default 0 check (best_day between 0 and 100000),
  max_job    integer not null default 0 check (max_job between 0 and 10),
  mastered   integer not null default 0 check (mastered between 0 and 10000),
  correct    integer not null default 0 check (correct >= 0),
  answered   integer not null default 0 check (answered >= correct),
  wins       integer not null default 0 check (wins between 0 and 10000),
  updated_at timestamptz not null default now()
);
create index if not exists ltv_leaderboard_score_idx on public.ltv_leaderboard (score desc);

alter table public.ltv_leaderboard enable row level security;
drop policy if exists "ltv leaderboard read" on public.ltv_leaderboard;
create policy "ltv leaderboard read" on public.ltv_leaderboard for select using (true);
revoke all on public.ltv_leaderboard from anon, authenticated;
grant select (name, score, best_day, max_job, mastered, correct, answered, wins, updated_at)
  on public.ltv_leaderboard to anon, authenticated;

-- =====================================================================
-- Cloud saves. Account = nickname + PIN. The table is closed to the anon
-- key; the game only talks to it through the functions below.
-- =====================================================================
create table if not exists public.ltv_cloud_saves (
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
alter table public.ltv_cloud_saves enable row level security;
-- No policies on purpose: direct reads/writes with the anon key are denied.
revoke all on public.ltv_cloud_saves from anon, authenticated;

-- Log in, or create the account if the nickname is free.
create or replace function public.ltv_cloud_login(p_name text, p_pin text, p_player_id text)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare
  r public.ltv_cloud_saves;
  n text := trim(coalesce(p_name, ''));
  k text := lower(trim(coalesce(p_name, '')));
begin
  if char_length(n) not between 1 and 24 then raise exception 'bad_name'; end if;
  if coalesce(p_pin, '') !~ '^[0-9]{4,12}$' then raise exception 'bad_pin_format'; end if;

  select * into r from public.ltv_cloud_saves where name_key = k for update;
  if not found then
    insert into public.ltv_cloud_saves (name_key, name, pin_hash, token, player_id)
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
    update public.ltv_cloud_saves
       set fails = case when fails + 1 >= 5 then 0 else fails + 1 end,
           locked_until = case when fails + 1 >= 5 then now() + interval '15 minutes' else locked_until end
     where name_key = k;
    return jsonb_build_object('error', 'bad_pin');
  end if;

  update public.ltv_cloud_saves set fails = 0, locked_until = null where name_key = k;
  return jsonb_build_object('token', r.token, 'player_id', r.player_id, 'name', r.name,
                            'data', r.data, 'updated_at', r.updated_at, 'created', false);
end $$;

-- Save the whole progress snapshot (up to ~1 MB).
create or replace function public.ltv_cloud_save(p_token text, p_data jsonb)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare t timestamptz;
begin
  if p_data is null or jsonb_typeof(p_data) <> 'object' then raise exception 'bad_data'; end if;
  if pg_column_size(p_data) > 1000000 then raise exception 'too_big'; end if;
  update public.ltv_cloud_saves set data = p_data, updated_at = now()
   where token = p_token returning updated_at into t;
  if t is null then raise exception 'bad_token'; end if;
  return jsonb_build_object('updated_at', t);
end $$;

-- Load the latest snapshot.
create or replace function public.ltv_cloud_load(p_token text)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare r public.ltv_cloud_saves;
begin
  select * into r from public.ltv_cloud_saves where token = p_token;
  if not found then raise exception 'bad_token'; end if;
  return jsonb_build_object('name', r.name, 'player_id', r.player_id, 'data', r.data, 'updated_at', r.updated_at);
end $$;

-- Submit stats; the server computes the score.
create or replace function public.ltv_lb_submit(p_token text, p_best_day integer, p_max_job integer,
                                                p_mastered integer, p_correct integer, p_answered integer, p_wins integer)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare r public.ltv_cloud_saves; sc integer;
begin
  select * into r from public.ltv_cloud_saves where token = p_token;
  if not found then raise exception 'bad_token'; end if;
  if p_best_day not between 0 and 100000 or p_max_job not between 0 and 10
     or p_mastered not between 0 and 10000 or p_wins not between 0 and 10000
     or p_correct < 0 or p_answered < p_correct or p_answered > 10000000 then raise exception 'bad_stats'; end if;
  sc := least(1000000, p_wins * 500 + p_best_day * 20 + p_max_job * 100 + p_mastered * 10 + least(p_correct, 200000) * 2);
  insert into public.ltv_leaderboard (player_id, name, score, best_day, max_job, mastered, correct, answered, wins, updated_at)
  values (r.player_id, r.name, sc, p_best_day, p_max_job, p_mastered, p_correct, p_answered, p_wins, now())
  on conflict (player_id) do update set name = excluded.name, score = excluded.score, best_day = excluded.best_day,
    max_job = excluded.max_job, mastered = excluded.mastered, correct = excluded.correct,
    answered = excluded.answered, wins = excluded.wins, updated_at = now();
  return jsonb_build_object('score', sc);
end $$;

revoke all on function public.ltv_cloud_login(text, text, text) from public;
revoke all on function public.ltv_cloud_save(text, jsonb) from public;
revoke all on function public.ltv_cloud_load(text) from public;
revoke all on function public.ltv_lb_submit(text, integer, integer, integer, integer, integer, integer) from public;
grant execute on function public.ltv_cloud_login(text, text, text) to anon, authenticated;
grant execute on function public.ltv_cloud_save(text, jsonb) to anon, authenticated;
grant execute on function public.ltv_cloud_load(text) to anon, authenticated;
grant execute on function public.ltv_lb_submit(text, integer, integer, integer, integer, integer, integer) to anon, authenticated;

-- =====================================================================
-- Safety net: every cloud save keeps the previous version (last 20 per player).
-- =====================================================================
create table if not exists public.ltv_cloud_saves_history (
  id         bigserial primary key,
  name_key   text not null,
  data       jsonb not null,
  saved_at   timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists ltv_cloud_saves_history_key_idx on public.ltv_cloud_saves_history (name_key, id desc);
alter table public.ltv_cloud_saves_history enable row level security;
revoke all on public.ltv_cloud_saves_history from anon, authenticated;

create or replace function public.ltv_cloud_saves_keep_history() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.data is distinct from new.data and old.data <> '{}'::jsonb then
    insert into public.ltv_cloud_saves_history (name_key, data, saved_at) values (old.name_key, old.data, old.updated_at);
    delete from public.ltv_cloud_saves_history
     where name_key = old.name_key
       and id not in (select id from public.ltv_cloud_saves_history where name_key = old.name_key order by id desc limit 20);
  end if;
  return new;
end $$;
drop trigger if exists ltv_cloud_saves_history_trg on public.ltv_cloud_saves;
create trigger ltv_cloud_saves_history_trg before update of data on public.ltv_cloud_saves
  for each row execute function public.ltv_cloud_saves_keep_history();

-- Restore example (run by the owner in SQL Editor):
--   update public.ltv_cloud_saves set data = (select data from public.ltv_cloud_saves_history
--     where name_key = 'ник в нижнем регистре' order by id desc limit 1) where name_key = 'ник в нижнем регистре';

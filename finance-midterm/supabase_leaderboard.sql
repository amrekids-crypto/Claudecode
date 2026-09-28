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
create policy "leaderboard read" on public.leaderboard
  for select using (true);

-- Anyone can add their own row
create policy "leaderboard insert" on public.leaderboard
  for insert with check (true);

-- Rows can be updated (the game upserts by player_id).
-- Note: without login there is no real ownership check, so this is a
-- trust-based classroom leaderboard, like the battleship one.
create policy "leaderboard update" on public.leaderboard
  for update using (true) with check (true);

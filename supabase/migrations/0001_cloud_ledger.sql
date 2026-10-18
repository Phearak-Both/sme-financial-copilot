-- SME Financial Copilot: per-user cloud ledger.
--
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Every table is protected by Row-Level Security, so each signed-in user can
-- only read and write their own rows.

-- ------------------------------------------------------------ ledger entries

create table if not exists public.ledger_entries (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  type text not null
    check (type in ('income', 'expense', 'ownerContribution', 'ownerWithdrawal')),
  -- Integer minor units: USD cents or whole riel. Direction comes from type.
  amount_minor bigint not null check (amount_minor > 0),
  currency text not null check (currency in ('USD', 'KHR')),
  occurred_on date not null,
  category_id text,
  description text not null default '',
  note text,
  payment_method text,
  source text not null default 'manual',
  status text not null default 'active' check (status in ('active', 'voided')),
  void_reason text,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ledger_entries_user_date
  on public.ledger_entries (user_id, occurred_on desc, created_at desc);

-- Append-only history, written only by the trigger below.
create table if not exists public.entry_revisions (
  id bigint generated always as identity primary key,
  entry_id uuid not null references public.ledger_entries (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  version integer not null,
  kind text not null check (kind in ('create', 'edit', 'voided')),
  snapshot jsonb not null,
  changed_at timestamptz not null default now()
);

create index if not exists entry_revisions_entry
  on public.entry_revisions (entry_id, id desc);

-- Server-side rules for every change to an entry: voided entries are frozen,
-- the version goes up by one, and identity fields can't be changed.
create or replace function public.ledger_entries_before_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.version := 1;
    new.status := 'active';
    new.created_at := now();
    new.updated_at := now();
    return new;
  end if;
  if old.status = 'voided' then
    raise exception 'Entry % is voided and cannot be changed', old.id;
  end if;
  new.id := old.id;
  new.user_id := old.user_id;
  new.created_at := old.created_at;
  new.version := old.version + 1;
  new.updated_at := now();
  return new;
end;
$$;

-- Records a snapshot for every create, edit and void. Runs as the table
-- owner so users can read their history but never write or alter it.
create or replace function public.ledger_entries_after_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.entry_revisions (entry_id, user_id, version, kind, snapshot)
  values (
    new.id,
    new.user_id,
    new.version,
    case
      when tg_op = 'INSERT' then 'create'
      when new.status = 'voided' then 'voided'
      else 'edit'
    end,
    to_jsonb(new)
  );
  return new;
end;
$$;

drop trigger if exists ledger_entries_before_write on public.ledger_entries;
create trigger ledger_entries_before_write
  before insert or update on public.ledger_entries
  for each row execute function public.ledger_entries_before_write();

drop trigger if exists ledger_entries_after_write on public.ledger_entries;
create trigger ledger_entries_after_write
  after insert or update on public.ledger_entries
  for each row execute function public.ledger_entries_after_write();

-- -------------------------------------------------------------- opening cash

create table if not exists public.opening_balances (
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  currency text not null check (currency in ('USD', 'KHR')),
  amount_minor bigint not null check (amount_minor >= 0),
  as_of date not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, currency)
);

-- ----------------------------------------------------------- assistant chats

create table if not exists public.chats (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  title text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id bigint generated always as identity primary key,
  chat_id uuid not null references public.chats (id) on delete cascade,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  position integer not null,
  -- JSON from the app's chat_codec.dart.
  data text not null
);

create index if not exists chat_messages_chat
  on public.chat_messages (chat_id, position);

-- ------------------------------------------------------- row-level security

alter table public.ledger_entries enable row level security;
alter table public.entry_revisions enable row level security;
alter table public.opening_balances enable row level security;
alter table public.chats enable row level security;
alter table public.chat_messages enable row level security;

-- Entries: read, add and change your own. No delete: entries are voided.
drop policy if exists "own entries: read" on public.ledger_entries;
create policy "own entries: read" on public.ledger_entries
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "own entries: add" on public.ledger_entries;
create policy "own entries: add" on public.ledger_entries
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "own entries: change" on public.ledger_entries;
create policy "own entries: change" on public.ledger_entries
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- History: read only.
drop policy if exists "own revisions: read" on public.entry_revisions;
create policy "own revisions: read" on public.entry_revisions
  for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "own opening cash" on public.opening_balances;
create policy "own opening cash" on public.opening_balances
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "own chats" on public.chats;
create policy "own chats" on public.chats
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "own chat messages" on public.chat_messages;
create policy "own chat messages" on public.chat_messages
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

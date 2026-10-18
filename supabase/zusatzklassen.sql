-- Zusatzklassen für das Kinderkonzert
--
-- Einmalig im Supabase-Dashboard ausführen: SQL Editor → New query → einfügen → Run.
-- Die Seite zusatzklasse.html spricht nur die beiden Funktionen unten an; die Tabelle
-- selbst ist von außen weder lesbar noch beschreibbar (Lehrer:innen-Namen bleiben privat).
--
-- Anmeldungen ansehen/exportieren: Table Editor → zusatzklassen → Export as CSV.
-- Anzahl der Plätze ändern: Zahl in zusatzklassen_max() anpassen und Skript erneut ausführen.

create table if not exists public.zusatzklassen (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  schule text not null,
  eigene_klasse text not null,
  zusatzklasse text not null,
  klassenname text,
  lehrkraft text not null,
  anzahl_kinder int
);

-- Jede angemeldete Klasse darf genau eine Zusatzklasse mitnehmen.
create unique index if not exists zusatzklassen_eine_pro_klasse
  on public.zusatzklassen (lower(btrim(schule)), lower(btrim(eigene_klasse)));

alter table public.zusatzklassen enable row level security;
revoke all on public.zusatzklassen from anon, authenticated;

create or replace function public.zusatzklassen_max()
returns int
language sql
immutable
as $$ select 4 $$;

create or replace function public.zusatzklassen_status()
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'max', zusatzklassen_max(),
    'frei', greatest(zusatzklassen_max() - count(*), 0)
  )
  from zusatzklassen;
$$;

create or replace function public.zusatzklasse_anmelden(
  p_schule text,
  p_eigene_klasse text,
  p_zusatzklasse text,
  p_lehrkraft text,
  p_klassenname text default null,
  p_anzahl_kinder int default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max int := zusatzklassen_max();
  v_vergeben int;
begin
  p_schule := btrim(p_schule);
  p_eigene_klasse := btrim(p_eigene_klasse);
  p_zusatzklasse := btrim(p_zusatzklasse);
  p_lehrkraft := btrim(p_lehrkraft);
  p_klassenname := nullif(btrim(p_klassenname), '');

  if coalesce(p_schule, '') = '' or coalesce(p_eigene_klasse, '') = ''
     or coalesce(p_zusatzklasse, '') = '' or coalesce(p_lehrkraft, '') = ''
     or length(p_schule) > 200 or length(p_eigene_klasse) > 60
     or length(p_zusatzklasse) > 60 or length(p_lehrkraft) > 120
     or length(p_klassenname) > 60 or p_anzahl_kinder not between 1 and 99 then
    return json_build_object('ok', false, 'fehler', 'ungueltig');
  end if;

  -- Gleichzeitige Anmeldungen nacheinander abarbeiten, damit nie mehr als v_max Plätze vergeben werden.
  lock table zusatzklassen in share row exclusive mode;

  select count(*) into v_vergeben from zusatzklassen;
  if v_vergeben >= v_max then
    return json_build_object('ok', false, 'fehler', 'ausgebucht', 'max', v_max, 'frei', 0);
  end if;

  begin
    insert into zusatzklassen (schule, eigene_klasse, zusatzklasse, klassenname, lehrkraft, anzahl_kinder)
    values (p_schule, p_eigene_klasse, p_zusatzklasse, p_klassenname, p_lehrkraft, p_anzahl_kinder);
  exception when unique_violation then
    return json_build_object('ok', false, 'fehler', 'doppelt', 'max', v_max, 'frei', v_max - v_vergeben);
  end;

  return json_build_object('ok', true, 'max', v_max, 'frei', v_max - v_vergeben - 1);
end;
$$;

revoke all on function public.zusatzklassen_status() from public;
revoke all on function public.zusatzklasse_anmelden(text, text, text, text, text, int) from public;
grant execute on function public.zusatzklassen_status() to anon, authenticated;
grant execute on function public.zusatzklasse_anmelden(text, text, text, text, text, int) to anon, authenticated;

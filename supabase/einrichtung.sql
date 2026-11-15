-- Roadbook Weihnachtspäckchenkonvoi: Einrichtung der gemeinsamen Datenbank
-- Im Supabase-Dashboard unter "SQL Editor" komplett einfügen und mit "Run" ausführen.
-- Vorher in der LETZTEN Anweisung deine eigene E-Mail-Adresse und deinen Namen eintragen.
-- Das Skript kann gefahrlos mehrfach ausgeführt werden.

-- 1. Tabellen ---------------------------------------------------------------

-- Wer das Roadbook nutzen darf. rolle: 'planer' (darf alles ändern) oder 'leser' (sieht alles, erfasst Päckchen-Abgaben)
create table if not exists public.mitglieder (
  email  text primary key,
  name   text,
  rolle  text not null default 'leser' check (rolle in ('planer','leser'))
);

-- Ein Eintrag je Konvoi (z. B. "Bulgarien 2026")
create table if not exists public.konvois (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  erstellt_am  timestamptz not null default now(),
  erstellt_von text
);

-- Die Planung eines Konvois, aufgeteilt in Bereiche (konvoi, strecke, route, fahrzeuge, bestand, abgabe:<id>)
create table if not exists public.daten (
  konvoi_id     uuid not null references public.konvois(id) on delete cascade,
  bereich       text not null,
  inhalt        jsonb,
  version       int  not null default 1,
  geaendert_am  timestamptz not null default now(),
  geaendert_von text,
  primary key (konvoi_id, bereich)
);

-- 2. Hilfsfunktionen für die Berechtigungen -----------------------------------

create or replace function public.ist_mitglied() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.mitglieder m where lower(m.email) = lower(auth.jwt() ->> 'email'));
$$;

create or replace function public.ist_planer() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.mitglieder m where lower(m.email) = lower(auth.jwt() ->> 'email') and m.rolle = 'planer');
$$;

-- 3. Zugriffsregeln (Row Level Security) --------------------------------------

alter table public.mitglieder enable row level security;
alter table public.konvois    enable row level security;
alter table public.daten      enable row level security;

revoke all on public.mitglieder, public.konvois, public.daten from anon;

drop policy if exists "mitglieder lesen" on public.mitglieder;
create policy "mitglieder lesen" on public.mitglieder for select to authenticated using (public.ist_mitglied());

drop policy if exists "konvois lesen" on public.konvois;
create policy "konvois lesen" on public.konvois for select to authenticated using (public.ist_mitglied());
drop policy if exists "konvois anlegen" on public.konvois;
create policy "konvois anlegen" on public.konvois for insert to authenticated with check (public.ist_planer());
drop policy if exists "konvois aendern" on public.konvois;
create policy "konvois aendern" on public.konvois for update to authenticated using (public.ist_planer()) with check (public.ist_planer());
drop policy if exists "konvois loeschen" on public.konvois;
create policy "konvois loeschen" on public.konvois for delete to authenticated using (public.ist_planer());

drop policy if exists "daten lesen" on public.daten;
create policy "daten lesen" on public.daten for select to authenticated using (public.ist_mitglied());
-- Schreiben in "daten" nur über die Funktion speichern() unten.

-- 4. Speichern mit Versionsprüfung --------------------------------------------
-- Verhindert, dass zwei Personen sich unbemerkt gegenseitig überschreiben.
-- Planer dürfen alle Bereiche speichern, Leser nur Päckchen-Abgaben (abgabe:...) und Tankprotokolle (tank:...).
-- Ein leerer Inhalt (null) bedeutet "gelöscht".

create or replace function public.speichern(p_konvoi uuid, p_bereich text, p_inhalt jsonb, p_version int)
returns int language plpgsql security definer set search_path = public as $$
declare
  v    int;
  mail text := lower(auth.jwt() ->> 'email');
begin
  if not (public.ist_planer() or ((p_bereich like 'abgabe:%' or p_bereich like 'tank:%') and public.ist_mitglied())) then
    raise exception 'keine_berechtigung';
  end if;
  if not exists (select 1 from public.konvois where id = p_konvoi) then
    raise exception 'konvoi_unbekannt';
  end if;
  if coalesce(p_version, 0) = 0 then
    insert into public.daten (konvoi_id, bereich, inhalt, version, geaendert_von)
    values (p_konvoi, p_bereich, p_inhalt, 1, mail)
    on conflict (konvoi_id, bereich) do nothing;
    if not found then raise exception 'konflikt'; end if;
    return 1;
  end if;
  update public.daten
     set inhalt = p_inhalt, version = version + 1, geaendert_am = now(), geaendert_von = mail
   where konvoi_id = p_konvoi and bereich = p_bereich and version = p_version
  returning version into v;
  if v is null then raise exception 'konflikt'; end if;
  return v;
end $$;

revoke all on function public.speichern(uuid, text, jsonb, int) from public, anon;
grant execute on function public.speichern(uuid, text, jsonb, int) to authenticated;

-- 5. Echtzeit-Aktualisierung einschalten --------------------------------------

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'daten') then
    alter publication supabase_realtime add table public.daten;
  end if;
end $$;

-- 6. Zugänge eintragen ---------------------------------------------------------
-- Variante A (empfohlen): Konvoi-Passwort mit zwei gemeinsamen Zugängen.
--   Dieselben zwei E-Mail-Adressen legst du unter Authentication → Users → "Add user" an
--   (jeweils mit eigenem Passwort, "Auto Confirm User" anhaken) und trägst sie in config.js
--   bei planerEmail und teamEmail ein. Die Adressen müssen kein echtes Postfach haben.
-- Variante B: Einzelne Konten je Person. Dann für jede Person eine Zeile mit ihrer E-Mail eintragen.

insert into public.mitglieder (email, name, rolle) values
  ('roadbook-planung@example.org', 'Planung', 'planer'),
  ('roadbook-team@example.org',    'Team',    'leser1')
on conflict (email) do update set name = excluded.name, rolle = excluded.rolle;

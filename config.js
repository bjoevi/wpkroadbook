/*
  Verbindung zur gemeinsamen Datenbank (Supabase).

  Trage hier die Werte aus deinem Supabase-Projekt ein:
  Project Settings → API Keys (bzw. Data API)
    supabaseUrl      = Project URL, z. B. https://abcdefghijkl.supabase.co
    supabaseAnonKey  = Publishable key (beginnt mit sb_publishable_) oder der "anon public" key

  Beide Werte sind für den Browser gedacht und dürfen öffentlich im Repository stehen.
  Geschützt werden die Daten durch Anmeldung und die Regeln aus supabase/einrichtung.sql.
  Den "secret" bzw. "service_role" key NIEMALS hier eintragen.

  Bleiben beide Werte leer, läuft das Roadbook ohne Anmeldung und speichert nur im eigenen Browser.
*/
window.ROADBOOK_CONFIG = {
  supabaseUrl: "",
  supabaseAnonKey: ""
};

# SEHARIA CRM

CRM în română pentru prospectare și vânzări PVC / aluminiu. Next.js, Supabase și Vercel.

## Funcții

Dashboard zilnic, obiective de contact, prospecți B2B/B2C, istoric discuții, pipeline, calendar, evidența ofertelor, rapoarte pe agent și județ. Agenții se înregistrează cu email și parolă; profilul se creează automat, fără aprobare. Toți agenții autentificați pot consulta și actualiza baza comună.

## 1. Supabase

1. Creează un proiect Supabase.
2. Deschide **SQL Editor → New query**, copiază întregul fișier `supabase/schema.sql` și apasă **Run**. Scriptul se execută o singură dată într-un proiect nou.
3. Din **Connect / Settings → API Keys**, copiază URL-ul proiectului și cheia **Publishable**.
4. Lasă înregistrarea cu email activată. Confirmarea emailului poate rămâne activată: agentul confirmă adresa, fără aprobare din partea unui administrator.

Nu sunt necesare chei Secret sau service_role. Datele sunt inaccesibile vizitatorilor neautentificați. RLS permite citirea pentru agenții autentificați; modificările trec printr-o funcție care verifică identitatea și păstrează autorul fiecărei înregistrări. Oricine își creează un cont în această aplicație primește acces la baza comună, conform modului de lucru ales.

## 2. Vercel

1. Importă acest repository: **Add New → Project → Import**.
2. Framework: **Next.js**. Root directory: rădăcina repository-ului. Păstrează comenzile implicite.
3. Adaugă variabilele de mediu:

| Nume | Valoare |
| --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | URL-ul proiectului Supabase |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Cheia Publishable |

4. Apasă **Deploy**.
5. În Supabase: **Authentication → URL Configuration**. Setează **Site URL** la adresa Vercel a aplicației. Adaugă la **Redirect URLs** adresa completă `https://ADRESA-APLICATIEI/auth/confirm`.
6. Pentru confirmarea emailului cu flux server-side, în **Authentication → Email Templates → Confirm signup**, păstrează restul șablonului și setează destinația linkului de confirmare la:

```html
<a href="{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=email">Confirmă contul</a>
```

7. Testează cu două conturi: adaugă un prospect din primul și verifică din al doilea că este vizibil. Înregistrează o discuție și verifică revenirea în calendar.

Dacă modifici variabilele Vercel după prima publicare, execută **Redeploy**.

## Dezvoltare locală

```sh
npm ci
cp .env.example .env.local
# completează cele două valori Supabase în .env.local
npm run dev
```

Verificări: `npm run typecheck` și `npm run build`.

## Migrarea datelor existente

Această versiune creează o bază Supabase nouă. Datele deja introduse în aplicația găzduită anterior nu sunt copiate automat. Un eventual transfer se face separat, cu maparea agenților la noile conturi Supabase. Aplicația anterioară rămâne disponibilă pe durata mutării.

import {currentUser,configured} from '@/lib/supabase/server';
import {redirect} from 'next/navigation';
import CRM from './crm';
export const dynamic='force-dynamic';
export default async function Page(){if(!configured())return <main className="signin"><div className="signin-card"><div className="brandmark">S</div><h1>SEHARIA CRM</h1><p>Aplicația este pregătită. Conexiunea la baza de date trebuie configurată înainte de utilizare.</p></div></main>;if(!await currentUser())redirect('/login');return <CRM/>}

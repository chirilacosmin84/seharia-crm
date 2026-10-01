import {configured} from '@/lib/supabase/server';
import Login from './login';
export default function Page(){return <Login ready={configured()}/>}

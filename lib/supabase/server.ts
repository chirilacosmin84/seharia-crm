import 'server-only';
import {createServerClient} from '@supabase/ssr';
import {cookies} from 'next/headers';
export function configured(){return !!(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)}
export async function supabase(){if(!configured())throw new Error('Conexiunea Supabase nu este configurată.');const jar=await cookies();return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,{cookies:{getAll:()=>jar.getAll(),setAll(values){try{values.forEach(({name,value,options})=>jar.set(name,value,options))}catch{/* Server components cannot write cookies; proxy refreshes sessions. */}}}})}
export async function currentUser(){if(!configured())return null;const client=await supabase();const {data,error}=await client.auth.getUser();if(error||!data.user)return null;const u=data.user;return {userId:u.id,email:u.email||'',displayName:u.user_metadata.full_name||u.email||'Agent',fullName:u.user_metadata.full_name||null}}

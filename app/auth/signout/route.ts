import {supabase} from '@/lib/supabase/server';
import {NextResponse} from 'next/server';
export async function POST(request:Request){const url=new URL(request.url);if(request.headers.get('origin')!==url.origin)return new Response('Cerere neautorizată',{status:403});const client=await supabase();await client.auth.signOut();return NextResponse.redirect(new URL('/login',url.origin),303)}

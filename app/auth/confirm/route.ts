import {supabase} from '@/lib/supabase/server';
import type {EmailOtpType} from '@supabase/supabase-js';
import {NextResponse} from 'next/server';
export async function GET(request:Request){const url=new URL(request.url),client=await supabase();const code=url.searchParams.get('code'),hash=url.searchParams.get('token_hash'),type=url.searchParams.get('type') as EmailOtpType|null;let ok=false;if(code){const {error}=await client.auth.exchangeCodeForSession(code);ok=!error}else if(hash&&type){const {error}=await client.auth.verifyOtp({token_hash:hash,type});ok=!error}return NextResponse.redirect(new URL(ok?'/':'/login',url.origin))}

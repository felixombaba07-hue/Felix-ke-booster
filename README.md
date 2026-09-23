# FELIX KE BOOSTER PRO

A Vercel-ready React/Vite + Supabase social-media services marketplace.

## Stack
- React + TypeScript + Vite
- Tailwind CSS v4
- Supabase Auth/Postgres/RLS
- Supabase Edge Functions for privileged payment/provider operations
- Vercel for the frontend

## Local setup
1. `npm install`
2. Copy `.env.example` to `.env.local` and add your Supabase values.
3. Run the SQL in `supabase/migrations/001_initial.sql` in Supabase SQL Editor.
4. `npm run dev`

## Vercel
Import this repository into Vercel. Add the VITE_* variables under Project Settings → Environment Variables, then redeploy.

Do not put Paystack secret keys or SMM provider secrets in VITE_* variables or in the browser.

# Deployment checklist

## Vercel
1. Push this folder to GitHub.
2. Vercel → Add New → Project → import the GitHub repo.
3. Framework should detect as Vite.
4. Build command: `npm run build`.
5. Output directory: `dist`.
6. Add:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `VITE_PAYSTACK_PUBLIC_KEY`
7. Deploy.

## Supabase
1. Create/open a Supabase project.
2. Run `supabase/migrations/001_initial.sql` in SQL Editor.
3. Confirm Auth email settings and production redirect URLs use your Vercel domain.
4. Deploy the Edge Functions when payment/provider code is configured.
5. Add server-only secrets to Supabase Functions, not Vercel browser variables:
   - `PAYSTACK_SECRET_KEY`
   - `SMM_API_URL`
   - `SMM_AFRICA_KEY`

## Important
The included payment and SMM Edge Functions are safe placeholders. They intentionally return 501 until you configure the real integrations. Do not switch them to live money/provider operations without server-side validation and webhook verification.

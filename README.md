# Offerteshock.it — Offerte, Guide, Blog e Coupon (SPA singolo file) – Bundle pronto per GitHub Pages

## Come pubblicare (1 clic)
1. Apri `RUN_ME_publish_REBASE_SAFE.bat`
2. Imposta:
   ```bat
   set "REPONAME=offerteshock-demo"
   set "VISIBILITY=public"
   ```
3. Doppio clic → lo script crea/aggancia il repo, fa commit+push e pubblica su Pages.

## Note
- Le pagine legali sono in `site/privacy.html`, `site/termini.html`, `site/contatti.html`.
- I link in menu/footer puntano a queste pagine (sono state rimosse eventuali modali).
- Workflow Pages già incluso in `.github/workflows/pages.yml`.

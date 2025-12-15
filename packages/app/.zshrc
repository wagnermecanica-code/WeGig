# ~/.zshrc
# =============================================
# Wagner Oliveira — Tô Sem Banda / WeGig
# =============================================

# Roda o app no iPhone físico (flavor dev) — seu comando do dia a dia
frun() {
  cd /Users/wagneroliveira/to_sem_banda/packages/app
  fvm flutter run --flavor dev -t lib/main_dev.dart \
    -d 00008140-001948D20AE2801C \
    --no-wireless --no-connect-via-network "$@"
}

# Carrega o arquivo de limpeza (só quando precisar)
source ~/.frunclean 2>/dev/null || true

export -f frun 2>/dev/null || true
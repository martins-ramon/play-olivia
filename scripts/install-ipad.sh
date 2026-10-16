#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
source scripts/xcode-env.sh

usage() {
  cat <<'TEXT'
Uso: ./scripts/install-ipad.sh [--device IDENTIFICADOR] [--team TEAM_ID] [--list]

Compila, assina, instala e abre o Mundo da Olívia no iPad indicado.
--list               Lista dispositivos conhecidos pelo Xcode, sem instalar.
--device ID          Identificador do iPad listado por devicectl.
--team TEAM_ID       Equipe cadastrada no Xcode (ou variável DEVELOPMENT_TEAM).
--bundle-id ID       Identificador único, se o padrão não estiver disponível.
--no-launch          Instala sem abrir o app.

Requer Xcode 15 ou mais recente, iPad pareado com Developer Mode e uma
Apple Account configurada no Xcode. A assinatura pode acessar a Apple.
Não publica o aplicativo na App Store.
TEXT
}

device="${IPAD_DEVICE_ID:-}"
team="${DEVELOPMENT_TEAM:-}"
bundle_id="${PRODUCT_BUNDLE_IDENTIFIER:-br.com.oliviaplay.app}"
list_only=false
launch=true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device|--team|--bundle-id)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { usage >&2; exit 1; }
      case "$1" in
        --device) device="$2" ;;
        --team) team="$2" ;;
        --bundle-id) bundle_id="$2" ;;
      esac
      shift 2 ;;
    --list) list_only=true; shift ;;
    --no-launch) launch=false; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if ! olivia_select_xcode; then
  echo 'Instalação pendente: Xcode completo não encontrado.' >&2
  echo 'Instale e abra o Xcode; adicione sua Apple Account em Settings > Accounts.' >&2
  echo 'Para um Xcode em outro diretório, configure DEVELOPER_DIR=/caminho/Xcode.app/Contents/Developer.' >&2
  exit 2
fi
if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  echo 'Instalação pendente: conclua a configuração inicial do Xcode.' >&2
  echo 'Abra o Xcode, revise/aceite sua licença e instale os componentes solicitados.' >&2
  echo 'Depois adicione sua Apple Account em Settings > Apple Accounts e repita este comando.' >&2
  exit 2
fi
if ! xcrun --find devicectl >/dev/null 2>&1; then
  echo 'Este script requer devicectl, incluído no Xcode 15 ou mais recente.' >&2
  echo 'Também é possível instalar pelo botão Run do Xcode.' >&2
  exit 2
fi
devices_json="$(mktemp -t olivia-devices)"
trap 'rm -f "$devices_json"' EXIT
xcrun devicectl list devices --json-output "$devices_json"
if $list_only; then
  python3 scripts/ipad-devices.py "$devices_json"
  exit 0
fi
if [[ -z "$device" ]]; then
  python3 scripts/ipad-devices.py "$devices_json"
  echo 'Informe o iPad da Olívia com --device IDENTIFICADOR. Nenhum dispositivo foi escolhido automaticamente.' >&2
  exit 2
fi
device_udid="$(python3 scripts/ipad-devices.py "$devices_json" "$device")"
if [[ -z "$team" ]]; then
  echo 'Informe --team TEAM_ID ou configure DEVELOPMENT_TEAM com a equipe da sua Apple Account no Xcode.' >&2
  echo 'Alternativa: abra OliviaPlay.xcodeproj, selecione sua Team em Signing & Capabilities e use Run.' >&2
  exit 2
fi
if [[ ! "$team" =~ ^[A-Z0-9]{10}$ ]]; then
  echo 'TEAM_ID inválido: use o identificador de 10 letras/números da equipe, não o e-mail.' >&2
  exit 1
fi
if [[ ! "$bundle_id" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
  echo 'Identificador do aplicativo inválido (exemplo: br.com.suafamilia.olivia).' >&2
  exit 1
fi

python3 scripts/generate-project.py
derived_data="$PROJECT_DIR/build/iPad"
xcodebuild -project OliviaPlay.xcodeproj -scheme OliviaPlay -configuration Debug \
  -destination "id=$device_udid" -derivedDataPath "$derived_data" \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  "DEVELOPMENT_TEAM=$team" "PRODUCT_BUNDLE_IDENTIFIER=$bundle_id" build
app_path="$derived_data/Build/Products/Debug-iphoneos/OliviaPlay.app"
[[ -d "$app_path" ]] || { echo 'Build terminou sem produzir OliviaPlay.app.' >&2; exit 1; }
xcrun devicectl device install app --device "$device" "$app_path"
if $launch; then
  if ! xcrun devicectl device process launch --device "$device" "$bundle_id"; then
    echo 'O aplicativo foi instalado, mas o iPad não permitiu sua abertura. Consulte o erro acima.' >&2
    echo 'Se o perfil ainda não for confiável: Ajustes > Geral > VPN e Gerenciamento de Dispositivo > sua conta > Confiar.' >&2
    echo 'Depois abra Mundo da Olívia no iPad. Não é necessário reinstalar para concluir essa confiança.' >&2
    exit 3
  fi
fi
echo 'Mundo da Olívia instalado no iPad.'

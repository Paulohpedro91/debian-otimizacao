#!/usr/bin/env bash
#
# debian-otimizacao.sh
# Script de manutenção e otimização segura para Debian e derivados com animação.
#

set -Eeuo pipefail

# --- Configurações & Variáveis Globais ---
readonly SCRIPT_NAME="$(basename "$0")"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

DRY_RUN=false
NON_INTERACTIVE=false

# --- Funções de Output ---
log()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $*"; }
err()  { echo -e "${RED}[ERRO]${NC} $*" >&2; }

# --- Animação de Loading / Spinner ---
# Oculta o cursor durante a animação e restaura no final
hide_cursor() { tput civis 2>/dev/null || true; }
show_cursor() { tput cnorm 2>/dev/null || true; }

# --- Tratamento Robusto de Sinais e Erros ---
cleanup() {
    local exit_code=$?
    show_cursor
    if [[ $exit_code -ne 0 ]]; then
        err "O script foi interrompido ou falhou (código de saída: $exit_code)."
    fi
    exit "$exit_code"
}
trap cleanup EXIT
trap 'show_cursor; err "Sinal de interrupção (SIGINT/SIGTERM) recebido. A abortar..."; exit 130' INT TERM

# --- Processamento Seguro de Opções / Parâmetros ---
show_help() {
    cat << EOF
Uso: sudo $SCRIPT_NAME [OPÇÕES]

Opções:
  -d, --dry-run        Modo simulação (não executa comandos reais).
  -y, --yes            Modo não interativo (responde 'sim' a todas as perguntas).
  -h, --help           Exibe esta mensagem de ajuda.

Exemplo:
  sudo ./$SCRIPT_NAME --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -y|--yes)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            err "Opção inválida: $1"
            show_help
            exit 1
            ;;
    esac
done

# --- Validações Iniciais ---
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    err "Este script deve ser executado com privilégios de root (ex: sudo $0)."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    err "Gerenciador de pacotes 'apt-get' não encontrado. Script compatível apenas com Debian e derivados."
    exit 1
fi

if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
else
    err "Ficheiro /etc/os-release não encontrado. Sistema não identificado."
    exit 1
fi

# --- Função de Execução com Animação de Carregamento ---
run_task() {
    local label="$1"
    shift
    
    if $DRY_RUN; then
        log "$label"
        echo -e "   ${CYAN}+ $*${NC}"
        return 0
    fi

    # Executa o comando em segundo plano guardando a saída num ficheiro temporário
    local tmp_log
    tmp_log="$(mktemp)"
    
    "$@" > "$tmp_log" 2>&1 &
    local pid=$!

    # Caracteres da animação
    local spinchars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    local delay=0.1

    hide_cursor

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % ${#spinchars} ))
        printf "\r${CYAN}[%s]${NC} %s..." "${spinchars:$i:1}" "$label"
        sleep "$delay"
    done

    wait "$pid"
    local exit_code=$?

    show_cursor

    if [[ $exit_code -eq 0 ]]; then
        printf "\r\033[K" # Limpa a linha atual
        ok "$label"
        rm -f "$tmp_log"
        return 0
    else
        printf "\r\033[K" # Limpa a linha atual
        err "Falha em: $label"
        echo "----------------------------------------"
        cat "$tmp_log"
        echo "----------------------------------------"
        rm -f "$tmp_log"
        return "$exit_code"
    fi
}

# --- Início do Script ---
echo
echo "=============================================="
echo "     OTIMIZAÇÃO / MANUTENÇÃO DO DEBIAN"
echo "=============================================="
echo "Sistema : ${PRETTY_NAME:-Debian}"
echo "Kernel  : $(uname -r)"
echo "Data    : $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo

if $DRY_RUN; then
    warn "MODO SIMULAÇÃO ATIVADO: nenhuma alteração será feita."
else
    warn "O script irá atualizar pacotes e remover caches/dependências desnecessárias."
    if ! $NON_INTERACTIVE; then
        read -r -p "Deseja continuar? [s/N] " answer
        if [[ ! "$answer" =~ ^[Ss]$ ]]; then
            echo "Operação cancelada pelo utilizador."
            exit 0
        fi
    fi
fi

# Definir modo não interativo para o APT durante a execução
export DEBIAN_FRONTEND=noninteractive

# 1. Atualizar índices
run_task "Atualizando índices dos repositórios APT" apt-get update -y

# 2. Atualização completa do sistema
run_task "Atualizando pacotes instalados e pacotes de sistema" apt-get full-upgrade -y

# 3. Corrigir dependências pendentes
run_task "Verificando e corrigindo dependências quebradas" apt-get install -f -y

# 4. Remover pacotes órfãos e configurações residuais
run_task "Removendo pacotes órfãos e ficheiros residuais" apt-get autoremove --purge -y

# 5. Limpeza do cache do APT
run_task "Limpando pacotes obsoleto do cache do APT" apt-get autoclean -y
run_task "Removendo arquivos restantes do cache do APT" apt-get clean

# 6. Otimização de Logs (systemd journald)
if command -v journalctl >/dev/null 2>&1; then
    run_task "Limpando logs antigos do systemd journal (mantendo 7 dias)" journalctl --vacuum-time=7d
fi

# 7. Arquivos temporários (systemd-tmpfiles)
if command -v systemd-tmpfiles >/dev/null 2>&1; then
    run_task "Limpando ficheiros temporários do sistema" systemd-tmpfiles --clean
fi

# 8. Suporte e limpeza de Flatpak (se instalado)
if command -v flatpak >/dev/null 2>&1; then
    run_task "Removendo runtimes não utilizados do Flatpak" flatpak uninstall --unused -y
fi

# 9. Suporte e limpeza de Snap (se instalado)
if command -v snap >/dev/null 2>&1; then
    clean_snaps() {
        snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
            snap remove "$snapname" --revision="$revision" || true
        done
    }
    run_task "Removendo revisões desativadas de pacotes Snap" clean_snaps
fi

# 10. Atualização do cache de fontes
if command -v fc-cache >/dev/null 2>&1; then
    run_task "Atualizando cache de fontes do sistema" fc-cache -f
fi

# 11. Auditoria e verificação do dpkg
if $DRY_RUN; then
    run_task "Verificando integridade da base de dados do dpkg" dpkg --audit
else
    if dpkg --audit >/dev/null 2>&1; then
        ok "Verificação de integridade do dpkg concluída sem erros."
    else
        warn "O dpkg reportou possíveis inconsistências. Execute 'dpkg --audit' manualmente."
    fi
fi

# 12. Exibir estado do disco
echo
log "Espaço em disco atual no ponto de montagem principal (/):"
df -h / | awk 'NR==1 || NR==2'

echo
echo "=============================================="
if $DRY_RUN; then
    echo " SIMULAÇÃO CONCLUÍDA COM SUCESSO"
    echo " Execute sem a opção --dry-run para aplicar."
else
    echo " MANUTENÇÃO E OTIMIZAÇÃO CONCLUÍDAS"
fi
echo "=============================================="
echo

if ! $DRY_RUN; then
    ok "O sistema foi atualizado e limpo com sucesso."
    
    if [[ -f /var/run/reboot-required ]]; then
        warn "ATENÇÃO: Foi instalada uma atualização crítica (Kernel/Glibc). Recomenda-se REINICIAR o sistema."
    fi
fi

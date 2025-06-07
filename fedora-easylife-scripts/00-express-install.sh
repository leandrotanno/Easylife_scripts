#!/bin/bash

# ============================================================================
# FEDORA SETUP - INSTALADOR AUTOMÁTICO INTELIGENTE
# ============================================================================
# Execução única como usuário normal - sudo apenas quando necessário
# Sem alternância confusa entre root/user durante execução
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configurações
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.fedora-complete-setup.log"
STATE_FILE="$HOME/.fedora-setup-state"
REQUIRED_SCRIPTS=("01-fedora-setup.sh" "02-fedora-post-install.sh" "03-ssh-setup.sh" "zsh-setup.sh")

# ============================================================================
# FUNÇÕES UTILITÁRIAS
# ============================================================================

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    🚀 FEDORA EXPRESS INSTALLER                          ║${NC}"
    echo -e "${PURPLE}║                                                                          ║${NC}"
    echo -e "${PURPLE}║               Instalação inteligente em execução única                  ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}⚡ Execução como usuário normal - sudo apenas quando necessário${NC}"
    echo -e "${CYAN}🎯 Sem alternância confusa entre root e user${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${BOLD}${BLUE}▶ $1${NC}"
    echo -e "${CYAN}$2${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# ============================================================================
# VERIFICAÇÕES PRÉ-INSTALAÇÃO
# ============================================================================

check_user() {
    if [ "$EUID" -eq 0 ]; then
        print_error "NÃO execute este script como root!"
        echo ""
        print_info "Execute como usuário normal:"
        echo -e "${CYAN}  ./$(basename "$0")${NC}"
        echo ""
        print_info "O script usará sudo automaticamente apenas quando necessário"
        exit 1
    fi
}

check_system() {
    print_info "Verificando sistema..."
    
    # Verificar Fedora
    if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
        print_error "Este script é específico para Fedora Linux"
        exit 1
    fi
    
    # Verificar versão
    local fedora_version=$(grep -oP 'VERSION_ID=\K\d+' /etc/os-release)
    if [ "$fedora_version" -lt 39 ]; then
        print_warning "Versão do Fedora ($fedora_version) pode não ser totalmente compatível"
        read -p "Continuar? [y/N]: " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Verificar internet
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_error "Sem conexão com a internet"
        exit 1
    fi
    
    # Verificar sudo
    if ! sudo -n true 2>/dev/null; then
        print_info "Testando acesso sudo..."
        if ! sudo true; then
            print_error "Acesso sudo necessário"
            exit 1
        fi
    fi
    
    print_success "Sistema OK (Fedora $fedora_version)"
}

check_scripts() {
    print_info "Verificando scripts..."
    
    local missing=()
    for script in "${REQUIRED_SCRIPTS[@]}"; do
        if [ ! -f "$INSTALL_DIR/$script" ]; then
            missing+=("$script")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Scripts não encontrados:"
        printf '  ❌ %s\n' "${missing[@]}"
        exit 1
    fi
    
    # Tornar executáveis
    for script in "${REQUIRED_SCRIPTS[@]}"; do
        chmod +x "$INSTALL_DIR/$script"
    done
    
    print_success "Scripts OK"
}

# ============================================================================
# GERENCIAMENTO DE ESTADO
# ============================================================================

save_state() {
    cat > "$STATE_FILE" << EOF
PHASE_COMPLETED="$1"
TIMESTAMP="$(date)"
USER="$USER"
EOF
    log_message "Estado salvo: Fase $1 concluída"
}

load_state() {
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
        return 0
    fi
    return 1
}

clear_state() {
    rm -f "$STATE_FILE"
    log_message "Estado limpo"
}

# ============================================================================
# INSTALAÇÃO INTELIGENTE
# ============================================================================

install_base_system() {
    print_step "FASE 1: SISTEMA BASE" "Instalação base via sudo - sem alternância de usuário"
    
    log_message "=== FASE 1: SISTEMA BASE ==="
    
    # Executar script base com sudo, mas mantendo contexto do usuário
    print_info "Executando configuração base do sistema..."
    print_info "Você pode ser solicitado a inserir sua senha sudo..."
    
    if sudo -E "$INSTALL_DIR/01-fedora-setup.sh" install; then
        save_state "1"
        print_success "Sistema base instalado com sucesso"
        
        # Verificar se precisa adicionar usuário ao docker
        if ! groups "$USER" | grep -q docker; then
            print_info "Adicionando usuário ao grupo docker..."
            sudo usermod -aG docker "$USER"
            
            print_warning "Grupo docker adicionado - logout/login pode ser necessário"
            print_info "Tentando continuar sem logout primeiro..."
            
            # Tentar recarregar grupos sem logout
            exec sg docker -c "$0 --continue"
        fi
        
        return 0
    else
        print_error "Falha na instalação do sistema base"
        exit 1
    fi
}

install_docker_workspace() {
    print_step "FASE 2: DOCKER WORKSPACE" "Configurando ambientes de desenvolvimento"
    
    log_message "=== FASE 2: DOCKER WORKSPACE ==="
    
    # Verificar se Docker está acessível
    if ! docker ps >/dev/null 2>&1; then
        print_warning "Docker não está acessível"
        print_info "Isso pode ser normal após primeira instalação"
        
        # Tentar diferentes abordagens
        print_info "Tentando recarregar permissões do grupo docker..."
        
        # Método 1: sg (switch group)
        if command -v sg >/dev/null 2>&1; then
            print_info "Usando 'sg docker' para acessar Docker..."
            exec sg docker -c "$0 --continue-docker"
        fi
        
        # Método 2: newgrp (se sg não funcionar)
        if command -v newgrp >/dev/null 2>&1; then
            print_info "Tentando com 'newgrp docker'..."
            exec newgrp docker -c "$0 --continue-docker"
        fi
        
        # Se nada funcionar, pedir logout
        print_error "Não foi possível acessar Docker sem logout/login"
        print_warning "NECESSÁRIO: Faça logout/login e execute:"
        echo -e "${CYAN}  $0 --continue${NC}"
        exit 0
    fi
    
    # Docker OK, continuar
    print_info "Docker acessível, configurando workspace..."
    
    if "$INSTALL_DIR/02-fedora-post-install.sh" all; then
        save_state "2"
        print_success "Docker workspace configurado"
        return 0
    else
        print_error "Falha na configuração do Docker workspace"
        exit 1
    fi
}

install_zsh_terminal() {
    print_step "FASE 3: TERMINAL ZSH" "Instalando ZSH + Oh My Zsh + Spaceship"
    
    log_message "=== FASE 3: ZSH TERMINAL ==="
    
    if "$INSTALL_DIR/zsh-setup.sh" install; then
        save_state "3"
        print_success "Terminal ZSH configurado"
        
        # Verificar se ZSH virou shell padrão
        if ! getent passwd "$USER" | grep -q zsh; then
            print_warning "ZSH instalado mas não é o shell padrão"
            print_info "Execute 'zsh' para testar ou faça logout/login"
        fi
        
        return 0
    else
        print_warning "Falha no ZSH - continuando sem ele"
        save_state "3"
        return 0
    fi
}

setup_ssh_info() {
    print_step "SSH SETUP" "Informações sobre configuração SSH"
    
    print_info "SSH pode ser configurado opcionalmente após a instalação"
    print_info "Para configurar SSH execute:"
    echo -e "${CYAN}  ./04-ssh-setup.sh${NC}"
    echo ""
    print_info "Isso configurará chaves para GitHub, GitLab, VPS, etc."
    
    save_state "4"
}

finalize_installation() {
    print_step "FINALIZAÇÃO" "Testando ambiente e finalizando"
    
    log_message "=== FINALIZAÇÃO ==="
    
    # Testar ambiente básico
    print_info "Testando ambiente..."
    
    if [ -d "$HOME/docker-workspace" ]; then
        print_success "Docker workspace criado"
        
        # Testar um script
        if [ -x "$HOME/docker-workspace/scripts/start-datascience.sh" ]; then
            print_info "Testando ambiente Data Science..."
            
            # Iniciar ambiente DS em background para teste
            cd "$HOME/docker-workspace/scripts"
            if timeout 30 ./start-datascience.sh >/dev/null 2>&1; then
                print_success "Ambiente Data Science funcional"
            else
                print_warning "Ambiente Data Science pode precisar de ajustes"
            fi
        fi
    fi
    
    save_state "5"
    clear_state  # Limpar estado pois acabou
    
    show_final_summary
}

# ============================================================================
# RESUMO FINAL
# ============================================================================

show_final_summary() {
    echo ""
    echo -e "${GREEN}🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BOLD}${BLUE}📦 INSTALADO:${NC}"
    echo -e "${GREEN}✅ Sistema Base Fedora${NC} (Docker, VS Code, codecs, fontes)"
    echo -e "${GREEN}✅ Docker Workspace${NC} (Node.js, Python, Data Science)"
    echo -e "${GREEN}✅ Terminal ZSH${NC} (Oh My Zsh, Spaceship, plugins)"
    echo -e "${GREEN}ℹ️  SSH Setup${NC} (disponível via ./04-ssh-setup.sh)"
    echo ""
    
    echo -e "${BOLD}${CYAN}🚀 COMANDOS DISPONÍVEIS:${NC}"
    echo ""
    echo -e "${YELLOW}# Ambientes Docker:${NC}"
    echo -e "  start-node          # Node.js + React/Vue"
    echo -e "  start-python        # Python Web + PostgreSQL"  
    echo -e "  start-ds            # Jupyter Lab + MLflow"
    echo -e "  stop-all            # Parar todos containers"
    echo -e "  dev-status          # Status dos ambientes"
    echo ""
    echo -e "${YELLOW}# Acesso rápido:${NC}"
    echo -e "  dw                  # Ir para docker-workspace"
    echo -e "  node-shell          # Acessar container Node.js"
    echo -e "  python-shell        # Acessar container Python"
    echo ""
    
    echo -e "${BOLD}${PURPLE}🧪 TESTE RÁPIDO:${NC}"
    echo -e "${CYAN}1. Execute:${NC} start-ds"
    echo -e "${CYAN}2. Abra:${NC} http://localhost:8888"
    echo -e "${CYAN}3. Token:${NC} dev123"
    echo ""
    
    echo -e "${BOLD}${YELLOW}📋 PRÓXIMOS PASSOS OPCIONAIS:${NC}"
    echo ""
    echo -e "${CYAN}• SSH Setup:${NC} ./04-ssh-setup.sh"
    echo -e "${CYAN}• Git Config:${NC}"
    echo -e "  git config --global user.name 'Seu Nome'"
    echo -e "  git config --global user.email 'seu@email.com'"
    echo -e "${CYAN}• NVM (Node.js):${NC}"
    echo -e "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    echo ""

    echo -e "${BOLD}${YELLOW}📋 AÇÃO MANUAL NECESSÁRIA:${NC}"
    echo ""
    echo -e "${RED}🔑 SSH SETUP:${NC}"
    echo -e "${CYAN}• Execute manualmente: ${YELLOW}./04-ssh-setup.sh${NC}"
    echo -e "${CYAN}• Configura chaves para: GitHub, GitLab, VPS${NC}"
    echo -e "${CYAN}• Necessário para: git clone, push, acesso remoto${NC}"
    echo -e "${CYAN}• Tempo estimado: 5-10 minutos${NC}"
    echo ""
    echo -e "${BLUE}💡 O SSH é manual porque precisa de suas informações pessoais${NC}"
    echo ""
    
    # Verificar se precisa logout
    if ! getent passwd "$USER" | grep -q zsh; then
        echo -e "${BOLD}${RED}⚠️  AÇÃO NECESSÁRIA:${NC}"
        echo -e "${YELLOW}Faça logout/login para ativar ZSH como shell padrão${NC}"
        echo -e "${CYAN}Ou execute 'zsh' para testar agora${NC}"
        echo ""
    fi
    
    echo -e "${BOLD}${GREEN}🏁 FEDORA PRONTO PARA DESENVOLVIMENTO FULL-STACK + ML!${NC}"
    
    log_message "=== INSTALAÇÃO COMPLETA FINALIZADA ==="
}

# ============================================================================
# CONTINUAÇÃO DE EXECUÇÃO
# ============================================================================

continue_installation() {
    print_info "Continuando instalação..."
    
    if load_state; then
        local phase=${PHASE_COMPLETED:-0}
        print_info "Continuando da fase $phase"
        
        case "$phase" in
            "1")
                install_docker_workspace
                install_zsh_terminal
                setup_ssh_info
                finalize_installation
                ;;
            "2")
                install_zsh_terminal
                setup_ssh_info
                finalize_installation
                ;;
            "3")
                setup_ssh_info
                finalize_installation
                ;;
            "4")
                finalize_installation
                ;;
            "5")
                print_success "Instalação já concluída!"
                show_final_summary
                ;;
            *)
                print_warning "Estado inválido, reiniciando..."
                clear_state
                run_complete_installation
                ;;
        esac
    else
        print_info "Nenhum estado anterior, iniciando do zero..."
        run_complete_installation
    fi
}

continue_docker_phase() {
    # Continuação específica para fase Docker após sg/newgrp
    print_info "Continuando fase Docker com permissões atualizadas..."
    
    if docker ps >/dev/null 2>&1; then
        print_success "Docker agora acessível!"
        install_docker_workspace
        install_zsh_terminal
        setup_ssh_info
        finalize_installation
    else
        print_error "Docker ainda não acessível"
        print_warning "Faça logout/login e execute: $0 --continue"
        exit 1
    fi
}

# ============================================================================
# INSTALAÇÃO PRINCIPAL
# ============================================================================

run_complete_installation() {
    print_header
    
    print_info "Iniciando instalação expressa..."
    log_message "=== INÍCIO INSTALAÇÃO EXPRESSA ==="
    log_message "Usuário: $USER"
    log_message "Diretório: $INSTALL_DIR"
    
    # Verificações
    check_user
    check_system
    check_scripts
    
    # Mostrar resumo
    echo -e "${BOLD}${CYAN}📋 SERÁ INSTALADO:${NC}"
    echo -e "• ${BLUE}Sistema Base${NC} → Fedora + Docker + VS Code + codecs"
    echo -e "• ${BLUE}Docker Workspace${NC} → Ambientes Node.js, Python, Data Science"
    echo -e "• ${BLUE}Terminal ZSH${NC} → Oh My Zsh + Spaceship + plugins"
    echo -e "• ${BLUE}SSH Info${NC} → Instruções para configurar depois"
    echo ""
    
    read -p "Continuar? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_info "Instalação cancelada"
        exit 0
    fi
    
    # Executar fases sequencialmente
    install_base_system
    install_docker_workspace
    install_zsh_terminal
    setup_ssh_info
    finalize_installation
}

# ============================================================================
# FUNÇÃO PRINCIPAL
# ============================================================================

show_usage() {
    echo -e "${PURPLE}🚀 Fedora Express Installer${NC}"
    echo ""
    echo -e "${CYAN}Uso:${NC}"
    echo -e "  $0                    # Instalação completa"
    echo -e "  $0 --continue         # Continuar instalação interrompida"
    echo -e "  $0 --status           # Mostrar status atual"
    echo -e "  $0 --reset            # Limpar estado e recomeçar"
    echo ""
    echo -e "${CYAN}Características:${NC}"
    echo -e "• ${GREEN}Execução única${NC} como usuário normal"
    echo -e "• ${GREEN}Sudo automático${NC} apenas quando necessário"
    echo -e "• ${GREEN}Sem alternância${NC} confusa root/user"
    echo -e "• ${GREEN}Estado persistente${NC} para recuperação"
    echo ""
}

main() {
    case "${1:-}" in
        "--continue")
            continue_installation
            ;;
        "--continue-docker")
            continue_docker_phase
            ;;
        "--status")
            if load_state; then
                print_info "Fase ${PHASE_COMPLETED:-0} concluída em ${TIMESTAMP:-'data desconhecida'}"
            else
                print_info "Nenhuma instalação em andamento"
            fi
            ;;
        "--reset")
            clear_state
            print_info "Estado limpo - execute novamente para reinstalar"
            ;;
        "--help"|"-h")
            show_usage
            ;;
        "")
            run_complete_installation
            ;;
        *)
            print_error "Opção inválida: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
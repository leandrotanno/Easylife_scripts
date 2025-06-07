#!/bin/bash

# 🚀 Express Installer - Fedora Setup Automation SMART EDITION
# Executa todos os scripts em sequência com detecção inteligente
# Gerencia privilégios automaticamente e salva estado para recuperação
#
# Uso: 
#   sudo ./express-installer.sh  (primeira execução como root)
#   logout/login quando solicitado
#   ./express-installer.sh       (segunda execução como usuário)

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
STATE_FILE="$HOME/.express-installer-state"
LOG_FILE="$HOME/.express-installer.log"
REQUIRED_SCRIPTS=("01-fedora-setup.sh" "02-fedora-post-install.sh" "04-ssh-setup.sh" "05-zsh-setup.sh" "project-creator.sh")

# ============================================================================
# FUNÇÕES UTILITÁRIAS
# ============================================================================

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║               🚀 EXPRESS INSTALLER SMART EDITION                ║${NC}"
    echo -e "${PURPLE}║          Configuração automática do Fedora para DEV             ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}✨ Detecção inteligente de portas e conflitos${NC}"
    echo -e "${CYAN}🔄 Recuperação automática de falhas${NC}"
    echo -e "${CYAN}⚡ Instalação completa em ~20 minutos${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Verificar se script existe
check_script_exists() {
    local script="$1"
    if [ ! -f "$script" ]; then
        print_error "Script $script não encontrado no diretório atual"
        print_info "Certifique-se de estar no diretório dos scripts"
        return 1
    fi
    return 0
}

# Verificar todos os scripts necessários
check_all_scripts() {
    print_info "Verificando scripts necessários..."
    
    local missing_scripts=()
    for script in "${REQUIRED_SCRIPTS[@]}"; do
        if [ ! -f "$script" ]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        print_error "Scripts não encontrados:"
        for script in "${missing_scripts[@]}"; do
            echo -e "   ${RED}• $script${NC}"
        done
        print_info "Baixe todos os scripts no mesmo diretório"
        return 1
    fi
    
    print_success "Todos os scripts encontrados"
    return 0
}

# Salvar estado do progresso
save_state() {
    local step="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    cat > "$STATE_FILE" << EOF
LAST_STEP="$step"
TIMESTAMP="$timestamp"
USER_MODE="$([[ $EUID -eq 0 ]] && echo "root" || echo "user")"
DOCKER_GROUP_ADDED="$DOCKER_GROUP_ADDED"
NEED_LOGOUT="$NEED_LOGOUT"
EOF
    log_message "Estado salvo: $step"
}

# Carregar estado anterior
load_state() {
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
        return 0
    fi
    return 1
}

# Verificar se Docker funciona sem sudo
check_docker_permissions() {
    if command -v docker >/dev/null 2>&1; then
        if docker ps >/dev/null 2>&1; then
            return 0  # Docker funciona
        else
            return 1  # Docker instalado mas sem permissão
        fi
    else
        return 2  # Docker não instalado
    fi
}

# Detectar estado atual do sistema
detect_system_state() {
    print_info "Detectando estado atual do sistema..."
    
    # Verificar se é primeira execução
    if [ ! -f "$STATE_FILE" ]; then
        if [ "$EUID" -eq 0 ]; then
            echo "FIRST_RUN_ROOT"
        else
            echo "FIRST_RUN_USER"
        fi
        return
    fi
    
    # Carregar estado anterior
    load_state
    
    # Verificar se precisa de logout/login
    if [ "$NEED_LOGOUT" = "true" ] && [ "$USER_MODE" = "user" ]; then
        check_docker_permissions
        local docker_status=$?
        
        if [ $docker_status -eq 1 ]; then
            echo "NEED_LOGOUT"
            return
        elif [ $docker_status -eq 0 ]; then
            echo "CONTINUE_USER"
            return
        fi
    fi
    
    # Determinar próximo passo baseado no estado
    case "$LAST_STEP" in
        "fedora_setup_complete")
            if [ "$EUID" -eq 0 ]; then
                echo "SWITCH_TO_USER"
            else
                echo "CONTINUE_USER"
            fi
            ;;
        "post_install_complete"|"ssh_setup_complete"|"zsh_setup_complete")
            echo "CONTINUE_USER"
            ;;
        *)
            if [ "$EUID" -eq 0 ]; then
                echo "CONTINUE_ROOT"
            else
                echo "CONTINUE_USER"
            fi
            ;;
    esac
}

# ============================================================================
# ETAPAS DE INSTALAÇÃO
# ============================================================================

# Etapa 1: Fedora Setup (como root)
run_fedora_setup() {
    print_info "Executando Fedora Setup (como root)..."
    
    if [ "$EUID" -ne 0 ]; then
        print_error "Esta etapa precisa ser executada como root"
        print_info "Execute: sudo ./express-installer.sh"
        return 1
    fi
    
    # Verificar se já foi executado
    if load_state && [ "$LAST_STEP" = "fedora_setup_complete" ]; then
        print_warning "Fedora setup já foi executado"
        return 0
    fi
    
    log_message "=== INICIANDO FEDORA SETUP ==="
    
    if ! check_script_exists "01-fedora-setup.sh"; then
        return 1
    fi
    
    chmod +x 01-fedora-setup.sh
    
    print_info "Executando 01-fedora-setup.sh install..."
    if ./01-fedora-setup.sh install 2>&1 | tee -a "$LOG_FILE"; then
        save_state "fedora_setup_complete"
        DOCKER_GROUP_ADDED="true"
        NEED_LOGOUT="true"
        print_success "Fedora setup concluído com sucesso"
        return 0
    else
        print_error "Falha no Fedora setup"
        return 1
    fi
}

# Etapa 2: Post Install com portas inteligentes (como usuário)
run_post_install() {
    print_info "Executando Post Install com portas inteligentes (como usuário)..."
    
    if [ "$EUID" -eq 0 ]; then
        print_error "Esta etapa deve ser executada como usuário normal"
        print_info "Execute: ./express-installer.sh (sem sudo)"
        return 1
    fi
    
    # Verificar Docker
    check_docker_permissions
    local docker_status=$?
    
    if [ $docker_status -eq 2 ]; then
        print_error "Docker não está instalado. Execute fedora-setup primeiro"
        return 1
    elif [ $docker_status -eq 1 ]; then
        print_error "Docker instalado mas usuário não tem permissões"
        print_warning "Execute logout/login e tente novamente"
        print_info "Ou execute: newgrp docker"
        return 1
    fi
    
    # Verificar se já foi executado
    if load_state && [ "$LAST_STEP" = "post_install_complete" ]; then
        print_warning "Post install já foi executado"
        return 0
    fi
    
    log_message "=== INICIANDO POST INSTALL ==="
    
    # Usar script com portas inteligentes se disponível
    local post_install_script="02-fedora-post-install.sh"
    if [ -f "02-fedora-post-install-SMART-PORTS.sh" ]; then
        post_install_script="02-fedora-post-install-SMART-PORTS.sh"
        print_info "Usando versão com portas inteligentes"
    fi
    
    if ! check_script_exists "$post_install_script"; then
        return 1
    fi
    
    chmod +x "$post_install_script"
    
    print_info "Executando $post_install_script all..."
    if ./"$post_install_script" all 2>&1 | tee -a "$LOG_FILE"; then
        save_state "post_install_complete"
        print_success "Post install concluído com sucesso"
        
        # Mostrar portas configuradas se disponível
        if [ -f "$HOME/docker-workspace/configs/ports.conf" ]; then
            echo ""
            print_info "Portas configuradas automaticamente:"
            source "$HOME/docker-workspace/configs/ports.conf"
            echo -e "${CYAN}   Node.js: $NODEJS_DEV_PORT, $NODEJS_VITE_PORT, $NODEJS_ALT_PORT${NC}"
            echo -e "${CYAN}   Python:  $PYTHON_API_PORT, $PYTHON_FLASK_PORT, $PYTHON_STREAMLIT_PORT${NC}"
            echo -e "${CYAN}   DS:      $DATASCIENCE_JUPYTER_PORT, $DATASCIENCE_MLFLOW_PORT${NC}"
        fi
        
        return 0
    else
        print_error "Falha no post install"
        return 1
    fi
}

# Etapa 3: SSH Setup (como usuário - opcional)
run_ssh_setup() {
    print_info "Configuração SSH (opcional)..."
    
    if [ "$EUID" -eq 0 ]; then
        print_error "Esta etapa deve ser executada como usuário normal"
        return 1
    fi
    
    # Verificar se já foi executado
    if load_state && [ "$LAST_STEP" = "ssh_setup_complete" ]; then
        print_warning "SSH setup já foi executado"
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}Deseja configurar chaves SSH? (GitHub, GitLab, VPS)${NC}"
    echo -e "${CYAN}Isso é opcional mas recomendado para desenvolvimento${NC}"
    read -p "Configurar SSH? [Y/n]: " setup_ssh
    
    if [[ "$setup_ssh" =~ ^[Nn]$ ]]; then
        print_info "SSH setup pulado"
        save_state "ssh_setup_skipped"
        return 0
    fi
    
    if ! check_script_exists "04-ssh-setup.sh"; then
        print_warning "Script SSH não encontrado, pulando..."
        return 0
    fi
    
    chmod +x 04-ssh-setup.sh
    
    log_message "=== INICIANDO SSH SETUP ==="
    print_info "Executando 04-ssh-setup.sh..."
    
    if ./04-ssh-setup.sh 2>&1 | tee -a "$LOG_FILE"; then
        save_state "ssh_setup_complete"
        print_success "SSH setup concluído"
        return 0
    else
        print_warning "SSH setup teve problemas, mas continuando..."
        save_state "ssh_setup_with_issues"
        return 0
    fi
}

# Etapa 4: ZSH Setup (como usuário - opcional)
run_zsh_setup() {
    print_info "Configuração ZSH (opcional)..."
    
    if [ "$EUID" -eq 0 ]; then
        print_error "Esta etapa deve ser executada como usuário normal"
        return 1
    fi
    
    # Verificar se já foi executado
    if load_state && [ "$LAST_STEP" = "zsh_setup_complete" ]; then
        print_warning "ZSH setup já foi executado"
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}Deseja configurar ZSH + Oh My Zsh + Spaceship theme?${NC}"
    echo -e "${CYAN}Terminal bonito e produtivo com 200+ aliases${NC}"
    read -p "Configurar ZSH? [Y/n]: " setup_zsh
    
    if [[ "$setup_zsh" =~ ^[Nn]$ ]]; then
        print_info "ZSH setup pulado"
        save_state "zsh_setup_skipped"
        return 0
    fi
    
    if ! check_script_exists "05-zsh-setup.sh"; then
        print_warning "Script ZSH não encontrado, pulando..."
        return 0
    fi
    
    chmod +x 05-zsh-setup.sh
    
    log_message "=== INICIANDO ZSH SETUP ==="
    print_info "Executando 05-zsh-setup.sh install..."
    
    if ./05-zsh-setup.sh install 2>&1 | tee -a "$LOG_FILE"; then
        save_state "zsh_setup_complete"
        print_success "ZSH setup concluído"
        print_warning "Faça logout/login para ativar ZSH como shell padrão"
        return 0
    else
        print_warning "ZSH setup teve problemas, mas continuando..."
        save_state "zsh_setup_with_issues"
        return 0
    fi
}

# Etapa 5: Configurar Project Creator
setup_project_creator() {
    print_info "Configurando Project Creator..."
    
    if [ "$EUID" -eq 0 ]; then
        print_error "Esta etapa deve ser executada como usuário normal"
        return 1
    fi
    
    if ! check_script_exists "project-creator.sh"; then
        print_warning "Project Creator não encontrado, pulando..."
        return 0
    fi
    
    chmod +x project-creator.sh
    
    # Verificar se existe versão com portas inteligentes
    local creator_script="project-creator.sh"
    if [ -f "project-creator-FULL-CLEAN.sh" ]; then
        creator_script="project-creator-FULL-CLEAN.sh"
        chmod +x "$creator_script"
        print_info "Usando Project Creator com portas inteligentes"
    fi
    
    # Criar link simbólico para facilitar uso
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(pwd)/$creator_script" "$HOME/.local/bin/create-project"
    
    # Integrar com configuração de portas se disponível
    if [ -f "$HOME/docker-workspace/configs/ports.conf" ]; then
        print_info "Integrando com configuração de portas existente"
        
        # Criar script wrapper que carrega configuração
        cat > "$HOME/.local/bin/create-project-smart" << 'EOF'
#!/bin/bash
# Project Creator com integração de portas inteligentes

# Carregar configuração de portas se disponível
if [ -f "$HOME/docker-workspace/configs/ports.conf" ]; then
    source "$HOME/docker-workspace/configs/ports.conf"
fi

# Executar project creator
exec "$(dirname "$0")/create-project" "$@"
EOF
        chmod +x "$HOME/.local/bin/create-project-smart"
        
        print_success "Project Creator integrado com sistema de portas"
        print_info "Use: create-project ou create-project-smart"
    fi
    
    log_message "Project Creator configurado"
    return 0
}

# ============================================================================
# LÓGICA PRINCIPAL
# ============================================================================

# Mostrar status de recuperação
show_recovery_status() {
    if load_state; then
        echo ""
        print_info "Recuperando instalação anterior..."
        echo -e "${CYAN}   Última etapa: $LAST_STEP${NC}"
        echo -e "${CYAN}   Timestamp: $TIMESTAMP${NC}"
        echo -e "${CYAN}   Modo: $USER_MODE${NC}"
        echo ""
    fi
}

# Mostrar instruções baseadas no estado
show_instructions() {
    local state="$1"
    
    case "$state" in
        "FIRST_RUN_ROOT")
            echo -e "${YELLOW}📋 PRIMEIRA EXECUÇÃO DETECTADA${NC}"
            echo -e "${CYAN}Este script irá executar na seguinte ordem:${NC}"
            echo -e "${CYAN}  1. Fedora Setup (como root) - Docker, VS Code, repositórios${NC}"
            echo -e "${CYAN}  2. Post Install (como usuário) - workspace Docker + portas inteligentes${NC}"
            echo -e "${CYAN}  3. SSH Setup (opcional) - chaves GitHub/GitLab${NC}"
            echo -e "${CYAN}  4. ZSH Setup (opcional) - terminal produtivo${NC}"
            echo ""
            echo -e "${RED}⚠️ SERÁ SOLICITADO LOGOUT/LOGIN entre as etapas${NC}"
            ;;
        "FIRST_RUN_USER")
            print_error "Execute primeiro como root: sudo ./express-installer.sh"
            exit 1
            ;;
        "NEED_LOGOUT")
            print_warning "Docker foi instalado mas usuário não tem permissões"
            echo ""
            echo -e "${YELLOW}📋 AÇÃO NECESSÁRIA:${NC}"
            echo -e "${CYAN}1. Faça logout da sessão atual${NC}"
            echo -e "${CYAN}2. Faça login novamente${NC}"
            echo -e "${CYAN}3. Execute: ./express-installer.sh${NC}"
            echo ""
            echo -e "${BLUE}Ou execute agora: newgrp docker${NC}"
            exit 0
            ;;
        "SWITCH_TO_USER")
            print_warning "Etapa como root concluída"
            echo ""
            echo -e "${YELLOW}📋 PRÓXIMO PASSO:${NC}"
            echo -e "${CYAN}Execute como usuário normal: ./express-installer.sh${NC}"
            exit 0
            ;;
    esac
}

# Função principal
main() {
    # Verificar argumentos especiais
    case "$1" in
        "--help"|"-h")
            print_header
            echo -e "${CYAN}Uso:${NC}"
            echo -e "${YELLOW}  sudo ./express-installer.sh${NC}     # Primeira execução (como root)"
            echo -e "${YELLOW}  logout/login${NC}                    # Quando solicitado"
            echo -e "${YELLOW}  ./express-installer.sh${NC}          # Segunda execução (como usuário)"
            echo ""
            echo -e "${CYAN}Opções:${NC}"
            echo -e "${YELLOW}  --status${NC}                        # Verificar estado atual"
            echo -e "${YELLOW}  --reset${NC}                         # Resetar estado (começar do zero)"
            echo -e "${YELLOW}  --logs${NC}                          # Mostrar logs"
            exit 0
            ;;
        "--status")
            if load_state; then
                echo -e "${BLUE}📊 STATUS DA INSTALAÇÃO:${NC}"
                echo -e "${CYAN}   Última etapa: $LAST_STEP${NC}"
                echo -e "${CYAN}   Timestamp: $TIMESTAMP${NC}"
                echo -e "${CYAN}   Modo: $USER_MODE${NC}"
                echo -e "${CYAN}   Docker group: $DOCKER_GROUP_ADDED${NC}"
                echo -e "${CYAN}   Need logout: $NEED_LOGOUT${NC}"
            else
                echo -e "${YELLOW}Nenhuma instalação anterior encontrada${NC}"
            fi
            exit 0
            ;;
        "--reset")
            rm -f "$STATE_FILE"
            print_success "Estado resetado"
            exit 0
            ;;
        "--logs")
            if [ -f "$LOG_FILE" ]; then
                less "$LOG_FILE"
            else
                print_info "Nenhum log encontrado"
            fi
            exit 0
            ;;
    esac
    
    print_header
    
    # Verificar scripts necessários
    if ! check_all_scripts; then
        exit 1
    fi
    
    # Detectar estado atual
    local current_state=$(detect_system_state)
    show_recovery_status
    show_instructions "$current_state"
    
    log_message "=== EXPRESS INSTALLER INICIADO ==="
    log_message "Estado detectado: $current_state"
    
    # Executar baseado no estado
    case "$current_state" in
        "FIRST_RUN_ROOT"|"CONTINUE_ROOT")
            echo -e "${BOLD}${BLUE}🚀 INICIANDO INSTALAÇÃO COMO ROOT${NC}"
            echo ""
            
            if run_fedora_setup; then
                echo ""
                print_success "Etapa ROOT concluída com sucesso!"
                echo ""
                echo -e "${YELLOW}📋 PRÓXIMO PASSO OBRIGATÓRIO:${NC}"
                echo -e "${RED}1. Faça LOGOUT da sessão atual${NC}"
                echo -e "${RED}2. Faça LOGIN novamente${NC}"
                echo -e "${RED}3. Execute: ./express-installer.sh${NC}"
                echo ""
                echo -e "${CYAN}Isso é necessário para que o Docker funcione sem sudo${NC}"
            else
                print_error "Falha na instalação como root"
                exit 1
            fi
            ;;
            
        "CONTINUE_USER")
            echo -e "${BOLD}${BLUE}🚀 CONTINUANDO INSTALAÇÃO COMO USUÁRIO${NC}"
            echo ""
            
            # Executar etapas do usuário em sequência
            local failed=false
            
            if ! run_post_install; then failed=true; fi
            if ! $failed && ! run_ssh_setup; then failed=true; fi
            if ! $failed && ! run_zsh_setup; then failed=true; fi
            if ! $failed && ! setup_project_creator; then failed=true; fi
            
            if ! $failed; then
                save_state "installation_complete"
                echo ""
                print_success "🎉 INSTALAÇÃO COMPLETA!"
                show_final_summary
            else
                print_error "Algumas etapas falharam, verifique os logs"
                exit 1
            fi
            ;;
            
        "NEED_LOGOUT"|"SWITCH_TO_USER")
            # Instruções já mostradas em show_instructions
            ;;
            
        *)
            print_error "Estado não reconhecido: $current_state"
            exit 1
            ;;
    esac
}

# Mostrar resumo final
show_final_summary() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    🎉 INSTALAÇÃO CONCLUÍDA!                     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Sistema Fedora configurado para desenvolvimento Docker-First${NC}"
    echo ""
    echo -e "${BLUE}🚀 COMANDOS PRINCIPAIS:${NC}"
    echo -e "${CYAN}   start-node${NC}           # Ambiente Node.js + Redis"
    echo -e "${CYAN}   start-python${NC}         # FastAPI + PostgreSQL + Redis"
    echo -e "${CYAN}   start-ds${NC}             # Jupyter Lab + MLflow + GPU"
    echo -e "${CYAN}   create-project${NC}       # Criar novos projetos"
    echo -e "${CYAN}   dev-status${NC}           # Status de todos containers"
    echo ""
    echo -e "${BLUE}🛠️ CLI TOOLS:${NC}"
    echo -e "${CYAN}   git-helper${NC}           # Git management visual"
    echo -e "${CYAN}   docker-helper${NC}        # Docker management completo"
    echo -e "${CYAN}   database-helper${NC}      # PostgreSQL management"
    echo -e "${CYAN}   dev-switcher${NC}         # Navegar entre projetos"
    echo ""
    
    # Mostrar portas se configuradas
    if [ -f "$HOME/docker-workspace/configs/ports.conf" ]; then
        source "$HOME/docker-workspace/configs/ports.conf"
        echo -e "${BLUE}🌐 PORTAS CONFIGURADAS AUTOMATICAMENTE:${NC}"
        echo -e "${CYAN}   Node.js: $NODEJS_DEV_PORT, $NODEJS_VITE_PORT, $NODEJS_ALT_PORT${NC}"
        echo -e "${CYAN}   Python:  $PYTHON_API_PORT, $PYTHON_FLASK_PORT, $PYTHON_STREAMLIT_PORT${NC}"
        echo -e "${CYAN}   DS:      $DATASCIENCE_JUPYTER_PORT, $DATASCIENCE_MLFLOW_PORT${NC}"
        echo ""
    fi
    
    echo -e "${YELLOW}🔥 TESTE RÁPIDO:${NC}"
    echo -e "${CYAN}   create-project${NC}       # Criar um projeto React/FastAPI"
    echo -e "${CYAN}   start-python${NC}         # Iniciar ambiente Python"
    echo ""
    echo -e "${PURPLE}Happy coding! 🚀${NC}"
    
    # Verificar se precisa de logout para ZSH
    if load_state && [[ "$LAST_STEP" =~ zsh_setup ]]; then
        echo ""
        print_warning "Para ativar ZSH como shell padrão, faça logout/login"
    fi
}

# Executar função principal
main "$@"
#!/bin/bash

# =============================================================================
# EXPRESS INSTALLER - Fedora Development Setup
# Automatiza máximo possível respeitando dependências obrigatórias
# =============================================================================

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Estado
STATE_FILE="$HOME/.fedora-setup-state"

# ADICIONAR AQUI - Nova função de verificação
check_required_files() {
    local missing=()
    
    if [ ! -f "./01-fedora-setup.sh" ]; then missing+=("01-fedora-setup.sh"); fi
    if [ ! -f "./02-fedora-post-install.sh" ]; then missing+=("02-fedora-post-install.sh"); fi
    if [ ! -f "./zsh-setup.sh" ]; then missing+=("zsh-setup.sh"); fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Arquivos necessários não encontrados:"
        printf '%s\n' "${missing[@]}"
        exit 1
    fi
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }

# Verificar estado atual
check_state() {
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
    fi
}

# Salvar estado
save_state() {
    echo "STEP_COMPLETED=$1" > "$STATE_FILE"
    echo "TIMESTAMP=$(date)" >> "$STATE_FILE"
}

# Verificar se é primeira execução
is_first_run() {
    [ ! -f "$STATE_FILE" ] || [ "${STEP_COMPLETED:-0}" -eq 0 ]
}

# Verificar se precisa ser root
check_root_phase() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Fase 1 precisa ser executada como ROOT"
        echo -e "${CYAN}Execute: ${YELLOW}sudo $0${NC}"
        exit 1
    fi
}

# Verificar se precisa ser usuário
check_user_phase() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Fases 2+ devem ser executadas como USUÁRIO normal"
        echo -e "${CYAN}Execute sem sudo: ${YELLOW}$0${NC}"
        exit 1
    fi
}

# Fase 1: Sistema base
phase1_system_base() {
    print_step "FASE 1: SISTEMA BASE (como ROOT)"
    check_root_phase
    
    if [ ! -f "./01-fedora-setup.sh" ]; then
        print_error "01-fedora-setup.sh não encontrado!"
        exit 1
    fi
    
    print_info "Executando configuração base do sistema..."
    if ./01-fedora-setup.sh install; then
        save_state 1
        print_success "Fase 1 concluída!"
        
        print_warning "NECESSÁRIO LOGOUT/LOGIN para Docker funcionar"
        print_info "Após logout/login, execute novamente: $0"
        exit 0
    else
        print_error "Falha na Fase 1"
        exit 1
    fi
}

# Fase 2: Docker workspace
phase2_docker_workspace() {
    print_step "FASE 2: DOCKER WORKSPACE (como usuário)"
    check_user_phase
    
    # Verificar se Docker está funcionando
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker não está funcionando!"
        print_warning "Você fez logout/login após a Fase 1?"
        print_info "Se não, faça logout/login e execute novamente"
        exit 1
    fi
    
    if [ ! -f "./02-fedora-post-install.sh" ]; then
        print_error "02-fedora-post-install.sh não encontrado!"
        exit 1
    fi
    
    print_info "Configurando workspace Docker..."
    if ./02-fedora-post-install.sh all; then
        save_state 2
        print_success "Fase 2 concluída!"
    else
        print_error "Falha na Fase 2"
        exit 1
    fi
}

# Fase 3: SSH automático (apenas GitHub)
phase3_ssh_auto() {
    print_step "FASE 3: SSH SETUP (manual recomendado)"
    
    if [ ! -f "./03-ssh-setup.sh" ]; then
        print_warning "03-ssh-setup.sh não encontrado - pulando SSH"
        save_state 3
        return
    fi
    
    print_info "SSH setup disponível para configuração manual"
    print_warning "Execute quando necessário: ./03-ssh-setup.sh"
    
    # NÃO tentar automação - SSH precisa ser manual
    save_state 3
    print_info "SSH setup disponível"
}

# Fase 4: ZSH terminal
phase4_zsh_terminal() {
    print_step "FASE 4: ZSH TERMINAL (como usuário)"
    
    if [ ! -f "./zsh-setup.sh" ]; then
        print_warning "zsh-setup.sh não encontrado - pulando ZSH"
        save_state 4
        return
    fi
    
    print_info "Instalando ZSH + Oh My Zsh + Spaceship..."
    if ./zsh-setup.sh install; then
        save_state 4
        print_success "Fase 4 concluída!"
        
        # Verificar se ZSH foi definido como shell padrão
        if getent passwd "$USER" | grep -q zsh; then
            print_warning "NECESSÁRIO LOGOUT/LOGIN para ativar ZSH"
            print_info "Ou execute 'zsh' para testar agora"
        fi
    else
        print_warning "Falha no ZSH - continuando sem terminal otimizado"
        save_state 4
    fi
}

# Fase 5: Finalização e testes
phase5_finalization() {
    print_step "FASE 5: FINALIZAÇÃO E TESTES"
    
    print_info "Testando ambiente Data Science..."
    
    # Testar se workspace existe
    if [ -d "$HOME/docker-workspace" ]; then
        print_success "Docker workspace OK"
    else
        print_error "Docker workspace não encontrado!"
        return 1
    fi
    
    # Testar scripts
    if [ -f "$HOME/docker-workspace/scripts/start-datascience.sh" ]; then
        print_info "Iniciando ambiente Data Science..."
        cd "$HOME/docker-workspace/scripts"
        
        if ./start-datascience.sh; then
            save_state 5
            print_success "🎉 SETUP COMPLETO!"
            
            print_step "AMBIENTE PRONTO PARA USO!"
            echo -e "${CYAN}🌐 Jupyter Lab: ${YELLOW}http://localhost:8888${NC} (token: dev123)"
            echo -e "${CYAN}🧪 MLflow: ${YELLOW}http://localhost:5555${NC}"
            echo -e "${CYAN}📊 Status: ${YELLOW}~/docker-workspace/scripts/status.sh${NC}"
            echo ""
            echo -e "${BLUE}🛠️ CLI Tools disponíveis:${NC}"
            echo -e "${YELLOW}• git-helper.sh${NC}     - Git management"
            echo -e "${YELLOW}• docker-helper.sh${NC}   - Docker management"
            echo -e "${YELLOW}• project-creator.sh${NC} - Criar projetos"
            echo -e "${YELLOW}• dev-switcher.sh${NC}    - Navegar projetos"
            echo -e "${YELLOW}• database-helper.sh${NC} - PostgreSQL helper"
            echo ""
            echo -e "${GREEN}✅ Fedora configurado para desenvolvimento Full-Stack + ML!${NC}"
            
            # Limpar estado
            rm -f "$STATE_FILE"
        else
            print_error "Falha ao iniciar Data Science"
            return 1
        fi
    else
        print_error "Scripts não encontrados!"
        return 1
    fi
}

# Menu de recuperação
show_recovery_menu() {
    print_step "MENU DE RECUPERAÇÃO"
    echo "Estado atual: Fase ${STEP_COMPLETED:-0} concluída"
    echo ""
    echo "1. 🔄 Continuar do ponto de parada"
    echo "2. 🗑️ Reset completo (apagar estado)"
    echo "3. 📊 Mostrar status atual"
    echo "4. 🚪 Sair"
    echo ""
    read -p "Escolha [1-4]: " choice
    
    case $choice in
        1) return 0 ;;
        2) 
            rm -f "$STATE_FILE"
            print_info "Estado resetado - execute novamente"
            exit 0
            ;;
        3)
            show_current_status
            exit 0
            ;;
        4) exit 0 ;;
        *) 
            print_error "Opção inválida"
            show_recovery_menu
            ;;
    esac
}

# Mostrar status atual
show_current_status() {
    print_step "STATUS ATUAL DO SISTEMA"
    
    # Sistema base
    if command -v docker >/dev/null 2>&1; then
        print_success "Docker instalado"
        if docker ps >/dev/null 2>&1; then
            print_success "Docker funcionando"
        else
            print_warning "Docker instalado mas não funciona (precisa logout/login?)"
        fi
    else
        print_error "Docker não instalado"
    fi
    
    # Workspace
    if [ -d "$HOME/docker-workspace" ]; then
        print_success "Docker workspace existe"
    else
        print_warning "Docker workspace não encontrado"
    fi
    
    # SSH
    if [ -f "$HOME/.ssh/id_github" ]; then
        print_success "SSH configurado"
    else
        print_warning "SSH não configurado"
    fi
    
    # ZSH
    if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
        print_success "ZSH ativo"
    else
        print_warning "ZSH não ativo (shell atual: $SHELL)"
    fi
}

# Função principal
main() {
    check_required_files
    check_state
    
    # Se não tem estado, começar do início
    if is_first_run; then
        if [ "$EUID" -eq 0 ]; then
            phase1_system_base
        else
            print_error "Execute primeiro como ROOT: sudo $0"
            exit 1
        fi
    fi
    
    # Continuar baseado no estado
    case "${STEP_COMPLETED:-0}" in
        0)
            if [ "$EUID" -eq 0 ]; then
                phase1_system_base
            else
                print_error "Execute como ROOT: sudo $0"
                exit 1
            fi
            ;;
        1)
            phase2_docker_workspace
            phase3_ssh_auto
            phase4_zsh_terminal
            ;;
        2)
            phase3_ssh_auto
            phase4_zsh_terminal
            ;;
        3)
            phase4_zsh_terminal
            ;;
        4)
            phase5_finalization
            ;;
        5)
            print_success "Setup já concluído!"
            show_current_status
            ;;
        *)
            print_warning "Estado inconsistente detectado"
            show_recovery_menu
            ;;
    esac
}

# Tratamento de argumentos
case "${1:-}" in
    "status")
        show_current_status
        ;;
    "reset")
        rm -f "$STATE_FILE"
        print_info "Estado resetado"
        ;;
    "recovery")
        check_state
        show_recovery_menu
        ;;
    *)
        main
        ;;
esac
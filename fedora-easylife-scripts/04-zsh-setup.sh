#!/bin/bash

# ZSH Setup - Terminal Customization Complete
# Instala ZSH + Oh My Zsh + Spaceship + Plugins + Aliases otimizados
# Execute como usuário normal após todos os outros scripts

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="$HOME/.zsh-setup.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}❌ Execute como usuário normal, não root${NC}"
        exit 1
    fi
}

# Header
show_header() {
    clear
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                  ⚡ ZSH TERMINAL SETUP                        ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🚀 Configuração completa do terminal para desenvolvimento${NC}"
    echo -e "${CYAN}📦 ZSH + Oh My Zsh + Spaceship + Plugins + Aliases${NC}"
    echo ""
}

# Verificar dependências
check_dependencies() {
    echo -e "${BLUE}🔍 Verificando dependências...${NC}"
    
    local missing_tools=()
    
    # Verificar ferramentas essenciais
    if ! command_exists git; then missing_tools+=("git"); fi
    if ! command_exists curl; then missing_tools+=("curl"); fi
    if ! command_exists wget; then missing_tools+=("wget"); fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}❌ Ferramentas não encontradas: ${missing_tools[*]}${NC}"
        echo -e "${CYAN}💡 Execute primeiro o fedora-setup.sh${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Dependências OK${NC}"
}

# Instalar ZSH
install_zsh() {
    echo -e "${BLUE}📦 Instalando ZSH...${NC}"
    log_message "=== INSTALANDO ZSH ==="
    
    if command_exists zsh; then
        echo -e "${GREEN}✅ ZSH já instalado${NC}"
        echo -e "${CYAN}Versão: $(zsh --version)${NC}"
    else
        echo -e "${CYAN}📥 Instalando ZSH via dnf...${NC}"
        sudo dnf install -y zsh
        
        if ! command_exists zsh; then
            echo -e "${RED}❌ Falha na instalação do ZSH${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✅ ZSH instalado com sucesso${NC}"
    fi
    
    log_message "✓ ZSH instalado"
}

# Instalar Oh My Zsh
install_oh_my_zsh() {
    echo -e "${BLUE}🎨 Instalando Oh My Zsh...${NC}"
    log_message "=== INSTALANDO OH MY ZSH ==="
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${GREEN}✅ Oh My Zsh já instalado${NC}"
    else
        echo -e "${CYAN}📥 Baixando Oh My Zsh...${NC}"
        
        # Instalar Oh My Zsh sem mudar shell automaticamente
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            echo -e "${RED}❌ Falha na instalação do Oh My Zsh${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Oh My Zsh instalado com sucesso${NC}"
    fi
    
    log_message "✓ Oh My Zsh instalado"
}

# Instalar Spaceship theme
install_spaceship() {
    echo -e "${BLUE}🚀 Instalando Spaceship theme...${NC}"
    log_message "=== INSTALANDO SPACESHIP THEME ==="
    
    local spaceship_dir="$HOME/.oh-my-zsh/custom/themes/spaceship-prompt"
    
    if [ -d "$spaceship_dir" ]; then
        echo -e "${YELLOW}⚠️ Spaceship já existe, atualizando...${NC}"
        cd "$spaceship_dir" && git pull
    else
        echo -e "${CYAN}📥 Clonando Spaceship theme...${NC}"
        git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$spaceship_dir" --depth=1
        
        if [ ! -d "$spaceship_dir" ]; then
            echo -e "${RED}❌ Falha no clone do Spaceship${NC}"
            exit 1
        fi
    fi
    
    # Criar symlink
    local theme_link="$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
    if [ ! -L "$theme_link" ]; then
        ln -s "$spaceship_dir/spaceship.zsh-theme" "$theme_link"
        echo -e "${GREEN}✅ Symlink do Spaceship criado${NC}"
    fi
    
    log_message "✓ Spaceship theme instalado"
}

# Instalar plugins ZSH
install_zsh_plugins() {
    echo -e "${BLUE}🔌 Instalando plugins ZSH...${NC}"
    log_message "=== INSTALANDO PLUGINS ZSH ==="
    
    local custom_plugins="$HOME/.oh-my-zsh/custom/plugins"
    
    # zsh-autosuggestions
    echo -e "${CYAN}📦 Instalando zsh-autosuggestions...${NC}"
    if [ ! -d "$custom_plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins/zsh-autosuggestions"
        echo -e "${GREEN}✅ zsh-autosuggestions instalado${NC}"
    else
        echo -e "${YELLOW}⚠️ zsh-autosuggestions já existe${NC}"
    fi
    
    # zsh-completions
    echo -e "${CYAN}📦 Instalando zsh-completions...${NC}"
    if [ ! -d "$custom_plugins/zsh-completions" ]; then
        git clone https://github.com/zsh-users/zsh-completions "$custom_plugins/zsh-completions"
        echo -e "${GREEN}✅ zsh-completions instalado${NC}"
    else
        echo -e "${YELLOW}⚠️ zsh-completions já existe${NC}"
    fi
    
    # zsh-syntax-highlighting
    echo -e "${CYAN}📦 Instalando zsh-syntax-highlighting...${NC}"
    if [ ! -d "$custom_plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom_plugins/zsh-syntax-highlighting"
        echo -e "${GREEN}✅ zsh-syntax-highlighting instalado${NC}"
    else
        echo -e "${YELLOW}⚠️ zsh-syntax-highlighting já existe${NC}"
    fi
    
    # zsh-you-should-use
    echo -e "${CYAN}📦 Instalando zsh-you-should-use...${NC}"
    if [ ! -d "$custom_plugins/you-should-use" ]; then
        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$custom_plugins/you-should-use"
        echo -e "${GREEN}✅ zsh-you-should-use instalado${NC}"
    else
        echo -e "${YELLOW}⚠️ zsh-you-should-use já existe${NC}"
    fi
    
    log_message "✓ Plugins ZSH instalados"
}

# Configurar .zshrc
configure_zshrc() {
    echo -e "${BLUE}⚙️ Configurando .zshrc...${NC}"
    log_message "=== CONFIGURANDO ZSHRC ==="
    
    # Backup do .zshrc atual
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CYAN}📋 Backup do .zshrc criado${NC}"
    fi
    
    # Criar novo .zshrc
    cat > "$HOME/.zshrc" << 'EOF'
# ============================================================================
# ZSH CONFIGURATION - Docker-First Development Environment
# ============================================================================

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"

# Theme: Spaceship
ZSH_THEME="spaceship"

# Plugins
plugins=(
    git
    sudo
    zsh-autosuggestions
    zsh-completions
    zsh-syntax-highlighting
    you-should-use
    docker
    docker-compose
    python
    node
    npm
    yarn
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# SPACESHIP THEME CONFIGURATION
# ============================================================================

# Configuração personalizada do Spaceship
SPACESHIP_PROMPT_ORDER=(
  time          # Hora
  user          # Username
  dir           # Diretório atual
  host          # Hostname
  git           # Informações do Git
  node          # Versão do Node.js
  ruby          # Versão do Ruby
  python        # Versão do Python
  docker        # Status do Docker
  venv          # Virtualenv Python
  line_sep      # Separador de linha
  battery       # Nível da bateria
  jobs          # Status de background jobs
  exit_code     # Código de saída do último comando
  char          # Prompt character
)

# Configurações específicas de cada seção
SPACESHIP_PROMPT_ADD_NEWLINE=true
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "
SPACESHIP_TIME_SHOW=true
SPACESHIP_TIME_PREFIX="["
SPACESHIP_TIME_SUFFIX="] "
SPACESHIP_USER_SHOW=always
SPACESHIP_DIR_TRUNC=3
SPACESHIP_GIT_SYMBOL="🌱 "
SPACESHIP_GIT_STATUS_PREFIX=" ["
SPACESHIP_GIT_STATUS_SUFFIX="]"
SPACESHIP_GIT_STATUS_MODIFIED="✹"
SPACESHIP_GIT_STATUS_UNTRACKED="✭"
SPACESHIP_GIT_STATUS_ADDED="✚"
SPACESHIP_NODE_PREFIX="⬢ "
SPACESHIP_RUBY_PREFIX="💎 "
SPACESHIP_PYTHON_PREFIX="🐍 "
SPACESHIP_DOCKER_PREFIX="🐳 "

# Cores personalizadas
SPACESHIP_DIR_COLOR="cyan"
SPACESHIP_GIT_BRANCH_COLOR="yellow"
SPACESHIP_USER_COLOR="green"
SPACESHIP_HOST_COLOR="blue"

# Configurações de performance
SPACESHIP_PROMPT_ASYNC=true
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=true

# Git
SPACESHIP_GIT_SHOW=true
SPACESHIP_GIT_BRANCH_SHOW=true
SPACESHIP_GIT_STATUS_SHOW=true

# Docker
SPACESHIP_DOCKER_SHOW=true

# Node.js
SPACESHIP_NODE_SHOW=true

# Python
SPACESHIP_PYTHON_SHOW=true

# ============================================================================
# NAVIGATION ALIASES
# ============================================================================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# ============================================================================
# FILE MANAGEMENT
# ============================================================================

alias ls='ls --color=auto'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'
alias lt='ls -ltrh'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias md='mkdir -p'

alias df='df -h'
alias du='du -h'
alias dud='du -d 1 -h'

# ============================================================================
# SEARCH & FIND
# ============================================================================

alias grep='grep --color=auto'
alias ff='find . -type f -name'
alias fd='find . -type d -name'
alias h='history | grep'

# ============================================================================
# GIT ALIASES
# ============================================================================

alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'
alias gst='git stash'
alias gstp='git stash pop'

# ============================================================================
# DOCKER ALIASES
# ============================================================================

alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias di='docker images'
alias dclean='docker system prune -af && docker volume prune -f'

# Docker Development Environments
alias dw='cd ~/docker-workspace'
alias start-node='~/docker-workspace/scripts/start-nodejs.sh'
alias start-python='~/docker-workspace/scripts/start-python.sh'
alias start-ds='~/docker-workspace/scripts/start-datascience.sh'
alias stop-all='~/docker-workspace/scripts/stop-all.sh'
alias dev-status='~/docker-workspace/scripts/status.sh'

# Container Access
alias node-shell='docker exec -it nodejs-dev sh'
alias python-shell='docker exec -it python-web bash'
alias jupyter-shell='docker exec -it jupyter-lab bash'

# ============================================================================
# CLI TOOLS
# ============================================================================

alias git-help='git-helper.sh'
alias docker-help='docker-helper.sh'
alias create-project='project-creator.sh'
alias dev-switch='dev-switcher.sh'
alias db-help='database-helper.sh'
alias compose-help='compose-templates.sh'

# ============================================================================
# LANGUAGE ALIASES
# ============================================================================

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# Node.js
alias n='node'
alias nr='npm run'
alias ni='npm install'
alias nrs='npm run start'
alias nrd='npm run dev'

# ============================================================================
# SYSTEM UTILITIES
# ============================================================================

alias c='clear'
alias e='exit'
alias reload='source ~/.zshrc'

# System Info
alias ports='netstat -tulanp'
alias mem='free -h'
alias myip='curl -s http://ipecho.net/plain; echo'

# ============================================================================
# PROJECT NAVIGATION
# ============================================================================

alias projects='cd ~/docker-workspace'
alias nodejs-projects='cd ~/docker-workspace/nodejs'
alias python-projects='cd ~/docker-workspace/python-web'
alias ds-projects='cd ~/docker-workspace/datascience'

# ============================================================================
# FUNCTIONS
# ============================================================================

# Create and enter directory
function mkcd() { mkdir -p "$1" && cd "$1"; }

# Create backup of file
function bak() { cp "$1"{,.bak}; }

# Quick Docker container access
function dsh() { docker exec -it "$1" /bin/bash; }

# Git commit shortcut
function gac() { git add . && git commit -m "$1"; }

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

export DOCKER_WORKSPACE="$HOME/docker-workspace"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="code"
export VISUAL="code"

# NVM (if installed)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# ============================================================================
# WELCOME MESSAGE
# ============================================================================

if [[ $- == *i* ]]; then
    echo "🚀 Docker-First Development Environment Ready!"
    echo "📦 Quick commands: start-node, start-python, start-ds, dev-switch"
    echo "🛠️  CLI Tools: git-help, docker-help, create-project, db-help"
    echo ""
fi

# ============================================================================
# AUTO-COMPLETIONS
# ============================================================================

# Load custom completions
if [ -d "$ZSH/custom/plugins/zsh-completions/src" ]; then
    fpath=($ZSH/custom/plugins/zsh-completions/src $fpath)
fi

# Initialize completions
autoload -U compinit && compinit
EOF

    echo -e "${GREEN}✅ .zshrc configurado com sucesso${NC}"
    log_message "✓ .zshrc configurado"
}

# Configurar ZSH como shell padrão
set_default_shell() {
    echo -e "${BLUE}🔧 Configurando ZSH como shell padrão...${NC}"
    log_message "=== CONFIGURANDO SHELL PADRÃO ==="
    
    local current_shell=$(echo $SHELL)
    
    if [[ "$current_shell" == *"zsh"* ]]; then
        echo -e "${GREEN}✅ ZSH já é o shell padrão${NC}"
    else
        echo -e "${CYAN}🔄 Alterando shell padrão para ZSH...${NC}"
        
        # Verificar se ZSH está em /etc/shells
        if ! grep -q "$(which zsh)" /etc/shells; then
            echo "$(which zsh)" | sudo tee -a /etc/shells
        fi
        
        # Alterar shell padrão
        chsh -s $(which zsh)
        
        echo -e "${GREEN}✅ Shell padrão alterado para ZSH${NC}"
        echo -e "${YELLOW}⚠️ Faça logout/login para aplicar a mudança${NC}"
    fi
    
    log_message "✓ Shell padrão configurado"
}

# Testar configuração
test_configuration() {
    echo -e "${BLUE}🧪 Testando configuração...${NC}"
    log_message "=== TESTANDO CONFIGURAÇÃO ==="
    
    # Testar se Oh My Zsh foi instalado
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${GREEN}✅ Oh My Zsh: OK${NC}"
    else
        echo -e "${RED}❌ Oh My Zsh: ERRO${NC}"
    fi
    
    # Testar se Spaceship foi instalado
    if [ -f "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme" ]; then
        echo -e "${GREEN}✅ Spaceship theme: OK${NC}"
    else
        echo -e "${RED}❌ Spaceship theme: ERRO${NC}"
    fi
    
    # Testar plugins
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    local plugins=("zsh-autosuggestions" "zsh-completions" "zsh-syntax-highlighting" "you-should-use")
    
    for plugin in "${plugins[@]}"; do
        if [ -d "$plugins_dir/$plugin" ]; then
            echo -e "${GREEN}✅ Plugin $plugin: OK${NC}"
        else
            echo -e "${RED}❌ Plugin $plugin: ERRO${NC}"
        fi
    done
    
    # Testar .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        echo -e "${GREEN}✅ .zshrc: OK${NC}"
    else
        echo -e "${RED}❌ .zshrc: ERRO${NC}"
    fi
    
    log_message "✓ Teste de configuração concluído"
}

# Mostrar resumo final
show_summary() {
    echo -e "${GREEN}🎉 CONFIGURAÇÃO ZSH CONCLUÍDA!${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
    echo -e "${BLUE}📦 Instalado:${NC}"
    echo -e "${GREEN}✅ ZSH${NC} - Shell moderno"
    echo -e "${GREEN}✅ Oh My Zsh${NC} - Framework de configuração"
    echo -e "${GREEN}✅ Spaceship${NC} - Theme bonito e funcional"
    echo -e "${GREEN}✅ Plugins essenciais${NC} - Autosuggestions, completions, syntax highlighting"
    echo -e "${GREEN}✅ Aliases otimizados${NC} - Para Docker-first development"
    echo ""
    echo -e "${BLUE}🚀 Comandos rápidos disponíveis:${NC}"
    echo -e "${YELLOW}• start-node, start-python, start-ds${NC} - Iniciar ambientes"
    echo -e "${YELLOW}• git-help, docker-help, db-help${NC} - CLI tools"
    echo -e "${YELLOW}• create-project, dev-switch${NC} - Gestão de projetos"
    echo ""
    echo -e "${RED}⚠️ IMPORTANTE:${NC}"
    echo -e "${YELLOW}1. Faça logout/login para ativar ZSH como shell padrão${NC}"
    echo -e "${YELLOW}2. ou execute 'zsh' para testar agora${NC}"
    echo ""
    echo -e "${PURPLE}🎨 Para testar agora: zsh${NC}"
}

# Função principal
main() {
    case "$1" in
        "install")
            show_header
            check_not_root
            log_message "=== INÍCIO CONFIGURAÇÃO ZSH ==="
            
            check_dependencies
            install_zsh
            install_oh_my_zsh
            install_spaceship
            install_zsh_plugins
            configure_zshrc
            set_default_shell
            test_configuration
            
            show_summary
            log_message "=== CONFIGURAÇÃO ZSH CONCLUÍDA ==="
            ;;
        "update")
            echo -e "${BLUE}🔄 Atualizando configuração ZSH...${NC}"
            check_not_root
            
            # Atualizar Oh My Zsh
            if [ -d "$HOME/.oh-my-zsh" ]; then
                cd "$HOME/.oh-my-zsh" && git pull
                echo -e "${GREEN}✅ Oh My Zsh atualizado${NC}"
            fi
            
            # Atualizar Spaceship
            local spaceship_dir="$HOME/.oh-my-zsh/custom/themes/spaceship-prompt"
            if [ -d "$spaceship_dir" ]; then
                cd "$spaceship_dir" && git pull
                echo -e "${GREEN}✅ Spaceship atualizado${NC}"
            fi
            
            # Atualizar plugins
            local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
            for plugin in zsh-autosuggestions zsh-completions zsh-syntax-highlighting you-should-use; do
                if [ -d "$plugins_dir/$plugin" ]; then
                    cd "$plugins_dir/$plugin" && git pull
                    echo -e "${GREEN}✅ Plugin $plugin atualizado${NC}"
                fi
            done
            
            echo -e "${GREEN}✅ Atualização concluída${NC}"
            ;;
        *)
            echo -e "${PURPLE}⚡ ZSH Terminal Setup${NC}"
            echo -e "${CYAN}Configuração completa do terminal para desenvolvimento${NC}"
            echo ""
            echo -e "${YELLOW}Uso: $0 {install|update}${NC}"
            echo ""
            echo -e "${CYAN}Comandos:${NC}"
            echo -e "${YELLOW}  install${NC}  - Instalação completa (ZSH + Oh My Zsh + Spaceship + Plugins)"
            echo -e "${YELLOW}  update${NC}   - Atualizar Oh My Zsh, Spaceship e plugins"
            echo ""
            echo -e "${PURPLE}💡 Execute 'install' para configuração completa${NC}"
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
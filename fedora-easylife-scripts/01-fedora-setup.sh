#!/bin/bash

# Script de Configuração Automática para Fedora 42+
# Criado para desenvolvimento Full-Stack, ML e Data Science
# Data: $(date)
# PARTE 1 - Configuração Base e Repositórios

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Arquivo de log
LOG_FILE="/var/log/fedora-setup.log"
MAX_LOG_SIZE=10485760  # 10MB

# Função para logging
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Função para rotacionar logs se ficarem muito grandes
rotate_log() {
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]; then
        sudo mv "$LOG_FILE" "${LOG_FILE}.old"
        sudo touch "$LOG_FILE"
        sudo chmod 666 "$LOG_FILE"
        log_message "Log rotacionado - arquivo ficou muito grande"
    fi
}

# Função para verificar se é root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Este script precisa ser executado como root (sudo)${NC}"
        exit 1
    fi
}

# Função para cleanup em caso de interrupção
cleanup() {
    log_message "Script interrompido. Executando limpeza..."
    dnf autoremove -y >/dev/null 2>&1
    dnf clean all >/dev/null 2>&1
    exit 1
}

# Função para verificar conexão com internet
check_internet() {
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${RED}✗ Sem conexão com a internet${NC}"
        log_message "ERRO: Sem conexão com a internet"
        return 1
    fi
    echo -e "${GREEN}✓ Conexão com internet OK${NC}"
    return 0
}

# Função de atualização do sistema
system_update() {
    echo -e "${BLUE}🔄 Atualizando sistema base...${NC}"
    log_message "=== INICIANDO ATUALIZAÇÃO DO SISTEMA ==="
    
    if ! check_internet; then
        return 1
    fi
    
    # Atualizar sistema
    if dnf update -y 2>&1 | tee -a "$LOG_FILE"; then
        log_message "✓ Sistema atualizado com sucesso"
        echo -e "${GREEN}✓ Sistema atualizado${NC}"
    else
        log_message "✗ Erro ao atualizar sistema"
        echo -e "${RED}✗ Erro na atualização${NC}"
        return 1
    fi
    
    # Upgrade de distribuição se disponível
    if dnf system-upgrade download --refresh -y 2>/dev/null; then
        log_message "⚠ Atualização de distribuição disponível"
        echo -e "${YELLOW}⚠ Atualização de distribuição disponível - execute 'sudo dnf system-upgrade reboot' quando apropriado${NC}"
    fi
    
    return 0
}

# Função para configurar repositórios essenciais
setup_repositories() {
    echo -e "${PURPLE}📦 Configurando repositórios essenciais...${NC}"
    log_message "=== CONFIGURANDO REPOSITÓRIOS ==="
    
    # RPM Fusion Free
    echo -e "${CYAN}Instalando RPM Fusion Free...${NC}"
    if dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" 2>&1 | tee -a "$LOG_FILE"; then
        log_message "✓ RPM Fusion Free instalado"
    else
        log_message "⚠ RPM Fusion Free já instalado ou erro na instalação"
    fi
    
    # RPM Fusion Non-Free
    echo -e "${CYAN}Instalando RPM Fusion Non-Free...${NC}"
    if dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" 2>&1 | tee -a "$LOG_FILE"; then
        log_message "✓ RPM Fusion Non-Free instalado"
    else
        log_message "⚠ RPM Fusion Non-Free já instalado ou erro na instalação"
    fi
    
    # Flathub
    echo -e "${CYAN}Configurando Flathub...${NC}"
    if ! dnf list installed flatpak >/dev/null 2>&1; then
        dnf install -y flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a "$LOG_FILE"
    log_message "✓ Flathub configurado"
    
    # Visual Studio Code
    echo -e "${CYAN}Configurando repositório VS Code...${NC}"
    rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>&1 | tee -a "$LOG_FILE"
    cat > /etc/yum.repos.d/vscode.repo << EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    log_message "✓ Repositório VS Code configurado"
    
    # Google Chrome
    echo -e "${CYAN}Configurando repositório Google Chrome...${NC}"
    cat > /etc/yum.repos.d/google-chrome.repo << EOF
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    log_message "✓ Repositório Google Chrome configurado"
    
    # Atualizar cache dos repositórios
    dnf makecache 2>&1 | tee -a "$LOG_FILE"
    echo -e "${GREEN}✓ Repositórios configurados${NC}"
    
    return 0
}

# Função para configurar Docker (seguindo documentação oficial)
setup_docker() {
    echo -e "${BLUE}🐳 Configurando Docker...${NC}"
    log_message "=== CONFIGURANDO DOCKER ==="
    
    # Instalar pré-requisitos
    echo -e "${CYAN}Instalando pré-requisitos do Docker...${NC}"
    dnf -y install dnf-plugins-core 2>&1 | tee -a "$LOG_FILE"
    
    # Adicionar repositório oficial do Docker
    echo -e "${CYAN}Adicionando repositório oficial do Docker...${NC}"
    dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>&1 | tee -a "$LOG_FILE"
    
    # Instalar Docker Engine
    echo -e "${CYAN}Instalando Docker Engine...${NC}"
    if dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tee -a "$LOG_FILE"; then
        log_message "✓ Docker Engine instalado com sucesso"
    else
        log_message "✗ Erro ao instalar Docker Engine"
        echo -e "${RED}✗ Erro na instalação do Docker${NC}"
        return 1
    fi
    
    # Habilitar e iniciar Docker
    echo -e "${CYAN}Habilitando e iniciando serviço Docker...${NC}"
    systemctl enable --now docker 2>&1 | tee -a "$LOG_FILE"
        
    # Verificar se Docker está rodando
    if systemctl is-active --quiet docker; then
        log_message "✓ Serviço Docker iniciado com sucesso"
        echo -e "${GREEN}✓ Docker está rodando${NC}"
    else
        log_message "✗ Falha ao iniciar serviço Docker"
        echo -e "${RED}✗ Falha ao iniciar Docker${NC}"
        return 1
    fi
    
    # Adicionar usuário ao grupo docker
    if [ -n "$SUDO_USER" ]; then
        echo -e "${CYAN}Adicionando usuário $SUDO_USER ao grupo docker...${NC}"
        usermod -aG docker "$USER" 2>&1 | tee -a "$LOG_FILE"
        log_message "✓ Usuário $USER adicionado ao grupo docker"
        echo -e "${GREEN}✓ Usuário adicionado ao grupo docker${NC}"
        echo -e "${YELLOW}⚠ Faça logout/login para usar Docker sem sudo${NC}"
    else
        echo -e "${YELLOW}⚠ Não foi possível detectar o usuário. Adicione manualmente ao grupo docker:${NC}"
        echo -e "${YELLOW}   sudo usermod -aG docker \$USER${NC}"
    fi
    
    # Testar instalação do Docker
    echo -e "${CYAN}Testando instalação do Docker...${NC}"
    if docker --version 2>&1 | tee -a "$LOG_FILE"; then
        log_message "✓ Docker instalado e configurado com sucesso"
        echo -e "${GREEN}✓ Docker configurado com sucesso${NC}"
    else
        log_message "✗ Erro no teste do Docker"
        echo -e "${RED}✗ Erro no teste do Docker${NC}"
        return 1
    fi
    
    return 0
}

# Função para instalar ferramentas de desenvolvimento
install_dev_tools() {
    echo -e "${BLUE}💻 Instalando ferramentas de desenvolvimento...${NC}"
    log_message "=== INSTALANDO FERRAMENTAS DE DESENVOLVIMENTO ==="
    
    # Grupos de desenvolvimento
    echo -e "${CYAN}Instalando grupos de desenvolvimento...${NC}"
    dnf groupinstall -y "Development Tools" "Development Libraries" 2>&1 | tee -a "$LOG_FILE"
    
    # Git e controle de versão
    echo -e "${CYAN}Instalando Git e ferramentas de versionamento...${NC}"
    dnf install -y git git-lfs gh 2>&1 | tee -a "$LOG_FILE"
    
    # Editores e IDEs
    echo -e "${CYAN}Instalando editores...${NC}"
    dnf install -y code 2>&1 | tee -a "$LOG_FILE"
    
    # Configurar Docker
    setup_docker || { 
        echo -e "${RED}Falha na configuração do Docker${NC}"; 
        log_message "✗ Falha na configuração do Docker";
        return 1; 
    }
    
    # Ferramentas essenciais para desenvolvimento
    echo -e "${CYAN}Instalando ferramentas essenciais...${NC}"
    dnf install -y \
        curl wget tree htop \
        unzip p7zip p7zip-plugins unrar \
        jq yq \
        make cmake \
        gcc gcc-c++ \
        python3-devel \
        openssl-devel \
        libffi-devel \
        sqlite-devel \
        readline-devel \
        zlib-devel \
        bzip2-devel \
        ncurses-devel \
        2>&1 | tee -a "$LOG_FILE"
    
    log_message "✓ Ferramentas de desenvolvimento instaladas"
    echo -e "${GREEN}✓ Ferramentas de desenvolvimento instaladas${NC}"
    
    return 0
}

# Função para instalar codecs multimídia
install_multimedia() {
    echo -e "${BLUE}🎵 Instalando codecs multimídia...${NC}"
    log_message "=== INSTALANDO CODECS MULTIMÍDIA ==="
    
    # GStreamer plugins (removendo openh264 problemático)
    echo -e "${CYAN}Instalando plugins GStreamer...${NC}"
    dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel 2>&1 | tee -a "$LOG_FILE"
    
    # Tentar instalar openh264 separadamente (se disponível)
    echo -e "${CYAN}Tentando instalar openh264...${NC}"
    if dnf install -y gstreamer1-plugin-openh264 2>/dev/null; then
        log_message "✓ OpenH264 instalado"
        echo -e "${GREEN}✓ OpenH264 instalado${NC}"
    else
        log_message "⚠ OpenH264 não disponível - continuando sem ele"
        echo -e "${YELLOW}⚠ OpenH264 não disponível - continuando sem ele${NC}"
    fi
    
    # Codecs adicionais
    echo -e "${CYAN}Instalando codecs adicionais...${NC}"
    dnf install -y lame\* --exclude=lame-devel 2>&1 | tee -a "$LOG_FILE"
    dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin 2>&1 | tee -a "$LOG_FILE"
    
    # FFmpeg
    echo -e "${CYAN}Instalando FFmpeg...${NC}"
    dnf install -y ffmpeg ffmpeg-libs 2>&1 | tee -a "$LOG_FILE"
    
    log_message "✓ Codecs multimídia instalados"
    echo -e "${GREEN}✓ Codecs multimídia instalados${NC}"
    
    return 0
}

# Função para instalar aplicativos essenciais
install_applications() {
    echo -e "${BLUE}📱 Instalando aplicativos essenciais...${NC}"
    log_message "=== INSTALANDO APLICATIVOS ==="
    
    # Navegadores
    echo -e "${CYAN}Instalando navegadores...${NC}"
    dnf install -y firefox google-chrome-stable 2>&1 | tee -a "$LOG_FILE"
    
    # Editores de texto e office
    echo -e "${CYAN}Instalando suíte office...${NC}"
    dnf install -y libreoffice 2>&1 | tee -a "$LOG_FILE"
    
    # Multimídia
    echo -e "${CYAN}Instalando aplicativos multimídia...${NC}"
    dnf install -y vlc gimp inkscape 2>&1 | tee -a "$LOG_FILE"
    
    # Utilitários do sistema
    echo -e "${CYAN}Instalando utilitários do sistema...${NC}"
    dnf install -y \
        gnome-tweaks \
        gnome-extensions-app \
        dconf-editor \
        transmission-gtk \
        file-roller \
        neofetch \
        2>&1 | tee -a "$LOG_FILE"
    
    log_message "✓ Aplicativos essenciais instalados"
    echo -e "${GREEN}✓ Aplicativos essenciais instalados${NC}"
    
    return 0
}

# Função para instalar fontes
install_fonts() {
    echo -e "${BLUE}🔤 Instalando fontes...${NC}"
    log_message "=== INSTALANDO FONTES ==="
    
    # Fontes básicas
    dnf install -y \
        google-noto-fonts-common \
        google-noto-sans-fonts \
        google-noto-serif-fonts \
        google-noto-mono-fonts \
        liberation-fonts \
        2>&1 | tee -a "$LOG_FILE"
    
    # Fontes Microsoft (se disponível)
    if dnf list available mscore-fonts >/dev/null 2>&1; then
        dnf install -y mscore-fonts 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Fira Code Nerd Font (para terminal com ícones)
    echo -e "${CYAN}Instalando Fira Code Nerd Font...${NC}"
    NERD_FONT_DIR="/usr/share/fonts/nerd-fonts"
    mkdir -p "$NERD_FONT_DIR"
    
    # Download Fira Code Nerd Font
    FIRA_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    if curl -L "$FIRA_URL" -o /tmp/FiraCode.zip 2>&1 | tee -a "$LOG_FILE"; then
        unzip -o /tmp/FiraCode.zip -d "$NERD_FONT_DIR" 2>&1 | tee -a "$LOG_FILE"
        rm -f /tmp/FiraCode.zip
        
        # Atualizar cache de fontes
        fc-cache -fv 2>&1 | tee -a "$LOG_FILE"
        
        echo -e "${GREEN}✓ Fira Code Nerd Font instalada${NC}"
        log_message "✓ Fira Code Nerd Font instalada"
    else
        echo -e "${YELLOW}⚠ Falha no download da Fira Code Nerd Font${NC}"
        log_message "⚠ Falha no download da Fira Code Nerd Font"
    fi
    
    log_message "✓ Fontes instaladas"
    echo -e "${GREEN}✓ Fontes instaladas${NC}"
    
    return 0
}

# Função de limpeza final
cleanup_system() {
    echo -e "${BLUE}🧹 Executando limpeza final...${NC}"
    log_message "=== LIMPEZA FINAL ==="
    
    # Remover pacotes órfãos
    dnf autoremove -y 2>&1 | tee -a "$LOG_FILE"
    
    # Limpar cache
    dnf clean all 2>&1 | tee -a "$LOG_FILE"
    
    # Flatpak cleanup
    flatpak uninstall --unused -y 2>/dev/null || true
    
    log_message "✓ Limpeza concluída"
    echo -e "${GREEN}✓ Sistema limpo${NC}"
    
    return 0
}

# Função para verificar se é necessário reiniciar
check_reboot() {
    if [ -f /var/run/reboot-required ] || needs-restarting -r >/dev/null 2>&1; then
        echo -e "${RED}⚠ REINICIALIZAÇÃO NECESSÁRIA${NC}"
        log_message "⚠ REINICIALIZAÇÃO NECESSÁRIA"
        return 0
    else
        echo -e "${GREEN}✓ Sistema não requer reinicialização${NC}"
        return 1
    fi
}

# Função para mostrar status do sistema
system_status() {
    echo -e "${BLUE}=== STATUS DO SISTEMA FEDORA ===${NC}"
    echo -e "${CYAN}Data/Hora:${NC} $(date)"
    echo -e "${CYAN}Uptime:${NC} $(uptime -p)"
    echo -e "${CYAN}Versão Fedora:${NC} $(cat /etc/fedora-release)"
    echo -e "${CYAN}Kernel:${NC} $(uname -r)"
    echo -e "${CYAN}Memória:${NC} $(free -h | awk '/^Mem:/ {print $3"/"$2" ("int($3/$2*100)"%)"}')"
    echo -e "${CYAN}Disco /:${NC} $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
    
    # Verificar atualizações pendentes
    PENDING=$(dnf check-update --quiet 2>/dev/null | wc -l)
    echo -e "${CYAN}Atualizações pendentes:${NC} $PENDING"
    
    # Verificar containers Docker
    if systemctl is-active docker >/dev/null 2>&1; then
        CONTAINERS=$(docker ps -q | wc -l)
        echo -e "${CYAN}Containers Docker ativos:${NC} $CONTAINERS"
        echo -e "${CYAN}Docker status:${NC} ${GREEN}Ativo${NC}"
    else
        echo -e "${CYAN}Docker status:${NC} ${RED}Inativo${NC}"
    fi
    
    # Status de reinicialização
    if check_reboot >/dev/null 2>&1; then
        echo -e "${CYAN}Status:${NC} ${RED}REINICIALIZAÇÃO NECESSÁRIA${NC}"
    else
        echo -e "${CYAN}Status:${NC} ${GREEN}OK${NC}"
    fi
}

# Função de instalação completa
full_install() {
    echo -e "${PURPLE}🚀 INICIANDO CONFIGURAÇÃO COMPLETA DO FEDORA 42+${NC}"
    echo -e "${PURPLE}=== Para Desenvolvimento Full-Stack, ML e Data Science ===${NC}"
    log_message "=== INÍCIO DA CONFIGURAÇÃO COMPLETA ==="
    
    check_root
    rotate_log
    
    # Executar todas as funções
    system_update || { echo -e "${RED}Falha na atualização do sistema${NC}"; exit 1; }
    setup_repositories || { echo -e "${RED}Falha na configuração de repositórios${NC}"; exit 1; }
    install_dev_tools || { echo -e "${RED}Falha na instalação de ferramentas de desenvolvimento${NC}"; exit 1; }
    install_multimedia || { echo -e "${RED}Falha na instalação de codecs${NC}"; exit 1; }
    install_applications || { echo -e "${RED}Falha na instalação de aplicativos${NC}"; exit 1; }
    install_fonts || { echo -e "${RED}Falha na instalação de fontes${NC}"; exit 1; }
    cleanup_system
    
    echo -e "${GREEN}✅ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
    echo ""
    echo -e "${YELLOW}📋 PRÓXIMOS PASSOS ESSENCIAIS:${NC}"
    echo -e "${CYAN}1. Reiniciar o sistema se necessário${NC}"
    echo -e "${CYAN}2. ${YELLOW}⚠ IMPORTANTE: Fazer logout/login para usar Docker sem sudo${CYAN}${NC}"
    echo -e "${CYAN}3. Testar Docker:${NC}"
    echo -e "   ${YELLOW}docker run hello-world${NC}"
    echo -e "${CYAN}4. Configurar Git:${NC}"
    echo -e "   ${YELLOW}git config --global user.name 'Seu Nome'${NC}"
    echo -e "   ${YELLOW}git config --global user.email 'seu@email.com'${NC}"
    echo ""
    echo -e "${PURPLE}🔧 FERRAMENTAS DE DESENVOLVIMENTO:${NC}"
    echo -e "${CYAN}5. Instalar NVM (Node.js):${NC}"
    echo -e "   ${YELLOW}curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash${NC}"
    echo -e "   ${YELLOW}source ~/.bashrc${NC}"
    echo -e "   ${YELLOW}nvm install --lts${NC}"
    echo -e "   ${YELLOW}nvm use --lts${NC}"
    echo ""
    echo -e "${CYAN}6. Configurar Anaconda/Miniconda (se ainda não fez):${NC}"
    echo -e "   ${YELLOW}wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh${NC}"
    echo -e "   ${YELLOW}bash Miniconda3-latest-Linux-x86_64.sh${NC}"
    echo ""
    echo -e "${CYAN}7. Instalar extensões úteis do VS Code:${NC}"
    echo -e "   ${YELLOW}code --install-extension ms-python.python${NC}"
    echo -e "   ${YELLOW}code --install-extension ms-vscode.vscode-typescript-next${NC}"
    echo -e "   ${YELLOW}code --install-extension ms-vscode-remote.remote-containers${NC}"
    echo ""
    echo -e "${PURPLE}📦 INSTALAÇÕES CONCLUÍDAS:${NC}"
    echo -e "${GREEN}✓ Docker + Docker Compose (configurado corretamente)${NC}"
    echo -e "${GREEN}✓ Git + GitHub CLI${NC}"
    echo -e "${GREEN}✓ VS Code${NC}"
    echo -e "${GREEN}✓ Flatpak com Flathub${NC}"
    echo -e "${GREEN}✓ Firefox + Chrome${NC}"
    echo -e "${GREEN}✓ Codecs multimídia (sem OpenH264 problemático)${NC}"
    echo -e "${GREEN}✓ Ferramentas de compilação C/C++${NC}"
    
    # Mostrar informações do Docker
    if systemctl is-active --quiet docker; then
        echo ""
        echo -e "${BLUE}🐳 DOCKER CONFIGURADO:${NC}"
        echo -e "${GREEN}✓ Serviço ativo e habilitado${NC}"
        if [ -n "$SUDO_USER" ]; then
            echo -e "${GREEN}✓ Usuário $SUDO_USER adicionado ao grupo docker${NC}"
        fi
        echo -e "${YELLOW}⚠ Faça logout/login para usar Docker sem sudo${NC}"
    fi
    
    check_reboot
    
    log_message "=== CONFIGURAÇÃO COMPLETA FINALIZADA ==="
}

# Função para atualização automática
auto_update() {
    echo -e "${BLUE}🔄 Executando atualização automática...${NC}"
    log_message "=== ATUALIZAÇÃO AUTOMÁTICA INICIADA ==="
    
    check_root
    rotate_log
    
    if ! check_internet; then
        exit 1
    fi
    
    # Atualizar sistema
    if dnf update -y 2>&1 | tee -a "$LOG_FILE"; then
        log_message "✓ Sistema atualizado automaticamente"
    else
        log_message "✗ Erro na atualização automática"
        exit 1
    fi
    
    # Atualizar Flatpaks
    flatpak update -y 2>&1 | tee -a "$LOG_FILE" || true
    
    # Limpeza
    dnf autoremove -y 2>&1 | tee -a "$LOG_FILE"
    dnf clean all 2>&1 | tee -a "$LOG_FILE"
    
    # Verificar se precisa reiniciar
    check_reboot
    
    log_message "=== ATUALIZAÇÃO AUTOMÁTICA CONCLUÍDA ==="
}

# Função para instalar o script no sistema
install_script() {
    echo -e "${PURPLE}📥 Instalando script no sistema...${NC}"
    check_root
    
    # Copiar script para /usr/local/bin
    cp "$0" /usr/local/bin/fedora-setup
    chmod +x /usr/local/bin/fedora-setup
    
    # Criar timer do systemd para atualizações automáticas
    cat > /etc/systemd/system/fedora-auto-update.service << EOF
[Unit]
Description=Atualização Automática do Fedora
Wants=fedora-auto-update.timer

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fedora-setup auto-update
User=root

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/fedora-auto-update.timer << EOF
[Unit]
Description=Executa atualização automática do Fedora semanalmente
Requires=fedora-auto-update.service

[Timer]
OnCalendar=weekly
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    systemctl daemon-reload
    systemctl enable fedora-auto-update.timer
    systemctl start fedora-auto-update.timer
    
    echo -e "${GREEN}✅ Script instalado com sucesso!${NC}"
    echo -e "${CYAN}Comandos disponíveis:${NC}"
    echo -e "${YELLOW}• fedora-setup install${NC}     - Configuração completa"
    echo -e "${YELLOW}• fedora-setup update${NC}      - Apenas atualização"
    echo -e "${YELLOW}• fedora-setup status${NC}      - Status do sistema"
    echo -e "${YELLOW}• fedora-setup auto-update${NC} - Atualização automática"
}

# Trap para cleanup
trap cleanup SIGINT SIGTERM

# Função principal
main() {
    case "$1" in
        "install")
            full_install
            ;;
        "update")
            check_root
            rotate_log
            system_update
            cleanup_system
            ;;
        "auto-update")
            auto_update
            ;;
        "status")
            system_status
            ;;
        "setup-script")
            install_script
            ;;
        *)
            echo -e "${PURPLE}🐧 Script de Configuração do Fedora 42+${NC}"
            echo -e "${CYAN}Para Desenvolvimento Full-Stack, ML e Data Science${NC}"
            echo ""
            echo -e "${YELLOW}Uso: $0 {install|update|auto-update|status|setup-script}${NC}"
            echo ""
            echo -e "${CYAN}Comandos:${NC}"
            echo -e "${YELLOW}  install${NC}      - Configuração completa do sistema"
            echo -e "${YELLOW}  update${NC}       - Atualizar apenas o sistema"
            echo -e "${YELLOW}  auto-update${NC}  - Atualização automática (para cron/systemd)"
            echo -e "${YELLOW}  status${NC}       - Mostrar status atual do sistema"
            echo -e "${YELLOW}  setup-script${NC} - Instalar este script no sistema"
            echo ""
            echo -e "${PURPLE}💡 Recomendação: Execute 'sudo $0 install' após formatação${NC}"
            echo -e "${PURPLE}🚀 NVM: Instale manualmente para gerenciar Node.js${NC}"
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"

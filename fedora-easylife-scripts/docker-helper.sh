#!/bin/bash

# Docker Helper - Interactive Docker Management
# Gerencia containers, compose e desenvolvimento via menu
# Usage: ./docker-helper.sh ou docker-help (se instalado)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verificar se Docker está disponível
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker não encontrado${NC}"
        exit 1
    fi
    
    if ! docker ps >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker não está rodando ou sem permissão${NC}"
        echo -e "${CYAN}💡 Execute 'sudo systemctl start docker' ou faça logout/login${NC}"
        exit 1
    fi
}

# Header
show_header() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    🐳 DOCKER HELPER                          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Docker info
    local running_containers=$(docker ps -q | wc -l)
    local total_containers=$(docker ps -a -q | wc -l)
    local images_count=$(docker images -q | wc -l)
    
    echo -e "${CYAN}🐳 Containers ativos: ${YELLOW}$running_containers${NC}"
    echo -e "${CYAN}📦 Total containers: ${YELLOW}$total_containers${NC}"
    echo -e "${CYAN}🖼️  Images: ${YELLOW}$images_count${NC}"
    echo ""
}

# Menu principal
show_main_menu() {
    echo -e "${BLUE}═══════════════════ MENU PRINCIPAL ═══════════════════${NC}"
    echo -e "${YELLOW}1.${NC}  📊 Status & Info"
    echo -e "${YELLOW}2.${NC}  🚀 Dev Environments (Node/Python/DS)"
    echo -e "${YELLOW}3.${NC}  📦 Containers"
    echo -e "${YELLOW}4.${NC}  🖼️  Images"
    echo -e "${YELLOW}5.${NC}  📋 Docker Compose"
    echo -e "${YELLOW}6.${NC}  🌐 Networks"
    echo -e "${YELLOW}7.${NC}  💾 Volumes"
    echo -e "${YELLOW}8.${NC}  🧹 Cleanup"
    echo -e "${YELLOW}9.${NC}  📜 Logs"
    echo -e "${YELLOW}0.${NC}  ❌ Sair"
    echo ""
    echo -ne "${PURPLE}Escolha uma opção [0-9]: ${NC}"
}

# 1. Status & Info
status_info() {
    clear
    echo -e "${BLUE}📊 DOCKER STATUS & INFORMAÇÕES${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo ""
    
    echo -e "${CYAN}🐳 Docker Version:${NC}"
    docker version --format "table {{.Server.Version}}\t{{.Server.Os}}/{{.Server.Arch}}"
    echo ""
    
    echo -e "${CYAN}📊 System Info:${NC}"
    docker system df
    echo ""
    
    echo -e "${CYAN}🔥 Containers ativos:${NC}"
    if [ $(docker ps -q | wc -l) -eq 0 ]; then
        echo -e "${YELLOW}Nenhum container ativo${NC}"
    else
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    fi
    echo ""
    
    echo -e "${CYAN}⚡ Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || echo "Nenhum container ativo"
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 2. Dev Environments
dev_environments() {
    clear
    echo -e "${BLUE}🚀 AMBIENTES DE DESENVOLVIMENTO${NC}"
    echo -e "${BLUE}===============================${NC}"
    echo ""
    
    # Check workspace
    if [ ! -d "$HOME/docker-workspace" ]; then
        echo -e "${RED}❌ Docker workspace não encontrado${NC}"
        echo -e "${CYAN}💡 Execute fedora-post-install.sh primeiro${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    # Status dos ambientes
    echo -e "${CYAN}📊 Status dos ambientes:${NC}"
    cd "$HOME/docker-workspace/compose-files"
    
    local envs=("nodejs-dev" "python-web" "datascience")
    for env in "${envs[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "$env"; then
            echo -e "${GREEN}✅ $env - ATIVO${NC}"
        else
            echo -e "${YELLOW}⏸️  $env - PARADO${NC}"
        fi
    done
    echo ""
    
    echo -e "${YELLOW}1.${NC} 🟢 Iniciar Node.js Dev"
    echo -e "${YELLOW}2.${NC} 🐍 Iniciar Python Web"
    echo -e "${YELLOW}3.${NC} 🔬 Iniciar Data Science"
    echo -e "${YELLOW}4.${NC} ⏹️  Parar ambiente específico"
    echo -e "${YELLOW}5.${NC} 🛑 Parar todos os ambientes"
    echo -e "${YELLOW}6.${NC} 🔄 Restart ambiente"
    echo -e "${YELLOW}7.${NC} 💻 Acessar shell do container"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-7]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}🚀 Iniciando Node.js environment...${NC}"
            docker-compose -f nodejs-dev.yml up -d
            echo -e "${GREEN}✅ Node.js ativo em ports 3000, 5173, 8080${NC}"
            ;;
        2)
            echo -e "${CYAN}🐍 Iniciando Python Web environment...${NC}"
            docker-compose -f python-web.yml up -d
            echo -e "${GREEN}✅ Python Web ativo - FastAPI:8000, Flask:5000, Streamlit:8501${NC}"
            echo -e "${CYAN}🗄️ PostgreSQL: localhost:5432 (dev/devpass/devdb)${NC}"
            ;;
        3)
            echo -e "${CYAN}🔬 Iniciando Data Science environment...${NC}"
            # Check GPU
            if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
                echo -e "${GREEN}🚀 GPU NVIDIA detectada - usando imagem GPU${NC}"
                sed -i 's/jupyter\/tensorflow-notebook:latest/tensorflow\/tensorflow:latest-gpu-jupyter/' datascience.yml
            fi
            docker-compose -f datascience.yml up -d
            echo -e "${GREEN}✅ Data Science ativo${NC}"
            echo -e "${CYAN}📊 Jupyter Lab: http://localhost:8888 (token: dev123)${NC}"
            echo -e "${CYAN}🧪 MLflow: http://localhost:5555${NC}"
            ;;
        4)
            echo -e "${CYAN}Qual ambiente parar? (nodejs-dev/python-web/datascience):${NC}"
            read env_name
            docker-compose -f "${env_name}.yml" down 2>/dev/null || echo -e "${RED}Ambiente não encontrado${NC}"
            ;;
        5)
            echo -e "${CYAN}⏹️ Parando todos os ambientes...${NC}"
            docker-compose -f nodejs-dev.yml down 2>/dev/null
            docker-compose -f python-web.yml down 2>/dev/null
            docker-compose -f datascience.yml down 2>/dev/null
            echo -e "${GREEN}✅ Todos os ambientes parados${NC}"
            ;;
        6)
            echo -e "${CYAN}Qual ambiente reiniciar? (nodejs-dev/python-web/datascience):${NC}"
            read env_name
            docker-compose -f "${env_name}.yml" restart 2>/dev/null || echo -e "${RED}Ambiente não encontrado${NC}"
            ;;
        7)
            echo -e "${CYAN}Containers disponíveis:${NC}"
            docker ps --format "{{.Names}}"
            echo ""
            echo -e "${CYAN}Nome do container:${NC}"
            read container_name
            echo -e "${CYAN}Shell (bash/sh/zsh) [bash]:${NC}"
            read shell_type
            shell_type=${shell_type:-bash}
            docker exec -it "$container_name" "$shell_type"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 3. Containers
manage_containers() {
    clear
    echo -e "${BLUE}📦 GERENCIAMENTO DE CONTAINERS${NC}"
    echo -e "${BLUE}=============================${NC}"
    echo ""
    
    echo -e "${CYAN}📋 Containers:${NC}"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} ▶️  Start container"
    echo -e "${YELLOW}2.${NC} ⏹️  Stop container"
    echo -e "${YELLOW}3.${NC} 🔄 Restart container"
    echo -e "${YELLOW}4.${NC} 🗑️  Remove container"
    echo -e "${YELLOW}5.${NC} 💻 Exec shell no container"
    echo -e "${YELLOW}6.${NC} 📊 Stats em tempo real"
    echo -e "${YELLOW}7.${NC} 🔍 Inspect container"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-7]: ${NC}"
    
    read choice
    case $choice in
        1|2|3|4)
            echo -e "${CYAN}Nome do container:${NC}"
            read container_name
            case $choice in
                1) docker start "$container_name" ;;
                2) docker stop "$container_name" ;;
                3) docker restart "$container_name" ;;
                4) 
                    echo -e "${YELLOW}⚠️ Confirma remoção? (y/N):${NC}"
                    read -n 1 confirm
                    echo
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        docker rm "$container_name"
                    fi
                    ;;
            esac
            ;;
        5)
            echo -e "${CYAN}Nome do container:${NC}"
            read container_name
            echo -e "${CYAN}Comando [/bin/bash]:${NC}"
            read cmd
            cmd=${cmd:-/bin/bash}
            docker exec -it "$container_name" "$cmd"
            ;;
        6)
            docker stats
            ;;
        7)
            echo -e "${CYAN}Nome do container:${NC}"
            read container_name
            docker inspect "$container_name" | less
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 4. Images
manage_images() {
    clear
    echo -e "${BLUE}🖼️  GERENCIAMENTO DE IMAGES${NC}"
    echo -e "${BLUE}==========================${NC}"
    echo ""
    
    echo -e "${CYAN}📋 Images:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 📥 Pull image"
    echo -e "${YELLOW}2.${NC} 🗑️  Remove image"
    echo -e "${YELLOW}3.${NC} 🧹 Remove unused images"
    echo -e "${YELLOW}4.${NC} 🔍 Inspect image"
    echo -e "${YELLOW}5.${NC} 📊 Image history"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Nome da image (ex: node:18-alpine):${NC}"
            read image_name
            docker pull "$image_name"
            ;;
        2)
            echo -e "${CYAN}Nome da image para remover:${NC}"
            read image_name
            echo -e "${YELLOW}⚠️ Confirma remoção? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                docker rmi "$image_name"
            fi
            ;;
        3)
            echo -e "${CYAN}🧹 Removendo images não utilizadas...${NC}"
            docker image prune -f
            ;;
        4)
            echo -e "${CYAN}Nome da image:${NC}"
            read image_name
            docker inspect "$image_name" | less
            ;;
        5)
            echo -e "${CYAN}Nome da image:${NC}"
            read image_name
            docker history "$image_name"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 5. Docker Compose
manage_compose() {
    clear
    echo -e "${BLUE}📋 DOCKER COMPOSE${NC}"
    echo -e "${BLUE}=================${NC}"
    echo ""
    
    if [ ! -f "docker-compose.yml" ] && [ ! -f "compose.yml" ]; then
        echo -e "${YELLOW}⚠️ Nenhum docker-compose.yml encontrado no diretório atual${NC}"
        echo -e "${CYAN}Diretório atual: $(pwd)${NC}"
        echo ""
        echo -e "${CYAN}Navegar para docker-workspace? (y/N):${NC}"
        read -n 1 navigate
        echo
        if [[ $navigate =~ ^[Yy]$ ]]; then
            cd "$HOME/docker-workspace/compose-files" 2>/dev/null || echo -e "${RED}Docker workspace não encontrado${NC}"
        fi
    fi
    
    echo -e "${YELLOW}1.${NC} 🚀 Up (start services)"
    echo -e "${YELLOW}2.${NC} ⏹️  Down (stop and remove)"
    echo -e "${YELLOW}3.${NC} 🔄 Restart services"
    echo -e "${YELLOW}4.${NC} 📊 Status (ps)"
    echo -e "${YELLOW}5.${NC} 📜 Logs"
    echo -e "${YELLOW}6.${NC} 🧹 Down + remove volumes"
    echo -e "${YELLOW}7.${NC} 📋 Escolher arquivo compose"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-7]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}🚀 Docker Compose Up...${NC}"
            docker-compose up -d
            ;;
        2)
            echo -e "${CYAN}⏹️ Docker Compose Down...${NC}"
            docker-compose down
            ;;
        3)
            echo -e "${CYAN}🔄 Docker Compose Restart...${NC}"
            docker-compose restart
            ;;
        4)
            docker-compose ps
            ;;
        5)
            echo -e "${CYAN}Serviço específico ou todos? [all]:${NC}"
            read service_name
            if [ -z "$service_name" ] || [ "$service_name" = "all" ]; then
                docker-compose logs -f
            else
                docker-compose logs -f "$service_name"
            fi
            ;;
        6)
            echo -e "${YELLOW}⚠️ Isso removerá volumes! Confirma? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                docker-compose down -v
            fi
            ;;
        7)
            echo -e "${CYAN}Arquivos compose disponíveis:${NC}"
            ls -1 *.yml 2>/dev/null || echo "Nenhum arquivo .yml encontrado"
            echo ""
            echo -e "${CYAN}Nome do arquivo:${NC}"
            read compose_file
            if [ -f "$compose_file" ]; then
                export COMPOSE_FILE="$compose_file"
                echo -e "${GREEN}✅ Usando $compose_file${NC}"
            else
                echo -e "${RED}❌ Arquivo não encontrado${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 6. Networks
manage_networks() {
    clear
    echo -e "${BLUE}🌐 GERENCIAMENTO DE NETWORKS${NC}"
    echo -e "${BLUE}===========================${NC}"
    echo ""
    
    echo -e "${CYAN}📋 Networks:${NC}"
    docker network ls
    echo ""
    
    echo -e "${YELLOW}1.${NC} 🌐 Create network"
    echo -e "${YELLOW}2.${NC} 🗑️  Remove network"
    echo -e "${YELLOW}3.${NC} 🔍 Inspect network"
    echo -e "${YELLOW}4.${NC} 🧹 Prune unused networks"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-4]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Nome da network:${NC}"
            read network_name
            docker network create "$network_name"
            ;;
        2)
            echo -e "${CYAN}Nome da network para remover:${NC}"
            read network_name
            docker network rm "$network_name"
            ;;
        3)
            echo -e "${CYAN}Nome da network:${NC}"
            read network_name
            docker network inspect "$network_name"
            ;;
        4)
            docker network prune -f
            echo -e "${GREEN}✅ Networks não utilizadas removidas${NC}"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 7. Volumes
manage_volumes() {
    clear
    echo -e "${BLUE}💾 GERENCIAMENTO DE VOLUMES${NC}"
    echo -e "${BLUE}==========================${NC}"
    echo ""
    
    echo -e "${CYAN}📋 Volumes:${NC}"
    docker volume ls
    echo ""
    
    echo -e "${YELLOW}1.${NC} 💾 Create volume"
    echo -e "${YELLOW}2.${NC} 🗑️  Remove volume"
    echo -e "${YELLOW}3.${NC} 🔍 Inspect volume"
    echo -e "${YELLOW}4.${NC} 🧹 Prune unused volumes"
    echo -e "${YELLOW}5.${NC} 📊 Volume usage"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Nome do volume:${NC}"
            read volume_name
            docker volume create "$volume_name"
            ;;
        2)
            echo -e "${CYAN}Nome do volume para remover:${NC}"
            read volume_name
            echo -e "${YELLOW}⚠️ Confirma remoção? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                docker volume rm "$volume_name"
            fi
            ;;
        3)
            echo -e "${CYAN}Nome do volume:${NC}"
            read volume_name
            docker volume inspect "$volume_name"
            ;;
        4)
            echo -e "${YELLOW}⚠️ Remover volumes não utilizados? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                docker volume prune -f
            fi
            ;;
        5)
            docker system df -v
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 8. Cleanup
cleanup_docker() {
    clear
    echo -e "${BLUE}🧹 LIMPEZA DO DOCKER${NC}"
    echo -e "${BLUE}===================${NC}"
    echo ""
    
    echo -e "${CYAN}📊 Uso atual do disco:${NC}"
    docker system df
    echo ""
    
    echo -e "${YELLOW}1.${NC} 🧹 Cleanup básico (containers parados, networks, images sem tag)"
    echo -e "${YELLOW}2.${NC} 💣 Cleanup completo (CUIDADO: remove tudo não utilizado)"
    echo -e "${YELLOW}3.${NC} 🗑️  Remove containers parados"
    echo -e "${YELLOW}4.${NC} 🖼️  Remove images sem tag"
    echo -e "${YELLOW}5.${NC} 📊 Verificar uso do disco"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}🧹 Executando cleanup básico...${NC}"
            docker system prune -f
            echo -e "${GREEN}✅ Cleanup básico concluído${NC}"
            ;;
        2)
            echo -e "${RED}⚠️ ATENÇÃO: Isso removerá TUDO não utilizado (containers, images, volumes, networks)${NC}"
            echo -e "${YELLOW}Continuar? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                docker system prune -a -f --volumes
                echo -e "${GREEN}✅ Cleanup completo concluído${NC}"
            fi
            ;;
        3)
            docker container prune -f
            echo -e "${GREEN}✅ Containers parados removidos${NC}"
            ;;
        4)
            docker image prune -f
            echo -e "${GREEN}✅ Images sem tag removidas${NC}"
            ;;
        5)
            docker system df -v
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 9. Logs
view_logs() {
    clear
    echo -e "${BLUE}📜 VISUALIZAÇÃO DE LOGS${NC}"
    echo -e "${BLUE}======================${NC}"
    echo ""
    
    if [ $(docker ps -q | wc -l) -eq 0 ]; then
        echo -e "${YELLOW}⚠️ Nenhum container ativo${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    echo -e "${CYAN}📋 Containers ativos:${NC}"
    docker ps --format "{{.Names}}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 📜 Logs de container específico"
    echo -e "${YELLOW}2.${NC} 🔄 Logs em tempo real (follow)"
    echo -e "${YELLOW}3.${NC} 📊 Logs com timestamp"
    echo -e "${YELLOW}4.${NC} 📋 Logs do docker-compose"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-4]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Nome do container:${NC}"
            read container_name
            echo -e "${CYAN}Número de linhas [100]:${NC}"
            read lines
            lines=${lines:-100}
            docker logs --tail "$lines" "$container_name"
            ;;
        2)
            echo -e "${CYAN}Nome do container:${NC}"
            read container_name
            docker logs -f "$container_name"
            ;;
        3)
            echo -e "${CYAN}Nome do container:${NC}"
            read container_name
            docker logs -t "$container_name"
            ;;
        4)
            if [ -f "docker-compose.yml" ] || [ -f "compose.yml" ]; then
                docker-compose logs -f
            else
                echo -e "${RED}❌ Nenhum docker-compose.yml encontrado${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Loop principal
main() {
    check_docker
    
    while true; do
        show_header
        show_main_menu
        
        read choice
        case $choice in
            1) status_info ;;
            2) dev_environments ;;
            3) manage_containers ;;
            4) manage_images ;;
            5) manage_compose ;;
            6) manage_networks ;;
            7) manage_volumes ;;
            8) cleanup_docker ;;
            9) view_logs ;;
            0) 
                echo -e "${GREEN}🐳 Até mais!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opção inválida. Pressione Enter...${NC}"
                read
                ;;
        esac
    done
}

# Executar
main
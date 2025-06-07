#!/bin/bash

# Dev Switcher - Quick Project Navigation & Environment Management
# Troca rapidamente entre projetos e gerencia ambientes
# Usage: ./dev-switcher.sh ou dev-switch (se instalado)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

WORKSPACE_DIR="$HOME/docker-workspace"
STATE_FILE="$HOME/.dev-switcher-state"

# Verificar workspace
check_workspace() {
    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo -e "${RED}❌ Docker workspace não encontrado${NC}"
        echo -e "${CYAN}💡 Execute fedora-post-install.sh primeiro${NC}"
        exit 1
    fi
}

# Salvar estado atual
save_state() {
    local project_path="$1"
    local project_type="$2"
    echo "LAST_PROJECT=$project_path" > "$STATE_FILE"
    echo "LAST_TYPE=$project_type" >> "$STATE_FILE"
    echo "LAST_ACCESS=$(date)" >> "$STATE_FILE"
}

# Carregar estado
load_state() {
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
    fi
}

# Header
show_header() {
    clear
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    🔄 DEV SWITCHER                           ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    load_state
    if [ -n "$LAST_PROJECT" ]; then
        echo -e "${CYAN}📂 Último projeto: ${YELLOW}$(basename "$LAST_PROJECT")${NC}"
        echo -e "${CYAN}🏷️  Tipo: ${YELLOW}$LAST_TYPE${NC}"
        echo -e "${CYAN}🕒 Último acesso: ${YELLOW}$LAST_ACCESS${NC}"
    else
        echo -e "${CYAN}📂 Primeiro uso - nenhum projeto anterior${NC}"
    fi
    echo ""
}

# Listar projetos por tipo
list_projects() {
    local base_dir="$1"
    local type_name="$2"
    
    if [ ! -d "$base_dir" ]; then
        return
    fi
    
    local projects=($(find "$base_dir" -maxdepth 1 -type d ! -path "$base_dir" 2>/dev/null | sort))
    
    if [ ${#projects[@]} -eq 0 ]; then
        return
    fi
    
    echo -e "${BLUE}📁 $type_name:${NC}"
    local count=1
    for project in "${projects[@]}"; do
        local project_name=$(basename "$project")
        local last_modified=$(stat -c %y "$project" 2>/dev/null | cut -d' ' -f1)
        
        # Verificar se tem git
        local git_status=""
        if [ -d "$project/.git" ]; then
            cd "$project"
            local branch=$(git branch --show-current 2>/dev/null)
            local changes=$(git status --porcelain 2>/dev/null | wc -l)
            if [ $changes -gt 0 ]; then
                git_status=" ${RED}($changes changes)${NC}"
            else
                git_status=" ${GREEN}(clean)${NC}"
            fi
            if [ -n "$branch" ]; then
                git_status=" ${CYAN}[$branch]${NC}$git_status"
            fi
        fi
        
        echo -e "  ${YELLOW}$count.${NC} $project_name ${CYAN}($last_modified)${NC}$git_status"
        ((count++))
    done
    echo ""
}

# Menu principal
show_main_menu() {
    echo -e "${BLUE}═══════════════════ PROJETOS DISPONÍVEIS ═══════════════════${NC}"
    
    list_projects "$WORKSPACE_DIR/nodejs" "Node.js/React/Vue"
    list_projects "$WORKSPACE_DIR/python-web" "Python Web"
    list_projects "$WORKSPACE_DIR/datascience" "Data Science"
    list_projects "$WORKSPACE_DIR/projects" "Projetos Gerais"
    
    echo -e "${BLUE}═══════════════════ AÇÕES RÁPIDAS ═══════════════════${NC}"
    echo -e "${YELLOW}q.${NC} 🔍 Quick switch (buscar projeto)"
    echo -e "${YELLOW}l.${NC} 📋 Listar todos os projetos"
    echo -e "${YELLOW}r.${NC} 🔄 Reabrir último projeto"
    echo -e "${YELLOW}s.${NC} 📊 Status dos ambientes Docker"
    echo -e "${YELLOW}e.${NC} ⚙️  Gerenciar ambientes"
    echo -e "${YELLOW}c.${NC} 🆕 Criar novo projeto"
    echo -e "${YELLOW}0.${NC} ❌ Sair"
    echo ""
    echo -ne "${PURPLE}Escolha projeto ou ação: ${NC}"
}

# Busca rápida de projeto
quick_search() {
    echo -e "${CYAN}🔍 Buscar projeto (digite parte do nome):${NC}"
    read -e search_term
    
    if [ -z "$search_term" ]; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}📁 Resultados para '$search_term':${NC}"
    
    local found_projects=()
    local base_dirs=("$WORKSPACE_DIR/nodejs" "$WORKSPACE_DIR/python-web" "$WORKSPACE_DIR/datascience" "$WORKSPACE_DIR/projects")
    
    for base_dir in "${base_dirs[@]}"; do
        if [ -d "$base_dir" ]; then
            while IFS= read -r -d '' project; do
                local project_name=$(basename "$project")
                if [[ "$project_name" == *"$search_term"* ]]; then
                    found_projects+=("$project")
                fi
            done < <(find "$base_dir" -maxdepth 1 -type d ! -path "$base_dir" -print0 2>/dev/null)
        fi
    done
    
    if [ ${#found_projects[@]} -eq 0 ]; then
        echo -e "${YELLOW}Nenhum projeto encontrado${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    local count=1
    for project in "${found_projects[@]}"; do
        local project_name=$(basename "$project")
        local project_type=$(basename "$(dirname "$project")")
        echo -e "  ${YELLOW}$count.${NC} $project_name ${CYAN}($project_type)${NC}"
        ((count++))
    done
    
    echo ""
    echo -ne "${PURPLE}Escolha projeto [1-${#found_projects[@]}]: ${NC}"
    read choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#found_projects[@]} ]; then
        local selected_project="${found_projects[$((choice-1))]}"
        open_project "$selected_project"
    fi
}

# Abrir projeto
open_project() {
    local project_path="$1"
    local project_name=$(basename "$project_path")
    local project_type=$(basename "$(dirname "$project_path")")
    
    echo -e "${CYAN}📂 Abrindo projeto: ${YELLOW}$project_name${NC}"
    echo -e "${CYAN}📁 Tipo: ${YELLOW}$project_type${NC}"
    echo -e "${CYAN}📍 Caminho: ${YELLOW}$project_path${NC}"
    echo ""
    
    # Salvar estado
    save_state "$project_path" "$project_type"
    
    # Verificar se tem VS Code instalado
    if command -v code >/dev/null 2>&1; then
        echo -e "${YELLOW}1.${NC} 💻 Abrir no VS Code"
    fi
    echo -e "${YELLOW}2.${NC} 📁 Abrir terminal no projeto"
    echo -e "${YELLOW}3.${NC} 🚀 Iniciar ambiente Docker (se aplicável)"
    echo -e "${YELLOW}4.${NC} 📊 Mostrar informações do projeto"
    echo -e "${YELLOW}5.${NC} 🌐 Abrir no navegador (se web project)"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha ação [0-5]: ${NC}"
    
    read action
    case $action in
        1)
            if command -v code >/dev/null 2>&1; then
                echo -e "${CYAN}🚀 Abrindo no VS Code...${NC}"
                code "$project_path"
            else
                echo -e "${RED}❌ VS Code não encontrado${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}📁 Abrindo terminal...${NC}"
            cd "$project_path"
            exec bash
            ;;
        3)
            start_project_environment "$project_path" "$project_type"
            ;;
        4)
            show_project_info "$project_path"
            ;;
        5)
            open_in_browser "$project_path" "$project_type"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}❌ Opção inválida${NC}"
            read -p "Pressione Enter..."
            ;;
    esac
}

# Iniciar ambiente do projeto
start_project_environment() {
    local project_path="$1"
    local project_type="$2"
    
    echo -e "${CYAN}🚀 Iniciando ambiente para projeto...${NC}"
    
    cd "$WORKSPACE_DIR/compose-files"
    
    case $project_type in
        "nodejs")
            echo -e "${CYAN}🟢 Iniciando ambiente Node.js...${NC}"
            docker-compose -f nodejs-dev.yml up -d
            echo -e "${GREEN}✅ Ambiente Node.js ativo!${NC}"
            echo -e "${CYAN}🌐 Portas: 3000, 5173, 8080${NC}"
            ;;
        "python-web")
            echo -e "${CYAN}🐍 Iniciando ambiente Python Web...${NC}"
            docker-compose -f python-web.yml up -d
            echo -e "${GREEN}✅ Ambiente Python ativo!${NC}"
            echo -e "${CYAN}🌐 FastAPI: 8000, Flask: 5000, Streamlit: 8501${NC}"
            ;;
        "datascience")
            echo -e "${CYAN}🔬 Iniciando ambiente Data Science...${NC}"
            # Check GPU
            if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
                echo -e "${GREEN}🚀 GPU detectada!${NC}"
            fi
            docker-compose -f datascience.yml up -d
            echo -e "${GREEN}✅ Ambiente Data Science ativo!${NC}"
            echo -e "${CYAN}📊 Jupyter: http://localhost:8888 (token: dev123)${NC}"
            echo -e "${CYAN}🧪 MLflow: http://localhost:5555${NC}"
            ;;
        "projects")
            echo -e "${CYAN}🌐 Verificando docker-compose no projeto...${NC}"
            if [ -f "$project_path/docker-compose.yml" ]; then
                cd "$project_path"
                docker-compose up -d
                echo -e "${GREEN}✅ Ambiente do projeto ativo!${NC}"
            else
                echo -e "${YELLOW}⚠️ Nenhum docker-compose.yml encontrado${NC}"
                echo -e "${CYAN}💡 Use um dos ambientes padrão (Node.js, Python, Data Science)${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠️ Tipo de projeto não reconhecido para ambiente Docker${NC}"
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

# Mostrar informações do projeto
show_project_info() {
    local project_path="$1"
    local project_name=$(basename "$project_path")
    
    clear
    echo -e "${BLUE}📊 INFORMAÇÕES DO PROJETO${NC}"
    echo -e "${BLUE}=========================${NC}"
    echo ""
    echo -e "${CYAN}📂 Nome: ${YELLOW}$project_name${NC}"
    echo -e "${CYAN}📍 Caminho: ${YELLOW}$project_path${NC}"
    echo -e "${CYAN}📅 Criado: ${YELLOW}$(stat -c %w "$project_path" 2>/dev/null || echo 'N/A')${NC}"
    echo -e "${CYAN}📅 Modificado: ${YELLOW}$(stat -c %y "$project_path" 2>/dev/null | cut -d' ' -f1)${NC}"
    echo -e "${CYAN}📏 Tamanho: ${YELLOW}$(du -sh "$project_path" 2>/dev/null | cut -f1)${NC}"
    
    # Git info
    if [ -d "$project_path/.git" ]; then
        cd "$project_path"
        echo ""
        echo -e "${BLUE}🌿 Git Information:${NC}"
        echo -e "${CYAN}Branch: ${YELLOW}$(git branch --show-current 2>/dev/null)${NC}"
        echo -e "${CYAN}Remote: ${YELLOW}$(git remote get-url origin 2>/dev/null || echo 'N/A')${NC}"
        echo -e "${CYAN}Último commit: ${YELLOW}$(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null)${NC}"
        local changes=$(git status --porcelain 2>/dev/null | wc -l)
        if [ $changes -gt 0 ]; then
            echo -e "${CYAN}Mudanças: ${RED}$changes arquivos modificados${NC}"
        else
            echo -e "${CYAN}Status: ${GREEN}Limpo${NC}"
        fi
    fi
    
    # Package.json info (Node.js projects)
    if [ -f "$project_path/package.json" ]; then
        echo ""
        echo -e "${BLUE}📦 Node.js Information:${NC}"
        if command -v jq >/dev/null 2>&1; then
            local pkg_name=$(jq -r '.name // "N/A"' "$project_path/package.json")
            local pkg_version=$(jq -r '.version // "N/A"' "$project_path/package.json")
            echo -e "${CYAN}Package: ${YELLOW}$pkg_name@$pkg_version${NC}"
            echo -e "${CYAN}Scripts: ${YELLOW}$(jq -r '.scripts | keys | join(", ")' "$project_path/package.json" 2>/dev/null)${NC}"
        else
            echo -e "${CYAN}package.json encontrado${NC}"
        fi
    fi
    
    # Requirements.txt info (Python projects)
    if [ -f "$project_path/requirements.txt" ]; then
        echo ""
        echo -e "${BLUE}🐍 Python Information:${NC}"
        local req_count=$(wc -l < "$project_path/requirements.txt")
        echo -e "${CYAN}Requirements: ${YELLOW}$req_count pacotes${NC}"
    fi
    
    # Docker info
    if [ -f "$project_path/docker-compose.yml" ]; then
        echo ""
        echo -e "${BLUE}🐳 Docker Information:${NC}"
        echo -e "${CYAN}docker-compose.yml encontrado${NC}"
    fi
    
    if [ -f "$project_path/Dockerfile" ]; then
        echo -e "${CYAN}Dockerfile encontrado${NC}"
    fi
    
    # README info
    if [ -f "$project_path/README.md" ]; then
        echo ""
        echo -e "${BLUE}📖 README Preview:${NC}"
        head -5 "$project_path/README.md" | sed 's/^/  /'
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Abrir no navegador
open_in_browser() {
    local project_path="$1"
    local project_type="$2"
    
    local urls=()
    
    case $project_type in
        "nodejs")
            urls+=("http://localhost:3000" "http://localhost:5173")
            ;;
        "python-web")
            urls+=("http://localhost:8000/docs" "http://localhost:5000" "http://localhost:8501")
            ;;
        "datascience")
            urls+=("http://localhost:8888" "http://localhost:5555")
            ;;
        "projects")
            urls+=("http://localhost:3000" "http://localhost:8000/docs")
            ;;
    esac
    
    if [ ${#urls[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ Nenhuma URL padrão para este tipo de projeto${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    echo -e "${CYAN}🌐 URLs disponíveis:${NC}"
    local count=1
    for url in "${urls[@]}"; do
        echo -e "  ${YELLOW}$count.${NC} $url"
        ((count++))
    done
    
    echo ""
    echo -ne "${PURPLE}Escolha URL [1-${#urls[@]}]: ${NC}"
    read choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#urls[@]} ]; then
        local selected_url="${urls[$((choice-1))]}"
        echo -e "${CYAN}🚀 Abrindo $selected_url...${NC}"
        
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$selected_url"
        elif command -v firefox >/dev/null 2>&1; then
            firefox "$selected_url" &
        else
            echo -e "${YELLOW}⚠️ Não foi possível abrir automaticamente${NC}"
            echo -e "${CYAN}URL: $selected_url${NC}"
        fi
    fi
    
    read -p "Pressione Enter..."
}

# Status dos ambientes
show_environment_status() {
    clear
    echo -e "${BLUE}📊 STATUS DOS AMBIENTES DOCKER${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo ""
    
    # Containers ativos
    local running_containers=$(docker ps -q | wc -l)
    echo -e "${CYAN}🐳 Containers ativos: ${YELLOW}$running_containers${NC}"
    
    if [ $running_containers -gt 0 ]; then
        echo ""
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    fi
    
    echo ""
    echo -e "${CYAN}🌐 Serviços Web ativos:${NC}"
    
    # Check services
    local services=()
    if docker ps --format "{{.Names}}" | grep -q "nodejs-dev"; then
        services+=("Node.js: http://localhost:3000, http://localhost:5173")
    fi
    if docker ps --format "{{.Names}}" | grep -q "python-web"; then
        services+=("Python: http://localhost:8000/docs, http://localhost:5000")
    fi
    if docker ps --format "{{.Names}}" | grep -q "jupyter-lab"; then
        services+=("Jupyter: http://localhost:8888 (token: dev123)")
    fi
    if docker ps --format "{{.Names}}" | grep -q "mlflow-server"; then
        services+=("MLflow: http://localhost:5555")
    fi
    
    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${YELLOW}  Nenhum serviço web ativo${NC}"
    else
        for service in "${services[@]}"; do
            echo -e "  ${GREEN}✓${NC} $service"
        done
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Gerenciar ambientes
manage_environments() {
    clear
    echo -e "${BLUE}⚙️ GERENCIAR AMBIENTES${NC}"
    echo -e "${BLUE}===================${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 🟢 Iniciar Node.js"
    echo -e "${YELLOW}2.${NC} 🐍 Iniciar Python Web"
    echo -e "${YELLOW}3.${NC} 🔬 Iniciar Data Science"
    echo -e "${YELLOW}4.${NC} ⏹️  Parar ambiente específico"
    echo -e "${YELLOW}5.${NC} 🛑 Parar todos"
    echo -e "${YELLOW}6.${NC} 🔄 Restart ambiente"
    echo -e "${YELLOW}7.${NC} 🧹 Cleanup Docker"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-7]: ${NC}"
    
    read choice
    
    cd "$WORKSPACE_DIR/compose-files"
    
    case $choice in
        1)
            echo -e "${CYAN}🚀 Iniciando Node.js...${NC}"
            docker-compose -f nodejs-dev.yml up -d
            ;;
        2)
            echo -e "${CYAN}🚀 Iniciando Python Web...${NC}"
            docker-compose -f python-web.yml up -d
            ;;
        3)
            echo -e "${CYAN}🚀 Iniciando Data Science...${NC}"
            docker-compose -f datascience.yml up -d
            ;;
        4)
            echo -e "${CYAN}Ambientes: nodejs-dev, python-web, datascience${NC}"
            echo -ne "${PURPLE}Nome do ambiente: ${NC}"
            read env_name
            docker-compose -f "${env_name}.yml" down 2>/dev/null
            ;;
        5)
            echo -e "${CYAN}⏹️ Parando todos...${NC}"
            docker-compose -f nodejs-dev.yml down 2>/dev/null
            docker-compose -f python-web.yml down 2>/dev/null
            docker-compose -f datascience.yml down 2>/dev/null
            ;;
        6)
            echo -e "${CYAN}Ambientes: nodejs-dev, python-web, datascience${NC}"
            echo -ne "${PURPLE}Nome do ambiente: ${NC}"
            read env_name
            docker-compose -f "${env_name}.yml" restart 2>/dev/null
            ;;
        7)
            echo -e "${YELLOW}⚠️ Cleanup Docker (remove unused)? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                docker system prune -f
                echo -e "${GREEN}✅ Cleanup concluído${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter..."
}

# Reabrir último projeto
reopen_last_project() {
    load_state
    
    if [ -z "$LAST_PROJECT" ] || [ ! -d "$LAST_PROJECT" ]; then
        echo -e "${YELLOW}⚠️ Nenhum projeto anterior ou projeto não existe mais${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    echo -e "${CYAN}🔄 Reabrindo último projeto...${NC}"
    open_project "$LAST_PROJECT"
}

# Listar todos os projetos
list_all_projects() {
    clear
    echo -e "${BLUE}📋 TODOS OS PROJETOS${NC}"
    echo -e "${BLUE}===================${NC}"
    echo ""
    
    local all_projects=()
    local base_dirs=("$WORKSPACE_DIR/nodejs" "$WORKSPACE_DIR/python-web" "$WORKSPACE_DIR/datascience" "$WORKSPACE_DIR/projects")
    
    for base_dir in "${base_dirs[@]}"; do
        if [ -d "$base_dir" ]; then
            while IFS= read -r -d '' project; do
                all_projects+=("$project")
            done < <(find "$base_dir" -maxdepth 1 -type d ! -path "$base_dir" -print0 2>/dev/null)
        fi
    done
    
    if [ ${#all_projects[@]} -eq 0 ]; then
        echo -e "${YELLOW}📁 Nenhum projeto encontrado${NC}"
        echo -e "${CYAN}💡 Use o Compose Templates para criar novos projetos${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    # Ordenar por data de modificação (corrigido)
    local sorted_projects=()
    while IFS= read -r line; do
        sorted_projects+=("$(echo "$line" | cut -d' ' -f2-)")
    done < <(printf '%s\n' "${all_projects[@]}" | while read -r project; do
        echo "$(stat -c %Y "$project" 2>/dev/null || echo 0) $project"
    done | sort -nr)
    
    local count=1
    for project in "${sorted_projects[@]}"; do
        local project_name=$(basename "$project")
        local project_type=$(basename "$(dirname "$project")")
        local last_modified=$(stat -c %y "$project" 2>/dev/null | cut -d' ' -f1)
        
        # Git status
        local git_info=""
        if [ -d "$project/.git" ]; then
            cd "$project"
            local branch=$(git branch --show-current 2>/dev/null)
            local changes=$(git status --porcelain 2>/dev/null | wc -l)
            if [ -n "$branch" ]; then
                git_info=" ${CYAN}[$branch]${NC}"
                if [ $changes -gt 0 ]; then
                    git_info="$git_info ${RED}($changes)${NC}"
                else
                    git_info="$git_info ${GREEN}✓${NC}"
                fi
            fi
        fi
        
        echo -e "  ${YELLOW}$count.${NC} $project_name ${PURPLE}($project_type)${NC} ${CYAN}$last_modified${NC}$git_info"
        ((count++))
    done
    
    echo ""
    echo -ne "${PURPLE}Escolha projeto [1-${#sorted_projects[@]}] ou Enter para voltar: ${NC}"
    read choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#sorted_projects[@]} ]; then
        local selected_project="${sorted_projects[$((choice-1))]}"
        open_project "$selected_project"
    fi
}

# Criar novo projeto
create_new_project() {
    if [ -f "./compose-templates.sh" ]; then
        echo -e "${CYAN}🚀 Abrindo Compose Templates...${NC}"
        ./compose-templates.sh
    else
        echo -e "${YELLOW}⚠️ Compose Templates não encontrado${NC}"
        echo -e "${CYAN}💡 Certifique-se de que compose-templates.sh está no mesmo diretório${NC}"
        read -p "Pressione Enter..."
    fi
}

# Navegação por número
navigate_by_number() {
    local input="$1"
    
    # Coletar todos os projetos ordenados
    local all_projects=()
    local base_dirs=("$WORKSPACE_DIR/nodejs" "$WORKSPACE_DIR/python-web" "$WORKSPACE_DIR/datascience" "$WORKSPACE_DIR/projects")
    
    for base_dir in "${base_dirs[@]}"; do
        if [ -d "$base_dir" ]; then
            while IFS= read -r -d '' project; do
                all_projects+=("$project")
            done < <(find "$base_dir" -maxdepth 1 -type d ! -path "$base_dir" -print0 2>/dev/null | sort -z)
        fi
    done
    
    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le ${#all_projects[@]} ]; then
        local selected_project="${all_projects[$((input-1))]}"
        open_project "$selected_project"
        return 0
    fi
    
    return 1
}

# Loop principal
main() {
    check_workspace
    
    while true; do
        show_header
        show_main_menu
        
        read choice
        case $choice in
            q|Q) quick_search ;;
            l|L) list_all_projects ;;
            r|R) reopen_last_project ;;
            s|S) show_environment_status ;;
            e|E) manage_environments ;;
            c|C) create_new_project ;;
            0) 
                echo -e "${GREEN}🔄 Até mais!${NC}"
                exit 0
                ;;
            *)
                # Tentar navegar por número
                if ! navigate_by_number "$choice"; then
                    echo -e "${RED}❌ Opção inválida. Pressione Enter...${NC}"
                    read
                fi
                ;;
        esac
    done
}

# Executar
main
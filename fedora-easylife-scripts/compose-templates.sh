#!/bin/bash

# ============================================================================
# COMPOSE TEMPLATES - Docker Compose Template Management
# ============================================================================
# Templates reutilizáveis e configuráveis para qualquer projeto
# Usage: ./compose-templates.sh ou compose-help (se instalado)
# ============================================================================

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
TEMPLATES_DIR="$HOME/docker-workspace/templates"
WORKSPACE_DIR="$HOME/docker-workspace"
PROJECTS_DIR="$WORKSPACE_DIR/projects"

# ============================================================================
# FUNÇÕES UTILITÁRIAS
# ============================================================================

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Header
show_header() {
    clear
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                🐳 COMPOSE TEMPLATES                           ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Status templates
    if [ -d "$TEMPLATES_DIR" ]; then
        local template_count=$(find "$TEMPLATES_DIR" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
        echo -e "${CYAN}📁 Templates disponíveis: ${YELLOW}$template_count${NC}"
        echo -e "${CYAN}📍 Localização: ${YELLOW}$TEMPLATES_DIR${NC}"
    else
        echo -e "${YELLOW}⚠️ Templates não inicializados${NC}"
    fi
    echo ""
}

# Menu principal
show_main_menu() {
    echo -e "${BLUE}═══════════════════ MENU PRINCIPAL ═══════════════════${NC}"
    echo -e "${YELLOW}1.${NC}  🏗️  Criar projeto com template"
    echo -e "${YELLOW}2.${NC}  📋 Listar templates disponíveis"
    echo -e "${YELLOW}3.${NC}  🔧 Configurar template para projeto existente"
    echo -e "${YELLOW}4.${NC}  📦 Combinar templates (compose múltiplo)"
    echo -e "${YELLOW}5.${NC}  ⚙️  Gerenciar templates"
    echo -e "${YELLOW}6.${NC}  🎯 Templates customizados"
    echo -e "${YELLOW}7.${NC}  📖 Documentação e exemplos"
    echo -e "${YELLOW}8.${NC}  🔄 Inicializar/Resetar templates"
    echo -e "${YELLOW}0.${NC}  ❌ Sair"
    echo ""
    echo -ne "${PURPLE}Escolha uma opção [0-8]: ${NC}"
}

# ============================================================================
# CRIAÇÃO DE TEMPLATES
# ============================================================================

# Criar estrutura de templates
create_templates_structure() {
    mkdir -p "$TEMPLATES_DIR"/{base,stacks,overrides,configs}
    
    # Base templates
    create_base_templates
    
    # Stack templates
    create_stack_templates
    
    # Override templates
    create_override_templates
    
    # Config templates
    create_config_templates
}

# Templates base reutilizáveis
create_base_templates() {
    # PostgreSQL base
    cat > "$TEMPLATES_DIR/base/postgres.yml" << 'EOF'
services:
  postgres:
    image: postgres:${POSTGRES_VERSION:-15}-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-app_db}
      POSTGRES_USER: ${POSTGRES_USER:-app_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-app_pass}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app_user}"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
EOF

    # Redis base
    cat > "$TEMPLATES_DIR/base/redis.yml" << 'EOF'
services:
  redis:
    image: redis:${REDIS_VERSION:-7}-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis_data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    command: redis-server --appendonly yes

volumes:
  redis_data:

networks:
  app-network:
    driver: bridge
EOF

    # Node.js base
    cat > "$TEMPLATES_DIR/base/nodejs.yml" << 'EOF'
services:
  nodejs:
    image: node:${NODE_VERSION:-18}-alpine
    working_dir: /app
    volumes:
      - .:/app
      - node_modules:/app/node_modules
    ports:
      - "${NODE_PORT:-3000}:3000"
      - "${NODE_DEV_PORT:-5173}:5173"
    environment:
      NODE_ENV: ${NODE_ENV:-development}
    networks:
      - app-network
    command: ${NODE_COMMAND:-npm run dev}
    stdin_open: true
    tty: true

volumes:
  node_modules:

networks:
  app-network:
    driver: bridge
EOF

    # Python base
    cat > "$TEMPLATES_DIR/base/python.yml" << 'EOF'
services:
  python:
    image: python:${PYTHON_VERSION:-3.11}-slim
    working_dir: /app
    volumes:
      - .:/app
      - pip_cache:/root/.cache/pip
    ports:
      - "${PYTHON_PORT:-8000}:8000"
    environment:
      PYTHONUNBUFFERED: 1
      PYTHONDONTWRITEBYTECODE: 1
    networks:
      - app-network
    command: ${PYTHON_COMMAND:-python main.py}

volumes:
  pip_cache:

networks:
  app-network:
    driver: bridge
EOF
}

# Stack templates completos
create_stack_templates() {
    # React + FastAPI + PostgreSQL
    cat > "$TEMPLATES_DIR/stacks/react-fastapi-postgres.yml" << 'EOF'
services:
  # Frontend React
  frontend:
    image: node:18-alpine
    working_dir: /app
    volumes:
      - ./frontend:/app
      - frontend_modules:/app/node_modules
    ports:
      - "${FRONTEND_PORT:-3000}:3000"
      - "${VITE_PORT:-5173}:5173"
    environment:
      NODE_ENV: development
      VITE_API_URL: http://localhost:${BACKEND_PORT:-8000}
    command: sh -c "npm install && npm run dev -- --host 0.0.0.0"
    networks:
      - app-network

  # Backend FastAPI
  backend:
    image: python:3.11-slim
    working_dir: /app
    volumes:
      - ./backend:/app
      - pip_cache:/root/.cache/pip
    ports:
      - "${BACKEND_PORT:-8000}:8000"
    environment:
      PYTHONUNBUFFERED: 1
      DATABASE_URL: postgresql://${POSTGRES_USER:-appuser}:${POSTGRES_PASSWORD:-apppass}@postgres:5432/${POSTGRES_DB:-appdb}
      CORS_ORIGINS: http://localhost:${FRONTEND_PORT:-3000}
    depends_on:
      postgres:
        condition: service_healthy
    command: sh -c "pip install -r requirements.txt && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
    networks:
      - app-network

  # PostgreSQL
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
      POSTGRES_USER: ${POSTGRES_USER:-appuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-apppass}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-appuser}"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis para cache
  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis_data:/data
    networks:
      - app-network

volumes:
  frontend_modules:
  pip_cache:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
EOF

    # MEAN Stack
    cat > "$TEMPLATES_DIR/stacks/mean.yml" << 'EOF'
services:
  # Frontend Angular
  frontend:
    image: node:18-alpine
    working_dir: /app
    volumes:
      - ./frontend:/app
      - frontend_modules:/app/node_modules
    ports:
      - "4200:4200"
    command: sh -c "npm install && npm start"
    environment:
      NODE_ENV: development
    networks:
      - mean-network

  # Backend Node.js/Express
  backend:
    image: node:18-alpine
    working_dir: /app
    volumes:
      - ./backend:/app
      - backend_modules:/app/node_modules
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: development
      MONGODB_URI: mongodb://mongo:27017/meanapp
    depends_on:
      - mongo
    command: sh -c "npm install && npm run dev"
    networks:
      - mean-network

  # MongoDB
  mongo:
    image: mongo:6
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: password
    networks:
      - mean-network

volumes:
  frontend_modules:
  backend_modules:
  mongo_data:

networks:
  mean-network:
    driver: bridge
EOF

    # Django + PostgreSQL
    cat > "$TEMPLATES_DIR/stacks/django-postgres.yml" << 'EOF'
services:
  # Django Web
  web:
    image: python:3.11-slim
    working_dir: /app
    volumes:
      - .:/app
      - pip_cache:/root/.cache/pip
    ports:
      - "${DJANGO_PORT:-8000}:8000"
    environment:
      PYTHONUNBUFFERED: 1
      DEBUG: ${DEBUG:-True}
      DATABASE_URL: postgresql://${POSTGRES_USER:-django}:${POSTGRES_PASSWORD:-django}@postgres:5432/${POSTGRES_DB:-django}
    depends_on:
      postgres:
        condition: service_healthy
    command: sh -c "pip install -r requirements.txt && python manage.py migrate && python manage.py runserver 0.0.0.0:8000"
    networks:
      - django-network

  # PostgreSQL
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-django}
      POSTGRES_USER: ${POSTGRES_USER:-django}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-django}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - django-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-django}"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  pip_cache:
  postgres_data:

networks:
  django-network:
    driver: bridge
EOF

    # Data Science Stack
    cat > "$TEMPLATES_DIR/stacks/datascience.yml" << 'EOF'
services:
  # Jupyter Lab
  jupyter:
    image: jupyter/tensorflow-notebook:latest
    working_dir: /home/jovyan/work
    volumes:
      - ./notebooks:/home/jovyan/work
      - ./data:/home/jovyan/work/data
      - jupyter_config:/home/jovyan/.jupyter
    ports:
      - "${JUPYTER_PORT:-8888}:8888"
      - "${TENSORBOARD_PORT:-6006}:6006"
    environment:
      JUPYTER_ENABLE_LAB: "yes"
      JUPYTER_TOKEN: ${JUPYTER_TOKEN:-dev123}
    user: root
    command: >
      bash -c "
        pip install --no-cache-dir mlflow plotly streamlit &&
        fix-permissions /home/jovyan &&
        start-notebook.sh --NotebookApp.token='${JUPYTER_TOKEN:-dev123}' --NotebookApp.password=''
      "
    networks:
      - ds-network

  # PostgreSQL para dados
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-datascience}
      POSTGRES_USER: ${POSTGRES_USER:-dsuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-dspass}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - ds-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-dsuser}"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  jupyter_config:
  postgres_data:

networks:
  ds-network:
    driver: bridge
EOF
}

# Override templates
create_override_templates() {
    # Development override
    cat > "$TEMPLATES_DIR/overrides/development.yml" << 'EOF'
# Development specific overrides
services:
  backend:
    volumes:
      - .:/app
    environment:
      DEBUG: "true"
      LOG_LEVEL: debug
    command: sh -c "pip install -r requirements-dev.txt && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"

  frontend:
    environment:
      NODE_ENV: development
      CHOKIDAR_USEPOLLING: "true"
    command: npm run dev -- --host 0.0.0.0

  postgres:
    ports:
      - "5432:5432"  # Expose for external tools
EOF

    # Production override
    cat > "$TEMPLATES_DIR/overrides/production.yml" << 'EOF'
# Production specific overrides
services:
  backend:
    restart: unless-stopped
    environment:
      DEBUG: "false"
      LOG_LEVEL: info
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M

  frontend:
    restart: unless-stopped
    environment:
      NODE_ENV: production
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 256M

  postgres:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 1G
EOF
}

# Config templates
create_config_templates() {
    # .env template
    cat > "$TEMPLATES_DIR/configs/.env.template" << 'EOF'
# Database Configuration
POSTGRES_VERSION=15
POSTGRES_DB=app_db
POSTGRES_USER=app_user
POSTGRES_PASSWORD=app_pass
POSTGRES_PORT=5432

# Redis Configuration
REDIS_VERSION=7
REDIS_PORT=6379

# Node.js Configuration
NODE_VERSION=18
NODE_ENV=development
NODE_PORT=3000
NODE_DEV_PORT=5173

# Python Configuration
PYTHON_VERSION=3.11
PYTHON_PORT=8000

# Frontend Configuration
FRONTEND_PORT=3000
VITE_PORT=5173
BACKEND_PORT=8000
EOF

    # Docker ignore template
    cat > "$TEMPLATES_DIR/configs/.dockerignore.template" << 'EOF'
node_modules
npm-debug.log
Dockerfile*
docker-compose*
.dockerignore
.git
.gitignore
README.md
.env
.nyc_output
coverage
.vscode
.idea
__pycache__
*.pyc
.pytest_cache
.coverage
venv
.venv
EOF
}

# ============================================================================
# FUNÇÕES PRINCIPAIS
# ============================================================================

# 1. Criar projeto com template
create_project_with_template() {
    clear
    echo -e "${BLUE}🏗️  CRIAR PROJETO COM TEMPLATE${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo ""
    
    # Verificar se templates existem
    if [ ! -d "$TEMPLATES_DIR/stacks" ]; then
        print_error "Templates não encontrados"
        print_info "Execute a opção 8 para inicializar"
        read -p "Pressione Enter..."
        return
    fi
    
    # Listar stacks disponíveis
    echo -e "${CYAN}📋 Stacks disponíveis:${NC}"
    local count=1
    local stacks=()
    
    for stack in "$TEMPLATES_DIR/stacks"/*.yml; do
        if [ -f "$stack" ]; then
            local stack_name=$(basename "$stack" .yml)
            local description=""
            
            case $stack_name in
                "react-fastapi-postgres") description="React + FastAPI + PostgreSQL" ;;
                "mean") description="MongoDB + Express + Angular + Node.js" ;;
                "django-postgres") description="Django + PostgreSQL" ;;
                "datascience") description="Jupyter + PostgreSQL" ;;
                *) description="Custom stack" ;;
            esac
            
            echo -e "  ${YELLOW}$count.${NC} $stack_name ${CYAN}($description)${NC}"
            stacks+=("$stack_name")
            ((count++))
        fi
    done
    
    if [ ${#stacks[@]} -eq 0 ]; then
        print_warning "Nenhum stack template encontrado"
        read -p "Pressione Enter..."
        return
    fi
    
    echo ""
    echo -ne "${PURPLE}Escolha stack [1-${#stacks[@]}]: ${NC}"
    read choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#stacks[@]} ]; then
        print_error "Opção inválida"
        read -p "Pressione Enter..."
        return
    fi
    
    local selected_stack="${stacks[$((choice-1))]}"
    
    # Nome do projeto
    echo -e "${CYAN}Nome do projeto:${NC}"
    read project_name
    
    if [ -z "$project_name" ]; then
        print_error "Nome do projeto não pode ser vazio"
        read -p "Pressione Enter..."
        return
    fi
    
    # Criar projeto
    create_project "$project_name" "$selected_stack"
}

# Função para criar projeto
create_project() {
    local project_name="$1"
    local selected_stack="$2"
    
    # Diretório do projeto
    local project_dir="$PROJECTS_DIR/$project_name"
    
    if [ -d "$project_dir" ]; then
        print_error "Projeto '$project_name' já existe"
        read -p "Pressione Enter..."
        return
    fi
    
    # Criar estrutura do projeto
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    # Copiar template
    cp "$TEMPLATES_DIR/stacks/$selected_stack.yml" docker-compose.yml
    
    # Criar .env baseado no template
    cp "$TEMPLATES_DIR/configs/.env.template" .env
    
    # Personalizar .env para o projeto
    sed -i "s/app_db/${project_name}_db/g" .env
    sed -i "s/app_user/${project_name}_user/g" .env
    sed -i "s/app_pass/${project_name}_pass/g" .env
    
    # Criar estrutura de diretórios baseada no stack
    case $selected_stack in
        "react-fastapi-postgres")
            mkdir -p frontend backend
            echo "# Frontend React" > frontend/README.md
            echo "# Backend FastAPI" > backend/README.md
            cat > backend/requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
psycopg2-binary==2.9.9
sqlalchemy==2.0.23
python-dotenv==1.0.0
EOF
            cat > backend/main.py << 'EOF'
from fastapi import FastAPI

app = FastAPI(title="API Backend")

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI!"}
EOF
            ;;
        "mean")
            mkdir -p frontend backend
            echo "# Frontend Angular" > frontend/README.md
            echo "# Backend Node.js/Express" > backend/README.md
            ;;
        "django-postgres")
            echo "# Django Project" > README.md
            cat > requirements.txt << 'EOF'
Django==4.2.7
psycopg2-binary==2.9.9
python-dotenv==1.0.0
EOF
            ;;
        "datascience")
            mkdir -p notebooks data models
            echo "# Data Science Project" > README.md
            ;;
    esac
    
    # Copiar configurações adicionais
    cp "$TEMPLATES_DIR/configs/.dockerignore.template" .dockerignore
    
    # Criar scripts de conveniência
    cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting project..."
docker compose up -d
echo "✅ Project started!"
docker compose ps
EOF
    
    cat > stop.sh << 'EOF'
#!/bin/bash
echo "⏹️ Stopping project..."
docker compose down
echo "✅ Project stopped!"
EOF
    
    cat > logs.sh << 'EOF'
#!/bin/bash
docker compose logs -f "$@"
EOF
    
    chmod +x start.sh stop.sh logs.sh
    
    # README do projeto
    cat > README.md << EOF
# $project_name

Project created with $selected_stack stack template.

## Quick Start

\`\`\`bash
# Start services
./start.sh

# Stop services  
./stop.sh

# View logs
./logs.sh [service_name]
\`\`\`

## Services

$(docker compose config --services 2>/dev/null | sed 's/^/- /' || echo "- Check docker-compose.yml")

## Configuration

Edit \`.env\` file to customize:
- Database credentials
- Port mappings
- Service versions

## Development

\`\`\`bash
# Access service shell
docker compose exec [service_name] sh

# View service logs
docker compose logs -f [service_name]

# Restart service
docker compose restart [service_name]
\`\`\`
EOF
    
    print_success "Projeto '$project_name' criado com sucesso!"
    echo -e "${CYAN}📁 Localização: $project_dir${NC}"
    echo -e "${CYAN}📋 Stack: $selected_stack${NC}"
    echo ""
    echo -e "${YELLOW}💡 Próximos passos:${NC}"
    echo -e "${CYAN}1. cd $project_dir${NC}"
    echo -e "${CYAN}2. ./start.sh${NC}"
    echo -e "${CYAN}3. Editar .env se necessário${NC}"
    
    read -p "Pressione Enter para continuar..."
}

# 2. Listar templates
list_templates() {
    clear
    echo -e "${BLUE}📋 TEMPLATES DISPONÍVEIS${NC}"
    echo -e "${BLUE}========================${NC}"
    echo ""
    
    if [ ! -d "$TEMPLATES_DIR" ]; then
        print_warning "Nenhum template encontrado"
        print_info "Execute a opção 8 para inicializar"
        read -p "Pressione Enter..."
        return
    fi
    
    # Stack templates
    echo -e "${YELLOW}📚 STACK TEMPLATES:${NC}"
    if [ -d "$TEMPLATES_DIR/stacks" ]; then
        for template in "$TEMPLATES_DIR/stacks"/*.yml; do
            if [ -f "$template" ]; then
                local name=$(basename "$template" .yml)
                local services=$(grep -c "^\s*[a-zA-Z].*:" "$template" 2>/dev/null || echo "0")
                echo -e "  ${GREEN}✓${NC} $name ${CYAN}($services services)${NC}"
                
                # Mostrar serviços
                grep "^\s*[a-zA-Z][^:]*:" "$template" 2>/dev/null | sed 's/://' | sed 's/^/    - /' | head -3
                local total_services=$(grep -c "^\s*[a-zA-Z].*:" "$template" 2>/dev/null || echo "0")
                if [ $total_services -gt 3 ]; then
                    echo "    ... e $((total_services - 3)) mais"
                fi
                echo ""
            fi
        done
    else
        echo -e "  ${YELLOW}Nenhum stack template${NC}"
    fi
    
    # Base templates
    echo -e "${YELLOW}🧱 BASE TEMPLATES:${NC}"
    if [ -d "$TEMPLATES_DIR/base" ]; then
        for template in "$TEMPLATES_DIR/base"/*.yml; do
            if [ -f "$template" ]; then
                local name=$(basename "$template" .yml)
                echo -e "  ${GREEN}✓${NC} $name"
            fi
        done
    else
        echo -e "  ${YELLOW}Nenhum base template${NC}"
    fi
    echo ""
    
    # Override templates
    echo -e "${YELLOW}🔧 OVERRIDE TEMPLATES:${NC}"
    if [ -d "$TEMPLATES_DIR/overrides" ]; then
        for template in "$TEMPLATES_DIR/overrides"/*.yml; do
            if [ -f "$template" ]; then
                local name=$(basename "$template" .yml)
                echo -e "  ${GREEN}✓${NC} $name"
            fi
        done
    else
        echo -e "  ${YELLOW}Nenhum override template${NC}"
    fi
    
    read -p "Pressione Enter para continuar..."
}

# 8. Inicializar templates
initialize_templates() {
    clear
    echo -e "${BLUE}🔄 INICIALIZAR/RESETAR TEMPLATES${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    if [ -d "$TEMPLATES_DIR" ]; then
        print_warning "Diretório de templates já existe"
        echo -e "${CYAN}Localização: $TEMPLATES_DIR${NC}"
        echo ""
        echo -e "${YELLOW}1.${NC} Manter e adicionar templates faltantes"
        echo -e "${YELLOW}2.${NC} Resetar completamente (apagar tudo)"
        echo -e "${YELLOW}3.${NC} Cancelar"
        echo ""
        echo -ne "${PURPLE}Escolha [1-3]: ${NC}"
        read choice
        
        case $choice in
            1)
                print_info "Adicionando templates faltantes..."
                create_templates_structure
                ;;
            2)
                print_warning "Isso apagará TODOS os templates existentes!"
                echo -ne "${YELLOW}Confirma? (digite 'RESET' para confirmar): ${NC}"
                read confirm
                if [ "$confirm" = "RESET" ]; then
                    rm -rf "$TEMPLATES_DIR"
                    print_info "Templates apagados"
                    print_info "Criando novos templates..."
                    create_templates_structure
                else
                    print_warning "Operação cancelada"
                    read -p "Pressione Enter..."
                    return
                fi
                ;;
            3)
                return
                ;;
            *)
                print_error "Opção inválida"
                read -p "Pressione Enter..."
                return
                ;;
        esac
    else
        print_info "Criando estrutura de templates..."
        create_templates_structure
    fi
    
    print_success "Templates inicializados com sucesso!"
    echo -e "${CYAN}📁 Localização: $TEMPLATES_DIR${NC}"
    
    # Estatísticas
    local base_count=$(find "$TEMPLATES_DIR/base" -name "*.yml" 2>/dev/null | wc -l)
    local stack_count=$(find "$TEMPLATES_DIR/stacks" -name "*.yml" 2>/dev/null | wc -l)
    local override_count=$(find "$TEMPLATES_DIR/overrides" -name "*.yml" 2>/dev/null | wc -l)
    local config_count=$(find "$TEMPLATES_DIR/configs" -name "*" -type f 2>/dev/null | wc -l)
    
    echo ""
    echo -e "${CYAN}📊 Templates criados:${NC}"
    echo -e "  ${GREEN}🧱 Base: $base_count${NC}"
    echo -e "  ${GREEN}📚 Stacks: $stack_count${NC}"
    echo -e "  ${GREEN}🔧 Overrides: $override_count${NC}"
    echo -e "  ${GREEN}⚙️ Configs: $config_count${NC}"
    
    read -p "Pressione Enter para continuar..."
}

# Funções placeholder para opções não implementadas
placeholder_function() {
    local option_name="$1"
    clear
    echo -e "${BLUE}🚧 $option_name - EM DESENVOLVIMENTO${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    print_info "Esta funcionalidade está sendo desenvolvida"
    print_info "Disponível em versões futuras"
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 3. Configurar template para projeto existente
configure_existing_project() {
    placeholder_function "CONFIGURAR PROJETO EXISTENTE"
}

# 4. Combinar templates
combine_templates() {
    placeholder_function "COMBINAR TEMPLATES"
}

# 5. Gerenciar templates
manage_templates() {
    placeholder_function "GERENCIAR TEMPLATES"
}

# 6. Templates customizados
custom_templates() {
    placeholder_function "TEMPLATES CUSTOMIZADOS"
}

# 7. Documentação
show_documentation() {
    clear
    echo -e "${BLUE}📖 DOCUMENTAÇÃO E EXEMPLOS${NC}"
    echo -e "${BLUE}============================${NC}"
    echo ""
    
    echo -e "${CYAN}🎯 Como usar:${NC}"
    echo ""
    echo -e "${YELLOW}1. Inicializar templates:${NC}"
    echo -e "   Opção 8 → Cria todos os templates padrão"
    echo ""
    echo -e "${YELLOW}2. Criar projeto:${NC}"
    echo -e "   Opção 1 → Escolhe stack → Nome do projeto"
    echo ""
    echo -e "${YELLOW}3. Comandos no projeto:${NC}"
    echo -e "   ./start.sh    # Iniciar serviços"
    echo -e "   ./stop.sh     # Parar serviços"
    echo -e "   ./logs.sh     # Ver logs"
    echo ""
    
    echo -e "${CYAN}🏗️ Stacks disponíveis:${NC}"
    echo ""
    echo -e "${GREEN}• react-fastapi-postgres:${NC} Frontend React + Backend FastAPI + PostgreSQL"
    echo -e "${GREEN}• mean:${NC} MongoDB + Express + Angular + Node.js"
    echo -e "${GREEN}• django-postgres:${NC} Django + PostgreSQL"
    echo -e "${GREEN}• datascience:${NC} Jupyter Lab + PostgreSQL"
    echo ""
    
    echo -e "${CYAN}📁 Estrutura criada:${NC}"
    echo ""
    echo -e "projeto/"
    echo -e "├── docker-compose.yml    # Configuração dos serviços"
    echo -e "├── .env                  # Variáveis de ambiente"
    echo -e "├── start.sh              # Script para iniciar"
    echo -e "├── stop.sh               # Script para parar"
    echo -e "├── logs.sh               # Script para logs"
    echo -e "├── README.md             # Documentação"
    echo -e "└── frontend/backend/     # Diretórios do código"
    echo ""
    
    echo -e "${CYAN}⚙️ Personalização:${NC}"
    echo ""
    echo -e "• Edite o arquivo ${YELLOW}.env${NC} para alterar portas, senhas, etc."
    echo -e "• Modifique ${YELLOW}docker-compose.yml${NC} para serviços específicos"
    echo -e "• Use ${YELLOW}overrides${NC} para diferentes ambientes (dev/prod)"
    echo ""
    
    read -p "Pressione Enter para continuar..."
}

# ============================================================================
# LOOP PRINCIPAL
# ============================================================================

# Loop principal
main() {
    # Criar diretório de projetos se não existir
    mkdir -p "$PROJECTS_DIR"
    
    while true; do
        show_header
        show_main_menu
        
        read choice
        case $choice in
            1) create_project_with_template ;;
            2) list_templates ;;
            3) configure_existing_project ;;
            4) combine_templates ;;
            5) manage_templates ;;
            6) custom_templates ;;
            7) show_documentation ;;
            8) initialize_templates ;;
            0) 
                print_success "Até mais!"
                exit 0
                ;;
            *)
                print_error "Opção inválida"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# EXECUÇÃO
# ============================================================================

# Verificar se está no ambiente correto
if [ ! -d "$HOME/docker-workspace" ]; then
    print_warning "Docker workspace não encontrado"
    print_info "Execute primeiro o setup completo: ./setup_install_all.sh"
    exit 1
fi

# Executar loop principal
main
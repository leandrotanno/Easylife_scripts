#!/bin/bash

# Compose Templates - Universal Docker Compose Management
# Templates reutilizáveis e configuráveis para qualquer projeto
# Usage: ./compose-templates.sh ou compose-help (se instalado)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

TEMPLATES_DIR="$HOME/docker-workspace/templates"
WORKSPACE_DIR="$HOME/docker-workspace"

# Criar estrutura de templates
init_templates() {
    mkdir -p "$TEMPLATES_DIR"/{base,stacks,overrides,configs}
    
    # Diretório do projeto
    local project_dir="$WORKSPACE_DIR/projects/$project_name"
    
    if [ -d "$project_dir" ]; then
        echo -e "${RED}❌ Projeto '$project_name' já existe${NC}"
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
        "mean")
            mkdir -p frontend backend
            echo "# Frontend Angular" > frontend/README.md
            echo "# Backend Node.js/Express" > backend/README.md
            ;;
        "lamp")
            mkdir -p src
            echo "<?php echo 'Hello LAMP!'; ?>" > src/index.php
            ;;
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
        "django-postgres-redis")
            echo "# Django Project" > README.md
            cat > requirements.txt << 'EOF'
Django==4.2.7
psycopg2-binary==2.9.9
redis==5.0.1
celery==5.3.4
python-dotenv==1.0.0
EOF
            ;;
        "datascience")
            mkdir -p notebooks data models
            echo "# Data Science Project" > README.md
            ;;
        "microservices")
            mkdir -p services/{auth,users,products}
            echo "# Auth Service" > services/auth/README.md
            echo "# Users Service" > services/users/README.md
            echo "# Products Service" > services/products/README.md
            ;;
    esac
    
    # Copiar configurações adicionais
    cp "$TEMPLATES_DIR/configs/.dockerignore.template" .dockerignore
    
    if [ -f "$TEMPLATES_DIR/configs/nginx.conf.template" ]; then
        cp "$TEMPLATES_DIR/configs/nginx.conf.template" nginx.conf
    fi
    
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

$(docker compose config --services 2>/dev/null | sed 's/^/- /')

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
    
    echo -e "${GREEN}✅ Projeto '$project_name' criado com sucesso!${NC}"
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
        echo -e "${YELLOW}📁 Nenhum template encontrado${NC}"
        echo -e "${CYAN}Execute a opção 8 para inicializar${NC}"
        read -p "Pressione Enter..."
        return
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
    
    # Stack templates
    echo -e "${YELLOW}📚 STACK TEMPLATES:${NC}"
    if [ -d "$TEMPLATES_DIR/stacks" ]; then
        for template in "$TEMPLATES_DIR/stacks"/*.yml; do
            if [ -f "$template" ]; then
                local name=$(basename "$template" .yml)
                local services=$(grep -c "^\s*[a-zA-Z].*:" "$template" || echo "0")
                echo -e "  ${GREEN}✓${NC} $name ${CYAN}($services services)${NC}"
                
                # Mostrar serviços
                grep "^\s*[a-zA-Z][^:]*:" "$template" | sed 's/://' | sed 's/^/    - /' | head -5
                local total_services=$(grep -c "^\s*[a-zA-Z].*:" "$template")
                if [ $total_services -gt 5 ]; then
                    echo "    ... e $((total_services - 5)) mais"
                fi
                echo ""
            fi
        done
    else
        echo -e "  ${YELLOW}Nenhum stack template${NC}"
    fi
    
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

# 3. Configurar template para projeto existente
configure_existing_project() {
    clear
    echo -e "${BLUE}🔧 CONFIGURAR PROJETO EXISTENTE${NC}"
    echo -e "${BLUE}===============================${NC}"
    echo ""
    
    # Listar projetos existentes
    echo -e "${CYAN}📁 Projetos disponíveis:${NC}"
    local projects=()
    local count=1
    
    # Verificar em diferentes diretórios
    for base_dir in "$WORKSPACE_DIR/nodejs" "$WORKSPACE_DIR/python-web" "$WORKSPACE_DIR/datascience" "$WORKSPACE_DIR/projects"; do
        if [ -d "$base_dir" ]; then
            for project in "$base_dir"/*; do
                if [ -d "$project" ]; then
                    local project_name=$(basename "$project")
                    local project_type=$(basename "$base_dir")
                    echo -e "  ${YELLOW}$count.${NC} $project_name ${CYAN}($project_type)${NC}"
                    projects+=("$project")
                    ((count++))
                fi
            done
        fi
    done
    
    if [ ${#projects[@]} -eq 0 ]; then
        echo -e "${YELLOW}📁 Nenhum projeto encontrado${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    echo ""
    echo -ne "${PURPLE}Escolha projeto [1-${#projects[@]}]: ${NC}"
    read choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#projects[@]} ]; then
        echo -e "${RED}❌ Opção inválida${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    local selected_project="${projects[$((choice-1))]}"
    
    # Listar templates disponíveis
    echo ""
    echo -e "${CYAN}📋 Templates disponíveis:${NC}"
    local templates=()
    count=1
    
    for template in "$TEMPLATES_DIR/stacks"/*.yml; do
        if [ -f "$template" ]; then
            local template_name=$(basename "$template" .yml)
            echo -e "  ${YELLOW}$count.${NC} $template_name"
            templates+=("$template_name")
            ((count++))
        fi
    done
    
    echo ""
    echo -ne "${PURPLE}Escolha template [1-${#templates[@]}]: ${NC}"
    read template_choice
    
    if [[ ! "$template_choice" =~ ^[0-9]+$ ]] || [ "$template_choice" -lt 1 ] || [ "$template_choice" -gt ${#templates[@]} ]; then
        echo -e "${RED}❌ Opção inválida${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    local selected_template="${templates[$((template_choice-1))]}"
    
    # Confirmar ação
    echo ""
    echo -e "${YELLOW}⚠️ Isso criará/substituirá docker-compose.yml no projeto${NC}"
    echo -e "${CYAN}Projeto: $(basename "$selected_project")${NC}"
    echo -e "${CYAN}Template: $selected_template${NC}"
    echo ""
    echo -ne "${PURPLE}Continuar? (y/N): ${NC}"
    read -n 1 confirm
    echo
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}⏭️ Operação cancelada${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    # Aplicar template
    cd "$selected_project"
    
    # Backup se já existir
    if [ -f "docker-compose.yml" ]; then
        cp "docker-compose.yml" "docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CYAN}📋 Backup criado: docker-compose.yml.backup.*${NC}"
    fi
    
    # Copiar template
    cp "$TEMPLATES_DIR/stacks/$selected_template.yml" docker-compose.yml
    
    # Criar/atualizar .env se não existir
    if [ ! -f ".env" ]; then
        cp "$TEMPLATES_DIR/configs/.env.template" .env
        local project_name=$(basename "$selected_project")
        sed -i "s/app_db/${project_name}_db/g" .env
        sed -i "s/app_user/${project_name}_user/g" .env
        sed -i "s/app_pass/${project_name}_pass/g" .env
        echo -e "${CYAN}📝 Arquivo .env criado${NC}"
    fi
    
    # Criar scripts se não existirem
    if [ ! -f "start.sh" ]; then
        cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting project..."
docker compose up -d
echo "✅ Project started!"
docker compose ps
EOF
        chmod +x start.sh
        echo -e "${CYAN}📜 Script start.sh criado${NC}"
    fi
    
    echo -e "${GREEN}✅ Template aplicado com sucesso!${NC}"
    echo -e "${CYAN}📁 Projeto: $selected_project${NC}"
    echo -e "${CYAN}📋 Template: $selected_template${NC}"
    
    read -p "Pressione Enter para continuar..."
}

# 4. Combinar templates
combine_templates() {
    clear
    echo -e "${BLUE}📦 COMBINAR TEMPLATES${NC}"
    echo -e "${BLUE}===================${NC}"
    echo ""
    
    echo -e "${CYAN}💡 Combine múltiplos templates base para criar um stack customizado${NC}"
    echo ""
    
    # Listar base templates
    echo -e "${YELLOW}🧱 Base templates disponíveis:${NC}"
    local base_templates=()
    local count=1
    
    for template in "$TEMPLATES_DIR/base"/*.yml; do
        if [ -f "$template" ]; then
            local template_name=$(basename "$template" .yml)
            echo -e "  ${YELLOW}$count.${NC} $template_name"
            base_templates+=("$template_name")
            ((count++))
        fi
    done
    
    if [ ${#base_templates[@]} -eq 0 ]; then
        echo -e "${YELLOW}📁 Nenhum base template encontrado${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    echo ""
    echo -e "${CYAN}Selecione templates para combinar (separados por espaço, ex: 1 2 3):${NC}"
    read selected_numbers
    
    if [ -z "$selected_numbers" ]; then
        echo -e "${RED}❌ Nenhum template selecionado${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    # Nome do novo compose
    echo -e "${CYAN}Nome para o arquivo combinado:${NC}"
    read compose_name
    
    if [ -z "$compose_name" ]; then
        compose_name="docker-compose-combined"
    fi
    
    # Diretório de saída
    echo -e "${CYAN}Diretório de saída [current]:${NC}"
    read output_dir
    
    if [ -z "$output_dir" ]; then
        output_dir="."
    fi
    
    mkdir -p "$output_dir"
    local output_file="$output_dir/$compose_name.yml"
    
    # Combinar templates
    echo "# Combined Docker Compose" > "$output_file"
    echo "# Generated on $(date)" >> "$output_file"
    echo "" >> "$output_file"
    
    local all_services=""
    local all_volumes=""
    local all_networks=""
    
    for num in $selected_numbers; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#base_templates[@]} ]; then
            local template_name="${base_templates[$((num-1))]}"
            local template_file="$TEMPLATES_DIR/base/$template_name.yml"
            
            echo -e "${CYAN}📦 Adicionando $template_name...${NC}"
            
            # Extrair serviços
            sed -n '/^services:/,/^volumes:\|^networks:\|^$/p' "$template_file" | head -n -1 >> "/tmp/services_$template_name"
            # Extrair volumes
            sed -n '/^volumes:/,/^networks:\|^$/p' "$template_file" | head -n -1 >> "/tmp/volumes_$template_name"
            # Extrair networks
            sed -n '/^networks:/,$p' "$template_file" >> "/tmp/networks_$template_name"
        fi
    done
    
    # Construir arquivo final
    echo "services:" >> "$output_file"
    for num in $selected_numbers; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#base_templates[@]} ]; then
            local template_name="${base_templates[$((num-1))]}"
            if [ -f "/tmp/services_$template_name" ]; then
                sed '1d' "/tmp/services_$template_name" >> "$output_file"
                rm "/tmp/services_$template_name"
            fi
        fi
    done
    
    echo "" >> "$output_file"
    echo "volumes:" >> "$output_file"
    for num in $selected_numbers; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#base_templates[@]} ]; then
            local template_name="${base_templates[$((num-1))]}"
            if [ -f "/tmp/volumes_$template_name" ]; then
                sed '1d' "/tmp/volumes_$template_name" >> "$output_file"
                rm "/tmp/volumes_$template_name"
            fi
        fi
    done
    
    echo "" >> "$output_file"
    echo "networks:" >> "$output_file"
    for num in $selected_numbers; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#base_templates[@]} ]; then
            local template_name="${base_templates[$((num-1))]}"
            if [ -f "/tmp/networks_$template_name" ]; then
                sed '1d' "/tmp/networks_$template_name" >> "$output_file"
                rm "/tmp/networks_$template_name"
                break  # Só um network é necessário
            fi
        fi
    done
    
    echo -e "${GREEN}✅ Templates combinados com sucesso!${NC}"
    echo -e "${CYAN}📁 Arquivo: $output_file${NC}"
    echo -e "${CYAN}📋 Templates combinados: ${selected_numbers// /, }${NC}"
    
    read -p "Pressione Enter para continuar..."
}

# 8. Inicializar templates
initialize_templates() {
    clear
    echo -e "${BLUE}🔄 INICIALIZAR/RESETAR TEMPLATES${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    if [ -d "$TEMPLATES_DIR" ]; then
        echo -e "${YELLOW}⚠️ Diretório de templates já existe${NC}"
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
                echo -e "${CYAN}📦 Adicionando templates faltantes...${NC}"
                init_templates
                ;;
            2)
                echo -e "${RED}⚠️ Isso apagará TODOS os templates existentes!${NC}"
                echo -ne "${YELLOW}Confirma? (digite 'RESET' para confirmar): ${NC}"
                read confirm
                if [ "$confirm" = "RESET" ]; then
                    rm -rf "$TEMPLATES_DIR"
                    echo -e "${CYAN}🗑️ Templates apagados${NC}"
                    echo -e "${CYAN}📦 Criando novos templates...${NC}"
                    init_templates
                else
                    echo -e "${YELLOW}⏭️ Operação cancelada${NC}"
                    read -p "Pressione Enter..."
                    return
                fi
                ;;
            3)
                return
                ;;
            *)
                echo -e "${RED}❌ Opção inválida${NC}"
                read -p "Pressione Enter..."
                return
                ;;
        esac
    else
        echo -e "${CYAN}📦 Criando estrutura de templates...${NC}"
        init_templates
    fi
    
    echo -e "${GREEN}✅ Templates inicializados com sucesso!${NC}"
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

# Loop principal
main() {
    while true; do
        show_header
        show_main_menu
        
        read choice
        case $choice in
            1) create_project_with_template ;;
            2) list_templates ;;
            3) configure_existing_project ;;
            4) combine_templates ;;
            5) echo -e "${YELLOW}⚙️ Gerenciar templates - Em desenvolvimento${NC}"; read -p "Pressione Enter..." ;;
            6) echo -e "${YELLOW}🎯 Templates customizados - Em desenvolvimento${NC}"; read -p "Pressione Enter..." ;;
            7) echo -e "${YELLOW}📖 Documentação - Em desenvolvimento${NC}"; read -p "Pressione Enter..." ;;
            8) initialize_templates ;;
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
main Base templates
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

    # Nginx base
    cat > "$TEMPLATES_DIR/base/nginx.yml" << 'EOF'
services:
  nginx:
    image: nginx:${NGINX_VERSION:-alpine}
    ports:
      - "${NGINX_HTTP_PORT:-80}:80"
      - "${NGINX_HTTPS_PORT:-443}:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - static_files:/var/www/static
    networks:
      - app-network
    depends_on:
      - backend

volumes:
  static_files:

networks:
  app-network:
    driver: bridge
EOF
}

# Stack templates completos
create_stack_templates() {
    # MEAN Stack (MongoDB, Express, Angular, Node)
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

  # Redis para sessions
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - mean-network

volumes:
  frontend_modules:
  backend_modules:
  mongo_data:
  redis_data:

networks:
  mean-network:
    driver: bridge
EOF

    # LAMP Stack (Linux, Apache, MySQL, PHP)
    cat > "$TEMPLATES_DIR/stacks/lamp.yml" << 'EOF'
services:
  # PHP Apache
  web:
    image: php:${PHP_VERSION:-8.2}-apache
    ports:
      - "${WEB_PORT:-80}:80"
    volumes:
      - ./src:/var/www/html
      - ./apache.conf:/etc/apache2/sites-available/000-default.conf
    environment:
      APACHE_DOCUMENT_ROOT: /var/www/html
    depends_on:
      - mysql
    networks:
      - lamp-network

  # MySQL
  mysql:
    image: mysql:${MYSQL_VERSION:-8.0}
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-rootpass}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-lampapp}
      MYSQL_USER: ${MYSQL_USER:-lampuser}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-lamppass}
    ports:
      - "${MYSQL_PORT:-3306}:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - lamp-network

  # phpMyAdmin
  phpmyadmin:
    image: phpmyadmin:latest
    ports:
      - "${PMA_PORT:-8080}:80"
    environment:
      PMA_HOST: mysql
      PMA_USER: root
      PMA_PASSWORD: ${MYSQL_ROOT_PASSWORD:-rootpass}
    depends_on:
      - mysql
    networks:
      - lamp-network

volumes:
  mysql_data:

networks:
  lamp-network:
    driver: bridge
EOF

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

    # Django + PostgreSQL + Redis
    cat > "$TEMPLATES_DIR/stacks/django-postgres-redis.yml" << 'EOF'
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
      REDIS_URL: redis://redis:6379/0
    depends_on:
      postgres:
        condition: service_healthy
      redis:
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

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis_data:/data
    networks:
      - django-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Celery Worker (opcional)
  celery:
    image: python:3.11-slim
    working_dir: /app
    volumes:
      - .:/app
      - pip_cache:/root/.cache/pip
    environment:
      PYTHONUNBUFFERED: 1
      DATABASE_URL: postgresql://${POSTGRES_USER:-django}:${POSTGRES_PASSWORD:-django}@postgres:5432/${POSTGRES_DB:-django}
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    command: sh -c "pip install -r requirements.txt && celery -A project worker -l info"
    networks:
      - django-network

volumes:
  pip_cache:
  postgres_data:
  redis_data:

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
        pip install --no-cache-dir \
          mlflow wandb \
          plotly dash streamlit \
          xgboost lightgbm catboost \
          optuna hyperopt \
          shap lime \
          geopandas folium &&
        fix-permissions /home/jovyan &&
        start-notebook.sh --NotebookApp.token='${JUPYTER_TOKEN:-dev123}' --NotebookApp.password=''
      "
    networks:
      - ds-network

  # MLflow Tracking Server
  mlflow:
    image: python:3.11-slim
    working_dir: /app
    volumes:
      - ./mlflow:/app
      - mlflow_artifacts:/mlflow-artifacts
    ports:
      - "${MLFLOW_PORT:-5000}:5000"
    environment:
      MLFLOW_BACKEND_STORE_URI: postgresql://${POSTGRES_USER:-mlflow}:${POSTGRES_PASSWORD:-mlflow}@postgres:5432/${POSTGRES_DB:-mlflow}
      MLFLOW_DEFAULT_ARTIFACT_ROOT: /mlflow-artifacts
    depends_on:
      postgres:
        condition: service_healthy
    command: >
      bash -c "
        pip install mlflow[extras] psycopg2-binary &&
        mlflow server --host 0.0.0.0 --port 5000
      "
    networks:
      - ds-network

  # PostgreSQL para MLflow
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-mlflow}
      POSTGRES_USER: ${POSTGRES_USER:-mlflow}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-mlflow}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - ds-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-mlflow}"]
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
      - ds-network

volumes:
  jupyter_config:
  mlflow_artifacts:
  postgres_data:
  redis_data:

networks:
  ds-network:
    driver: bridge
EOF

    # Microservices Stack
    cat > "$TEMPLATES_DIR/stacks/microservices.yml" << 'EOF'
services:
  # API Gateway (Nginx)
  gateway:
    image: nginx:alpine
    ports:
      - "${GATEWAY_PORT:-80}:80"
      - "${GATEWAY_HTTPS_PORT:-443}:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - auth-service
      - user-service
      - product-service
    networks:
      - microservices-network

  # Auth Service
  auth-service:
    image: node:18-alpine
    working_dir: /app
    volumes:
      - ./services/auth:/app
      - auth_modules:/app/node_modules
    ports:
      - "${AUTH_PORT:-3001}:3000"
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://${POSTGRES_USER:-auth}:${POSTGRES_PASSWORD:-auth}@postgres:5432/${AUTH_DB:-auth_db}
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    command: sh -c "npm install && npm run dev"
    networks:
      - microservices-network

  # User Service
  user-service:
    image: python:3.11-slim
    working_dir: /app
    volumes:
      - ./services/users:/app
      - user_cache:/root/.cache/pip
    ports:
      - "${USER_PORT:-3002}:8000"
    environment:
      PYTHONUNBUFFERED: 1
      DATABASE_URL: postgresql://${POSTGRES_USER:-users}:${POSTGRES_PASSWORD:-users}@postgres:5432/${USER_DB:-users_db}
    depends_on:
      - postgres
    command: sh -c "pip install -r requirements.txt && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
    networks:
      - microservices-network

  # Product Service
  product-service:
    image: python:3.11-slim
    working_dir: /app
    volumes:
      - ./services/products:/app
      - product_cache:/root/.cache/pip
    ports:
      - "${PRODUCT_PORT:-3003}:8000"
    environment:
      PYTHONUNBUFFERED: 1
      DATABASE_URL: postgresql://${POSTGRES_USER:-products}:${POSTGRES_PASSWORD:-products}@postgres:5432/${PRODUCT_DB:-products_db}
    depends_on:
      - postgres
    command: sh -c "pip install -r requirements.txt && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
    networks:
      - microservices-network

  # PostgreSQL
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-microservices}
      POSTGRES_USER: ${POSTGRES_USER:-microservices}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-microservices}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-dbs.sql:/docker-entrypoint-initdb.d/init-dbs.sql:ro
    networks:
      - microservices-network

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis_data:/data
    networks:
      - microservices-network

volumes:
  auth_modules:
  user_cache:
  product_cache:
  postgres_data:
  redis_data:

networks:
  microservices-network:
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
    command: sh -c "pip install -r requirements-dev.txt && python -m debugpy --listen 0.0.0.0:5678 --wait-for-client main.py"
    ports:
      - "5678:5678"  # Debug port

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
        reservations:
          cpus: '0.25'
          memory: 256M

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
        reservations:
          cpus: '0.25'
          memory: 512M
EOF

    # Testing override
    cat > "$TEMPLATES_DIR/overrides/testing.yml" << 'EOF'
# Testing specific overrides
services:
  backend:
    environment:
      NODE_ENV: test
      DATABASE_URL: postgresql://test:test@postgres:5432/test_db
    command: npm run test:watch

  postgres:
    environment:
      POSTGRES_DB: test_db
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test

  test-runner:
    image: node:18-alpine
    working_dir: /app
    volumes:
      - .:/app
    environment:
      NODE_ENV: test
    command: npm run test:ci
    depends_on:
      - postgres
    networks:
      - app-network
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
NODE_COMMAND=npm run dev

# Python Configuration
PYTHON_VERSION=3.11
PYTHON_PORT=8000
PYTHON_COMMAND=python main.py

# Nginx Configuration
NGINX_VERSION=alpine
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
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
.tox
venv
.venv
EOF

    # Nginx config template
    cat > "$TEMPLATES_DIR/configs/nginx.conf.template" << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:8000;
    }

    upstream frontend {
        server frontend:3000;
    }

    server {
        listen 80;
        server_name localhost;

        # Frontend
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # API Backend
        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # WebSocket support
        location /ws/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
        }
    }
}
EOF
}

# Header
show_header() {
    clear
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                🐳 COMPOSE TEMPLATES                           ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Status templates
    if [ -d "$TEMPLATES_DIR" ]; then
        local template_count=$(find "$TEMPLATES_DIR" -name "*.yml" -o -name "*.yaml" | wc -l)
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

# 1. Criar projeto com template
create_project_with_template() {
    clear
    echo -e "${BLUE}🏗️  CRIAR PROJETO COM TEMPLATE${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo ""
    
    # Verificar se templates existem
    if [ ! -d "$TEMPLATES_DIR/stacks" ]; then
        echo -e "${RED}❌ Templates não encontrados${NC}"
        echo -e "${CYAN}Execute a opção 8 para inicializar${NC}"
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
                "mean") description="MongoDB + Express + Angular + Node.js" ;;
                "lamp") description="Linux + Apache + MySQL + PHP" ;;
                "react-fastapi-postgres") description="React + FastAPI + PostgreSQL" ;;
                "django-postgres-redis") description="Django + PostgreSQL + Redis" ;;
                "datascience") description="Jupyter + MLflow + PostgreSQL" ;;
                "microservices") description="Nginx + Multiple Services + PostgreSQL" ;;
                *) description="Custom stack" ;;
            esac
            
            echo -e "  ${YELLOW}$count.${NC} $stack_name ${CYAN}($description)${NC}"
            stacks+=("$stack_name")
            ((count++))
        fi
    done
    
    if [ ${#stacks[@]} -eq 0 ]; then
        echo -e "${YELLOW}📁 Nenhum stack template encontrado${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    echo ""
    echo -ne "${PURPLE}Escolha stack [1-${#stacks[@]}]: ${NC}"
    read choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#stacks[@]} ]; then
        echo -e "${RED}❌ Opção inválida${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    local selected_stack="${stacks[$((choice-1))]}"
    
    # Nome do projeto
    echo -e "${CYAN}Nome do projeto:${NC}"
    read project_name
    
    if [ -z "$project_name" ]; then
        echo -e "${RED}❌ Nome do projeto não pode ser vazio${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    #
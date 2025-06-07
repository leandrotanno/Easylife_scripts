#!/bin/bash

# Database Helper - PostgreSQL Management for Docker Development
# Gerencia databases, schemas, backups e conexões
# Usage: ./database-helper.sh ou db-help (se instalado)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações padrão
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="dev"
DB_PASSWORD="devpass"
DB_NAME="devdb"
BACKUP_DIR="$HOME/docker-workspace/backups"

# Configurações MLflow
ML_DB_PORT="5433"
ML_DB_USER="mlflow"
ML_DB_PASSWORD="mlflow123"
ML_DB_NAME="mlflow"

# Verificar se PostgreSQL está rodando
check_postgres() {
    if ! docker ps | grep -q "dev-postgres\|ml-postgres"; then
        echo -e "${RED}❌ PostgreSQL não está rodando${NC}"
        echo -e "${CYAN}💡 Inicie um ambiente primeiro:${NC}"
        echo -e "${YELLOW}   start-python  # Para dev-postgres${NC}"
        echo -e "${YELLOW}   start-ds      # Para ml-postgres${NC}"
        exit 1
    fi
}

# Executar comando SQL
run_sql() {
    local sql="$1"
    local db_name="${2:-$DB_NAME}"
    local port="${3:-$DB_PORT}"
    local user="${4:-$DB_USER}"
    local password="${5:-$DB_PASSWORD}"
    
    PGPASSWORD="$password" psql -h "$DB_HOST" -p "$port" -U "$user" -d "$db_name" -c "$sql" 2>/dev/null
}

# Executar comando SQL via Docker
run_sql_docker() {
    local sql="$1"
    local container="$2"
    local db_name="${3:-$DB_NAME}"
    
    if [ "$container" = "ml-postgres" ]; then
        docker exec -it "$container" psql -U "$ML_DB_USER" -d "$db_name" -c "$sql"
    else
        docker exec -it "$container" psql -U "$DB_USER" -d "$db_name" -c "$sql"
    fi
}

# Header
show_header() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                  🗄️  DATABASE HELPER                         ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Status dos bancos
    echo -e "${CYAN}📊 Status PostgreSQL:${NC}"
    if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
        echo -e "${GREEN}✅ Dev PostgreSQL ativo (port 5432)${NC}"
    else
        echo -e "${YELLOW}⏸️  Dev PostgreSQL parado${NC}"
    fi
    
    if docker ps --format "{{.Names}}" | grep -q "ml-postgres"; then
        echo -e "${GREEN}✅ ML PostgreSQL ativo (port 5433)${NC}"
    else
        echo -e "${YELLOW}⏸️  ML PostgreSQL parado${NC}"
    fi
    echo ""
}

# Menu principal
show_main_menu() {
    echo -e "${BLUE}═══════════════════ MENU PRINCIPAL ═══════════════════${NC}"
    echo -e "${YELLOW}1.${NC}  📊 Status & Info"
    echo -e "${YELLOW}2.${NC}  🗄️  Databases & Schemas"
    echo -e "${YELLOW}3.${NC}  📋 Tables & Data"
    echo -e "${YELLOW}4.${NC}  🔗 Conexões & psql"
    echo -e "${YELLOW}5.${NC}  💾 Backup & Restore"
    echo -e "${YELLOW}6.${NC}  🧹 Cleanup & Maintenance"
    echo -e "${YELLOW}7.${NC}  📈 Monitoring & Performance"
    echo -e "${YELLOW}8.${NC}  ⚙️  Configuration"
    echo -e "${YELLOW}0.${NC}  ❌ Sair"
    echo ""
    echo -ne "${PURPLE}Escolha uma opção [0-8]: ${NC}"
}

# 1. Status & Info
status_info() {
    clear
    echo -e "${BLUE}📊 DATABASE STATUS & INFORMAÇÕES${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
    
    # Verificar containers
    local dev_running=$(docker ps --format "{{.Names}}" | grep "dev-postgres" | wc -l)
    local ml_running=$(docker ps --format "{{.Names}}" | grep "ml-postgres" | wc -l)
    
    if [ $dev_running -eq 0 ] && [ $ml_running -eq 0 ]; then
        echo -e "${RED}❌ Nenhum PostgreSQL ativo${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    echo -e "${CYAN}🐳 Containers PostgreSQL:${NC}"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep postgres
    echo ""
    
    # Dev PostgreSQL info
    if [ $dev_running -gt 0 ]; then
        echo -e "${CYAN}📊 Dev PostgreSQL (port 5432):${NC}"
        echo -e "${YELLOW}Connection: postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME${NC}"
        
        # Listar databases
        echo -e "${CYAN}Databases:${NC}"
        run_sql_docker "\l" "dev-postgres" "postgres" 2>/dev/null | grep -E "^\s+\w+" | head -10
        
        # Estatísticas
        local db_count=$(run_sql_docker "SELECT count(*) FROM pg_database WHERE datistemplate = false;" "dev-postgres" "postgres" 2>/dev/null | grep -E "^\s+[0-9]+" | tr -d ' ')
        echo -e "${CYAN}Total databases: ${YELLOW}$db_count${NC}"
        echo ""
    fi
    
    # ML PostgreSQL info
    if [ $ml_running -gt 0 ]; then
        echo -e "${CYAN}📊 ML PostgreSQL (port 5433):${NC}"
        echo -e "${YELLOW}Connection: postgresql://$ML_DB_USER:$ML_DB_PASSWORD@$DB_HOST:$ML_DB_PORT/$ML_DB_NAME${NC}"
        echo -e "${CYAN}Usado por: MLflow, experimentos ML${NC}"
        echo ""
    fi
    
    # Uso de disco
    echo -e "${CYAN}💾 Uso de disco:${NC}"
    if [ -d "$HOME/docker-workspace/volumes/postgres-data" ]; then
        local dev_size=$(du -sh "$HOME/docker-workspace/volumes/postgres-data" 2>/dev/null | cut -f1)
        echo -e "${CYAN}Dev PostgreSQL: ${YELLOW}$dev_size${NC}"
    fi
    if [ -d "$HOME/docker-workspace/volumes/ml-postgres-data" ]; then
        local ml_size=$(du -sh "$HOME/docker-workspace/volumes/ml-postgres-data" 2>/dev/null | cut -f1)
        echo -e "${CYAN}ML PostgreSQL: ${YELLOW}$ml_size${NC}"
    fi
    
    read -p "Pressione Enter para continuar..."
}

# 2. Databases & Schemas
manage_databases() {
    clear
    echo -e "${BLUE}🗄️  GERENCIAMENTO DE DATABASES & SCHEMAS${NC}"
    echo -e "${BLUE}=======================================${NC}"
    echo ""
    
    # Escolher instância
    echo -e "${CYAN}Escolha a instância PostgreSQL:${NC}"
    echo -e "${YELLOW}1.${NC} Dev PostgreSQL (port 5432)"
    echo -e "${YELLOW}2.${NC} ML PostgreSQL (port 5433)"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-2]: ${NC}"
    
    read instance_choice
    
    local container=""
    local port=""
    local user=""
    local password=""
    
    case $instance_choice in
        1)
            container="dev-postgres"
            port="$DB_PORT"
            user="$DB_USER"
            password="$DB_PASSWORD"
            ;;
        2)
            container="ml-postgres"
            port="$ML_DB_PORT"
            user="$ML_DB_USER"
            password="$ML_DB_PASSWORD"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}❌ Opção inválida${NC}"
            read -p "Pressione Enter..."
            return
            ;;
    esac
    
    # Verificar se container está rodando
    if ! docker ps --format "{{.Names}}" | grep -q "$container"; then
        echo -e "${RED}❌ Container $container não está rodando${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    clear
    echo -e "${BLUE}🗄️  DATABASES & SCHEMAS - $container${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    # Listar databases existentes
    echo -e "${CYAN}📋 Databases existentes:${NC}"
    run_sql_docker "\l" "$container" "postgres" 2>/dev/null | grep -E "^\s+\w+" | head -10
    echo ""
    
    echo -e "${YELLOW}1.${NC} 🆕 Criar novo database"
    echo -e "${YELLOW}2.${NC} 🆕 Criar novo schema"
    echo -e "${YELLOW}3.${NC} 📋 Listar schemas de um database"
    echo -e "${YELLOW}4.${NC} 🗑️  Deletar database"
    echo -e "${YELLOW}5.${NC} 🗑️  Deletar schema"
    echo -e "${YELLOW}6.${NC} 🔄 Criar database para projeto"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-6]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Nome do novo database:${NC}"
            read db_name
            if [ -n "$db_name" ]; then
                run_sql_docker "CREATE DATABASE $db_name;" "$container" "postgres"
                echo -e "${GREEN}✅ Database '$db_name' criado${NC}"
                echo -e "${CYAN}Conexão: postgresql://$user:$password@localhost:$port/$db_name${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Nome do database onde criar schema:${NC}"
            read target_db
            echo -e "${CYAN}Nome do novo schema:${NC}"
            read schema_name
            if [ -n "$target_db" ] && [ -n "$schema_name" ]; then
                run_sql_docker "CREATE SCHEMA $schema_name;" "$container" "$target_db"
                echo -e "${GREEN}✅ Schema '$schema_name' criado no database '$target_db'${NC}"
            fi
            ;;
        3)
            echo -e "${CYAN}Nome do database:${NC}"
            read target_db
            if [ -n "$target_db" ]; then
                echo -e "${CYAN}📋 Schemas no database '$target_db':${NC}"
                run_sql_docker "SELECT schema_name FROM information_schema.schemata;" "$container" "$target_db"
            fi
            ;;
        4)
            echo -e "${CYAN}Nome do database para deletar:${NC}"
            read db_name
            echo -e "${RED}⚠️ ATENÇÃO: Isso deletará TODOS os dados do database '$db_name'!${NC}"
            echo -e "${YELLOW}Confirma? (digite 'DELETAR' para confirmar):${NC}"
            read confirm
            if [ "$confirm" = "DELETAR" ]; then
                run_sql_docker "DROP DATABASE $db_name;" "$container" "postgres"
                echo -e "${GREEN}✅ Database '$db_name' deletado${NC}"
            else
                echo -e "${YELLOW}⏭️ Operação cancelada${NC}"
            fi
            ;;
        5)
            echo -e "${CYAN}Nome do database:${NC}"
            read target_db
            echo -e "${CYAN}Nome do schema para deletar:${NC}"
            read schema_name
            echo -e "${RED}⚠️ ATENÇÃO: Isso deletará TODOS os dados do schema '$schema_name'!${NC}"
            echo -e "${YELLOW}Confirma? (digite 'DELETAR' para confirmar):${NC}"
            read confirm
            if [ "$confirm" = "DELETAR" ]; then
                run_sql_docker "DROP SCHEMA $schema_name CASCADE;" "$container" "$target_db"
                echo -e "${GREEN}✅ Schema '$schema_name' deletado${NC}"
            else
                echo -e "${YELLOW}⏭️ Operação cancelada${NC}"
            fi
            ;;
        6)
            echo -e "${CYAN}Nome do projeto:${NC}"
            read project_name
            if [ -n "$project_name" ]; then
                # Criar database
                local db_name="${project_name}_db"
                run_sql_docker "CREATE DATABASE $db_name;" "$container" "postgres"
                
                # Criar schema
                run_sql_docker "CREATE SCHEMA $project_name;" "$container" "$db_name"
                
                echo -e "${GREEN}✅ Setup completo para projeto '$project_name':${NC}"
                echo -e "${CYAN}Database: $db_name${NC}"
                echo -e "${CYAN}Schema: $project_name${NC}"
                echo -e "${CYAN}Conexão: postgresql://$user:$password@localhost:$port/$db_name${NC}"
                echo -e "${CYAN}Use em queries: $project_name.tabela${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

# 3. Tables & Data
manage_tables() {
    clear
    echo -e "${BLUE}📋 GERENCIAMENTO DE TABLES & DATA${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
    
    # Escolher container
    echo -e "${CYAN}Escolha PostgreSQL:${NC}"
    echo -e "${YELLOW}1.${NC} Dev PostgreSQL"
    echo -e "${YELLOW}2.${NC} ML PostgreSQL"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-2]: ${NC}"
    
    read instance_choice
    
    local container=""
    case $instance_choice in
        1) container="dev-postgres" ;;
        2) container="ml-postgres" ;;
        0) return ;;
        *) echo -e "${RED}❌ Opção inválida${NC}"; read -p "Pressione Enter..."; return ;;
    esac
    
    echo -e "${CYAN}Nome do database:${NC}"
    read target_db
    if [ -z "$target_db" ]; then
        target_db="$DB_NAME"
    fi
    
    clear
    echo -e "${BLUE}📋 TABLES & DATA - $container/$target_db${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 📋 Listar todas as tabelas"
    echo -e "${YELLOW}2.${NC} 🔍 Descrever estrutura de tabela"
    echo -e "${YELLOW}3.${NC} 📊 Ver dados de tabela (LIMIT 10)"
    echo -e "${YELLOW}4.${NC} 📈 Estatísticas de tabela"
    echo -e "${YELLOW}5.${NC} 💾 Executar SQL personalizado"
    echo -e "${YELLOW}6.${NC} 📤 Exportar tabela para CSV"
    echo -e "${YELLOW}7.${NC} 🗑️  Limpar dados de tabela"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-7]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}📋 Tabelas no database '$target_db':${NC}"
            run_sql_docker "SELECT tablename FROM pg_tables WHERE schemaname = 'public';" "$container" "$target_db"
            ;;
        2)
            echo -e "${CYAN}Nome da tabela:${NC}"
            read table_name
            if [ -n "$table_name" ]; then
                echo -e "${CYAN}📊 Estrutura da tabela '$table_name':${NC}"
                run_sql_docker "\d $table_name" "$container" "$target_db"
            fi
            ;;
        3)
            echo -e "${CYAN}Nome da tabela:${NC}"
            read table_name
            if [ -n "$table_name" ]; then
                echo -e "${CYAN}📊 Dados da tabela '$table_name' (primeiras 10 linhas):${NC}"
                run_sql_docker "SELECT * FROM $table_name LIMIT 10;" "$container" "$target_db"
            fi
            ;;
        4)
            echo -e "${CYAN}Nome da tabela:${NC}"
            read table_name
            if [ -n "$table_name" ]; then
                echo -e "${CYAN}📈 Estatísticas da tabela '$table_name':${NC}"
                run_sql_docker "SELECT COUNT(*) as total_rows FROM $table_name;" "$container" "$target_db"
                run_sql_docker "SELECT pg_size_pretty(pg_total_relation_size('$table_name')) as table_size;" "$container" "$target_db"
            fi
            ;;
        5)
            echo -e "${CYAN}Digite o comando SQL:${NC}"
            read sql_command
            if [ -n "$sql_command" ]; then
                echo -e "${CYAN}🔍 Executando SQL:${NC}"
                run_sql_docker "$sql_command" "$container" "$target_db"
            fi
            ;;
        6)
            echo -e "${CYAN}Nome da tabela:${NC}"
            read table_name
            if [ -n "$table_name" ]; then
                local output_file="$HOME/docker-workspace/backups/${table_name}_$(date +%Y%m%d_%H%M%S).csv"
                mkdir -p "$(dirname "$output_file")"
                echo -e "${CYAN}📤 Exportando para $output_file...${NC}"
                run_sql_docker "\copy $table_name TO '/tmp/export.csv' WITH CSV HEADER;" "$container" "$target_db"
                docker cp "$container:/tmp/export.csv" "$output_file"
                echo -e "${GREEN}✅ Tabela exportada: $output_file${NC}"
            fi
            ;;
        7)
            echo -e "${CYAN}Nome da tabela:${NC}"
            read table_name
            echo -e "${RED}⚠️ ATENÇÃO: Isso deletará TODOS os dados da tabela '$table_name'!${NC}"
            echo -e "${YELLOW}Confirma? (digite 'LIMPAR' para confirmar):${NC}"
            read confirm
            if [ "$confirm" = "LIMPAR" ]; then
                run_sql_docker "TRUNCATE TABLE $table_name;" "$container" "$target_db"
                echo -e "${GREEN}✅ Dados da tabela '$table_name' removidos${NC}"
            else
                echo -e "${YELLOW}⏭️ Operação cancelada${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

# 4. Conexões & psql
manage_connections() {
    clear
    echo -e "${BLUE}🔗 CONEXÕES & PSQL${NC}"
    echo -e "${BLUE}==================${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 💻 Conectar via psql (Dev PostgreSQL)"
    echo -e "${YELLOW}2.${NC} 💻 Conectar via psql (ML PostgreSQL)"
    echo -e "${YELLOW}3.${NC} 📋 Mostrar strings de conexão"
    echo -e "${YELLOW}4.${NC} 🧪 Testar conexão"
    echo -e "${YELLOW}5.${NC} 📊 Mostrar conexões ativas"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${CYAN}🔗 Conectando ao Dev PostgreSQL...${NC}"
                echo -e "${YELLOW}Para sair: \q${NC}"
                docker exec -it dev-postgres psql -U "$DB_USER" -d "$DB_NAME"
            else
                echo -e "${RED}❌ Dev PostgreSQL não está rodando${NC}"
            fi
            ;;
        2)
            if docker ps --format "{{.Names}}" | grep -q "ml-postgres"; then
                echo -e "${CYAN}🔗 Conectando ao ML PostgreSQL...${NC}"
                echo -e "${YELLOW}Para sair: \q${NC}"
                docker exec -it ml-postgres psql -U "$ML_DB_USER" -d "$ML_DB_NAME"
            else
                echo -e "${RED}❌ ML PostgreSQL não está rodando${NC}"
            fi
            ;;
        3)
            echo -e "${CYAN}📋 STRINGS DE CONEXÃO:${NC}"
            echo ""
            echo -e "${YELLOW}Dev PostgreSQL:${NC}"
            echo -e "${CYAN}URL: postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME${NC}"
            echo -e "${CYAN}Host: $DB_HOST${NC}"
            echo -e "${CYAN}Port: $DB_PORT${NC}"
            echo -e "${CYAN}Database: $DB_NAME${NC}"
            echo -e "${CYAN}User: $DB_USER${NC}"
            echo -e "${CYAN}Password: $DB_PASSWORD${NC}"
            echo ""
            echo -e "${YELLOW}ML PostgreSQL:${NC}"
            echo -e "${CYAN}URL: postgresql://$ML_DB_USER:$ML_DB_PASSWORD@$DB_HOST:$ML_DB_PORT/$ML_DB_NAME${NC}"
            echo -e "${CYAN}Host: $DB_HOST${NC}"
            echo -e "${CYAN}Port: $ML_DB_PORT${NC}"
            echo -e "${CYAN}Database: $ML_DB_NAME${NC}"
            echo -e "${CYAN}User: $ML_DB_USER${NC}"
            echo -e "${CYAN}Password: $ML_DB_PASSWORD${NC}"
            ;;
        4)
            echo -e "${CYAN}🧪 Testando conexões...${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                if run_sql_docker "SELECT 1;" "dev-postgres" "$DB_NAME" >/dev/null 2>&1; then
                    echo -e "${GREEN}✅ Dev PostgreSQL: Conexão OK${NC}"
                else
                    echo -e "${RED}❌ Dev PostgreSQL: Falha na conexão${NC}"
                fi
            else
                echo -e "${YELLOW}⏸️  Dev PostgreSQL: Container parado${NC}"
            fi
            
            if docker ps --format "{{.Names}}" | grep -q "ml-postgres"; then
                if run_sql_docker "SELECT 1;" "ml-postgres" "$ML_DB_NAME" >/dev/null 2>&1; then
                    echo -e "${GREEN}✅ ML PostgreSQL: Conexão OK${NC}"
                else
                    echo -e "${RED}❌ ML PostgreSQL: Falha na conexão${NC}"
                fi
            else
                echo -e "${YELLOW}⏸️  ML PostgreSQL: Container parado${NC}"
            fi
            ;;
        5)
            echo -e "${CYAN}📊 CONEXÕES ATIVAS:${NC}"
            echo ""
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${YELLOW}Dev PostgreSQL:${NC}"
                run_sql_docker "SELECT pid, usename, application_name, client_addr, state FROM pg_stat_activity WHERE state = 'active';" "dev-postgres" "$DB_NAME"
            fi
            echo ""
            if docker ps --format "{{.Names}}" | grep -q "ml-postgres"; then
                echo -e "${YELLOW}ML PostgreSQL:${NC}"
                run_sql_docker "SELECT pid, usename, application_name, client_addr, state FROM pg_stat_activity WHERE state = 'active';" "ml-postgres" "$ML_DB_NAME"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

# 5. Backup & Restore
manage_backups() {
    clear
    echo -e "${BLUE}💾 BACKUP & RESTORE${NC}"
    echo -e "${BLUE}==================${NC}"
    echo ""
    
    # Criar diretório de backup
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${CYAN}📁 Diretório de backups: $BACKUP_DIR${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 💾 Backup database completo"
    echo -e "${YELLOW}2.${NC} 📥 Restore database"
    echo -e "${YELLOW}3.${NC} 💾 Backup tabela específica"
    echo -e "${YELLOW}4.${NC} 📋 Listar backups existentes"
    echo -e "${YELLOW}5.${NC} 🗑️  Deletar backup antigo"
    echo -e "${YELLOW}6.${NC} 🔄 Backup automático de todos os databases"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-6]: ${NC}"
    
    read choice
    case $choice in
        1)
            # Escolher instância
            echo -e "${CYAN}Escolha PostgreSQL:${NC}"
            echo -e "${YELLOW}1.${NC} Dev PostgreSQL"
            echo -e "${YELLOW}2.${NC} ML PostgreSQL"
            echo -ne "${PURPLE}Escolha [1-2]: ${NC}"
            read instance
            
            local container=""
            local user=""
            case $instance in
                1) container="dev-postgres"; user="$DB_USER" ;;
                2) container="ml-postgres"; user="$ML_DB_USER" ;;
                *) echo -e "${RED}❌ Opção inválida${NC}"; read -p "Pressione Enter..."; return ;;
            esac
            
            echo -e "${CYAN}Nome do database:${NC}"
            read db_name
            
            if [ -n "$db_name" ] && docker ps --format "{{.Names}}" | grep -q "$container"; then
                local backup_file="$BACKUP_DIR/${db_name}_$(date +%Y%m%d_%H%M%S).sql"
                echo -e "${CYAN}💾 Criando backup de '$db_name'...${NC}"
                
                docker exec "$container" pg_dump -U "$user" "$db_name" > "$backup_file"
                
                if [ -f "$backup_file" ]; then
                    local size=$(du -sh "$backup_file" | cut -f1)
                    echo -e "${GREEN}✅ Backup criado: $backup_file ($size)${NC}"
                else
                    echo -e "${RED}❌ Erro ao criar backup${NC}"
                fi
            fi
            ;;
        2)
            echo -e "${CYAN}📋 Backups disponíveis:${NC}"
            ls -la "$BACKUP_DIR"/*.sql 2>/dev/null | awk '{print $9, $5, $6, $7, $8}' | while read file size date time; do
                if [ -n "$file" ]; then
                    echo -e "  $(basename "$file") ($size bytes)"
                fi
            done
            echo ""
            echo -e "${CYAN}Nome do arquivo de backup (sem caminho):${NC}"
            read backup_file
            
            if [ -f "$BACKUP_DIR/$backup_file" ]; then
                echo -e "${CYAN}Escolha PostgreSQL:${NC}"
                echo -e "${YELLOW}1.${NC} Dev PostgreSQL"
                echo -e "${YELLOW}2.${NC} ML PostgreSQL"
                echo -ne "${PURPLE}Escolha [1-2]: ${NC}"
                read instance
                
                local container=""
                local user=""
                case $instance in
                    1) container="dev-postgres"; user="$DB_USER" ;;
                    2) container="ml-postgres"; user="$ML_DB_USER" ;;
                    *) echo -e "${RED}❌ Opção inválida${NC}"; read -p "Pressione Enter..."; return ;;
                esac
                
                echo -e "${CYAN}Nome do database destino:${NC}"
                read target_db
                
                echo -e "${RED}⚠️ ATENÇÃO: Isso sobrescreverá o database '$target_db'!${NC}"
                echo -e "${YELLOW}Confirma? (y/N):${NC}"
                read -n 1 confirm
                echo
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${CYAN}📥 Restaurando backup...${NC}"
                    docker cp "$BACKUP_DIR/$backup_file" "$container:/tmp/restore.sql"
                    docker exec "$container" psql -U "$user" -d "$target_db" -f /tmp/restore.sql
                    echo -e "${GREEN}✅ Backup restaurado em '$target_db'${NC}"
                else
                    echo -e "${YELLOW}⏭️ Operação cancelada${NC}"
                fi
            else
                echo -e "${RED}❌ Arquivo de backup não encontrado${NC}"
            fi
            ;;
        3)
            echo -e "${CYAN}Escolha PostgreSQL:${NC}"
            echo -e "${YELLOW}1.${NC} Dev PostgreSQL"
            echo -e "${YELLOW}2.${NC} ML PostgreSQL"
            echo -ne "${PURPLE}Escolha [1-2]: ${NC}"
            read instance
            
            local container=""
            case $instance in
                1) container="dev-postgres" ;;
                2) container="ml-postgres" ;;
                *) echo -e "${RED}❌ Opção inválida${NC}"; read -p "Pressione Enter..."; return ;;
            esac
            
            echo -e "${CYAN}Nome do database:${NC}"
            read db_name
            echo -e "${CYAN}Nome da tabela:${NC}"
            read table_name
            
            if [ -n "$db_name" ] && [ -n "$table_name" ]; then
                local backup_file="$BACKUP_DIR/${table_name}_$(date +%Y%m%d_%H%M%S).csv"
                echo -e "${CYAN}💾 Exportando tabela '$table_name'...${NC}"
                
                run_sql_docker "\copy $table_name TO '/tmp/table_backup.csv' WITH CSV HEADER;" "$container" "$db_name"
                docker cp "$container:/tmp/table_backup.csv" "$backup_file"
                
                if [ -f "$backup_file" ]; then
                    local size=$(du -sh "$backup_file" | cut -f1)
                    echo -e "${GREEN}✅ Tabela exportada: $backup_file ($size)${NC}"
                else
                    echo -e "${RED}❌ Erro ao exportar tabela${NC}"
                fi
            fi
            ;;
        4)
            echo -e "${CYAN}📋 BACKUPS EXISTENTES:${NC}"
            echo ""
            if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
                ls -lah "$BACKUP_DIR" | grep -v "^total\|^d"
            else
                echo -e "${YELLOW}📁 Nenhum backup encontrado${NC}"
            fi
            ;;
        5)
            echo -e "${CYAN}📋 Backups para deletar:${NC}"
            ls -la "$BACKUP_DIR"/*.sql "$BACKUP_DIR"/*.csv 2>/dev/null | awk '{print NR ": " $9}' 
            echo ""
            echo -e "${CYAN}Nome do arquivo para deletar:${NC}"
            read file_to_delete
            
            if [ -f "$BACKUP_DIR/$file_to_delete" ]; then
                echo -e "${YELLOW}Confirma deleção de '$file_to_delete'? (y/N):${NC}"
                read -n 1 confirm
                echo
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    rm "$BACKUP_DIR/$file_to_delete"
                    echo -e "${GREEN}✅ Backup deletado${NC}"
                else
                    echo -e "${YELLOW}⏭️ Operação cancelada${NC}"
                fi
            else
                echo -e "${RED}❌ Arquivo não encontrado${NC}"
            fi
            ;;
        6)
            echo -e "${CYAN}🔄 Backup automático de todos os databases...${NC}"
            
            # Backup Dev PostgreSQL
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${CYAN}📦 Backup Dev PostgreSQL...${NC}"
                local databases=$(run_sql_docker "SELECT datname FROM pg_database WHERE datistemplate = false;" "dev-postgres" "postgres" | grep -v "datname\|---\|row")
                
                while IFS= read -r db; do
                    if [ -n "$db" ] && [[ ! "$db" =~ ^[[:space:]]*$ ]]; then
                        db=$(echo "$db" | tr -d ' ')
                        local backup_file="$BACKUP_DIR/auto_${db}_$(date +%Y%m%d_%H%M%S).sql"
                        docker exec dev-postgres pg_dump -U "$DB_USER" "$db" > "$backup_file" 2>/dev/null
                        if [ -f "$backup_file" ]; then
                            echo -e "${GREEN}  ✅ $db${NC}"
                        fi
                    fi
                done <<< "$databases"
            fi
            
            # Backup ML PostgreSQL
            if docker ps --format "{{.Names}}" | grep -q "ml-postgres"; then
                echo -e "${CYAN}📦 Backup ML PostgreSQL...${NC}"
                local backup_file="$BACKUP_DIR/auto_mlflow_$(date +%Y%m%d_%H%M%S).sql"
                docker exec ml-postgres pg_dump -U "$ML_DB_USER" "$ML_DB_NAME" > "$backup_file" 2>/dev/null
                if [ -f "$backup_file" ]; then
                    echo -e "${GREEN}  ✅ mlflow${NC}"
                fi
            fi
            
            echo -e "${GREEN}✅ Backup automático concluído${NC}"
            ;;
        0)
            return
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

# 6. Cleanup & Maintenance
cleanup_maintenance() {
    clear
    echo -e "${BLUE}🧹 CLEANUP & MAINTENANCE${NC}"
    echo -e "${BLUE}========================${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 🧹 VACUUM databases"
    echo -e "${YELLOW}2.${NC} 📊 ANALYZE tables"
    echo -e "${YELLOW}3.${NC} 🗑️  Limpar logs antigos"
    echo -e "${YELLOW}4.${NC} 📈 Reindex databases"
    echo -e "${YELLOW}5.${NC} 🔍 Verificar integridade"
    echo -e "${YELLOW}6.${NC} 📊 Estatísticas de uso"
    echo -e "${YELLOW}7.${NC} 🗑️  Limpar backups antigos (>30 dias)"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-7]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}🧹 Executando VACUUM em todos os databases...${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${CYAN}Dev PostgreSQL:${NC}"
                run_sql_docker "VACUUM;" "dev-postgres" "$DB_NAME"
                echo -e "${GREEN}✅ VACUUM concluído${NC}"
            fi
            
            if docker ps --format "{{.Names}}" | grep -q "ml-postgres"; then
                echo -e "${CYAN}ML PostgreSQL:${NC}"
                run_sql_docker "VACUUM;" "ml-postgres" "$ML_DB_NAME"
                echo -e "${GREEN}✅ VACUUM concluído${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}📊 Executando ANALYZE em todos os databases...${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${CYAN}Dev PostgreSQL:${NC}"
                run_sql_docker "ANALYZE;" "dev-postgres" "$DB_NAME"
                echo -e "${GREEN}✅ ANALYZE concluído${NC}"
            fi
            
            if docker ps --format "{{.Names}}" | grep -q "ml-postgres"; then
                echo -e "${CYAN}ML PostgreSQL:${NC}"
                run_sql_docker "ANALYZE;" "ml-postgres" "$ML_DB_NAME"
                echo -e "${GREEN}✅ ANALYZE concluído${NC}"
            fi
            ;;
        3)
            echo -e "${CYAN}🗑️ Limpando logs do PostgreSQL...${NC}"
            # Limpar logs dentro dos containers
            docker exec dev-postgres sh -c "find /var/log -name '*.log' -mtime +7 -delete" 2>/dev/null || true
            docker exec ml-postgres sh -c "find /var/log -name '*.log' -mtime +7 -delete" 2>/dev/null || true
            echo -e "${GREEN}✅ Logs antigos removidos${NC}"
            ;;
        4)
            echo -e "${CYAN}📈 Executando REINDEX...${NC}"
            echo -e "${YELLOW}⚠️ Isso pode demorar para databases grandes${NC}"
            echo -e "${YELLOW}Continuar? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                    echo -e "${CYAN}Dev PostgreSQL:${NC}"
                    run_sql_docker "REINDEX DATABASE $DB_NAME;" "dev-postgres" "$DB_NAME"
                    echo -e "${GREEN}✅ REINDEX concluído${NC}"
                fi
            fi
            ;;
        5)
            echo -e "${CYAN}🔍 Verificando integridade dos databases...${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${CYAN}Dev PostgreSQL:${NC}"
                local corrupted=$(run_sql_docker "SELECT COUNT(*) FROM pg_stat_database WHERE datname = '$DB_NAME';" "dev-postgres" "$DB_NAME" | grep -o '[0-9]*')
                if [ "$corrupted" = "1" ]; then
                    echo -e "${GREEN}✅ Database íntegro${NC}"
                else
                    echo -e "${RED}❌ Possível corrupção detectada${NC}"
                fi
            fi
            ;;
        6)
            echo -e "${CYAN}📊 ESTATÍSTICAS DE USO:${NC}"
            echo ""
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${YELLOW}Dev PostgreSQL:${NC}"
                echo -e "${CYAN}Databases:${NC}"
                run_sql_docker "SELECT datname, pg_size_pretty(pg_database_size(datname)) as size FROM pg_database WHERE datistemplate = false;" "dev-postgres" "postgres"
                echo ""
                echo -e "${CYAN}Top 5 tabelas maiores:${NC}"
                run_sql_docker "SELECT schemaname,tablename,pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 5;" "dev-postgres" "$DB_NAME"
            fi
            ;;
        7)
            echo -e "${CYAN}🗑️ Limpando backups antigos (>30 dias)...${NC}"
            local deleted=$(find "$BACKUP_DIR" -name "*.sql" -o -name "*.csv" -mtime +30 -delete -print | wc -l)
            echo -e "${GREEN}✅ $deleted backups antigos removidos${NC}"
            ;;
        0)
            return
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

# 7. Monitoring & Performance
monitoring_performance() {
    clear
    echo -e "${BLUE}📈 MONITORING & PERFORMANCE${NC}"
    echo -e "${BLUE}============================${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 📊 Status em tempo real"
    echo -e "${YELLOW}2.${NC} 🔥 Queries mais lentas"
    echo -e "${YELLOW}3.${NC} 💾 Uso de memória"
    echo -e "${YELLOW}4.${NC} 🔗 Conexões ativas"
    echo -e "${YELLOW}5.${NC} 📈 Estatísticas de I/O"
    echo -e "${YELLOW}6.${NC} 🚨 Locks e bloqueios"
    echo -e "${YELLOW}7.${NC} 📊 Configurações principais"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-7]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}📊 STATUS EM TEMPO REAL:${NC}"
            echo ""
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${YELLOW}Dev PostgreSQL:${NC}"
                run_sql_docker "SELECT pid, usename, application_name, state, query_start, left(query, 50) as query FROM pg_stat_activity WHERE state != 'idle' ORDER BY query_start;" "dev-postgres" "$DB_NAME"
            fi
            
            if docker ps --format "{{.Names}}" | grep -q "ml-postgres"; then
                echo -e "${YELLOW}ML PostgreSQL:${NC}"
                run_sql_docker "SELECT pid, usename, application_name, state, query_start, left(query, 50) as query FROM pg_stat_activity WHERE state != 'idle' ORDER BY query_start;" "ml-postgres" "$ML_DB_NAME"
            fi
            ;;
        2)
            echo -e "${CYAN}🔥 QUERIES MAIS LENTAS:${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${YELLOW}Dev PostgreSQL:${NC}"
                run_sql_docker "SELECT query, calls, total_time, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;" "dev-postgres" "$DB_NAME" 2>/dev/null || echo "pg_stat_statements não habilitado"
            fi
            ;;
        3)
            echo -e "${CYAN}💾 USO DE MEMÓRIA:${NC}"
            
            echo -e "${YELLOW}Container Stats:${NC}"
            docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep postgres
            ;;
        4)
            echo -e "${CYAN}🔗 CONEXÕES ATIVAS:${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${YELLOW}Dev PostgreSQL:${NC}"
                run_sql_docker "SELECT count(*) as total_connections, state FROM pg_stat_activity GROUP BY state;" "dev-postgres" "$DB_NAME"
            fi
            ;;
        5)
            echo -e "${CYAN}📈 ESTATÍSTICAS DE I/O:${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${YELLOW}Dev PostgreSQL:${NC}"
                run_sql_docker "SELECT datname, blks_read, blks_hit, blk_read_time, blk_write_time FROM pg_stat_database WHERE datname = '$DB_NAME';" "dev-postgres" "$DB_NAME"
            fi
            ;;
        6)
            echo -e "${CYAN}🚨 LOCKS E BLOQUEIOS:${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${YELLOW}Dev PostgreSQL:${NC}"
                run_sql_docker "SELECT pid, mode, locktype, relation::regclass, page, tuple FROM pg_locks WHERE granted = false;" "dev-postgres" "$DB_NAME"
            fi
            ;;
        7)
            echo -e "${CYAN}📊 CONFIGURAÇÕES PRINCIPAIS:${NC}"
            
            if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                echo -e "${YELLOW}Dev PostgreSQL:${NC}"
                run_sql_docker "SELECT name, setting, unit FROM pg_settings WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'max_connections', 'checkpoint_timeout');" "dev-postgres" "$DB_NAME"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

# 8. Configuration
manage_configuration() {
    clear
    echo -e "${BLUE}⚙️  CONFIGURAÇÃO${NC}"
    echo -e "${BLUE}================${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 📋 Mostrar configurações atuais"
    echo -e "${YELLOW}2.${NC} 🔧 Alterar configurações de conexão"
    echo -e "${YELLOW}3.${NC} 📁 Mostrar diretórios"
    echo -e "${YELLOW}4.${NC} 🎯 Configurar ambiente para projeto"
    echo -e "${YELLOW}5.${NC} 🔄 Reset configurações padrão"
    echo -e "${YELLOW}0.${NC} ↩️  Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}📋 CONFIGURAÇÕES ATUAIS:${NC}"
            echo ""
            echo -e "${YELLOW}Dev PostgreSQL:${NC}"
            echo -e "${CYAN}Host: $DB_HOST${NC}"
            echo -e "${CYAN}Port: $DB_PORT${NC}"
            echo -e "${CYAN}User: $DB_USER${NC}"
            echo -e "${CYAN}Password: $DB_PASSWORD${NC}"
            echo -e "${CYAN}Database: $DB_NAME${NC}"
            echo ""
            echo -e "${YELLOW}ML PostgreSQL:${NC}"
            echo -e "${CYAN}Host: $DB_HOST${NC}"
            echo -e "${CYAN}Port: $ML_DB_PORT${NC}"
            echo -e "${CYAN}User: $ML_DB_USER${NC}"
            echo -e "${CYAN}Password: $ML_DB_PASSWORD${NC}"
            echo -e "${CYAN}Database: $ML_DB_NAME${NC}"
            echo ""
            echo -e "${YELLOW}Diretórios:${NC}"
            echo -e "${CYAN}Backups: $BACKUP_DIR${NC}"
            echo -e "${CYAN}Workspace: $HOME/docker-workspace${NC}"
            ;;
        2)
            echo -e "${CYAN}🔧 Alterar configurações (para esta sessão):${NC}"
            echo ""
            echo -e "${CYAN}Host atual [$DB_HOST]:${NC}"
            read new_host
            if [ -n "$new_host" ]; then
                DB_HOST="$new_host"
            fi
            
            echo -e "${CYAN}Port Dev atual [$DB_PORT]:${NC}"
            read new_port
            if [ -n "$new_port" ]; then
                DB_PORT="$new_port"
            fi
            
            echo -e "${GREEN}✅ Configurações atualizadas para esta sessão${NC}"
            ;;
        3)
            echo -e "${CYAN}📁 DIRETÓRIOS DO SISTEMA:${NC}"
            echo ""
            echo -e "${YELLOW}Volumes Docker:${NC}"
            echo -e "${CYAN}Dev PostgreSQL: $HOME/docker-workspace/volumes/postgres-data${NC}"
            echo -e "${CYAN}ML PostgreSQL: $HOME/docker-workspace/volumes/ml-postgres-data${NC}"
            echo ""
            echo -e "${YELLOW}Backups:${NC}"
            echo -e "${CYAN}Diretório: $BACKUP_DIR${NC}"
            if [ -d "$BACKUP_DIR" ]; then
                local backup_count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
                local backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
                echo -e "${CYAN}Arquivos: $backup_count${NC}"
                echo -e "${CYAN}Tamanho: $backup_size${NC}"
            else
                echo -e "${YELLOW}Diretório não existe${NC}"
            fi
            ;;
        4)
            echo -e "${CYAN}🎯 Configurar ambiente para projeto:${NC}"
            echo ""
            echo -e "${CYAN}Nome do projeto:${NC}"
            read project_name
            
            if [ -n "$project_name" ]; then
                echo -e "${CYAN}Tipo de projeto:${NC}"
                echo -e "${YELLOW}1.${NC} Web App (Node.js/Python)"
                echo -e "${YELLOW}2.${NC} Data Science/ML"
                echo -e "${YELLOW}3.${NC} Full-Stack"
                echo -ne "${PURPLE}Escolha [1-3]: ${NC}"
                read project_type
                
                local db_name="${project_name}_db"
                local schema_name="$project_name"
                
                case $project_type in
                    1)
                        echo -e "${CYAN}📋 Configuração Web App:${NC}"
                        echo -e "${YELLOW}Usar Dev PostgreSQL (port 5432)${NC}"
                        if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                            run_sql_docker "CREATE DATABASE $db_name;" "dev-postgres" "postgres" 2>/dev/null
                            run_sql_docker "CREATE SCHEMA $schema_name;" "dev-postgres" "$db_name" 2>/dev/null
                            echo -e "${GREEN}✅ Database '$db_name' criado${NC}"
                            echo -e "${CYAN}Conexão: postgresql://$DB_USER:$DB_PASSWORD@localhost:$DB_PORT/$db_name${NC}"
                        fi
                        ;;
                    2)
                        echo -e "${CYAN}📋 Configuração Data Science:${NC}"
                        echo -e "${YELLOW}Usar ML PostgreSQL (port 5433) + MLflow${NC}"
                        echo -e "${CYAN}MLflow já configurado${NC}"
                        echo -e "${CYAN}Conexão: postgresql://$ML_DB_USER:$ML_DB_PASSWORD@localhost:$ML_DB_PORT/$ML_DB_NAME${NC}"
                        ;;
                    3)
                        echo -e "${CYAN}📋 Configuração Full-Stack:${NC}"
                        echo -e "${YELLOW}Backend: Dev PostgreSQL${NC}"
                        echo -e "${YELLOW}Frontend: Node.js${NC}"
                        if docker ps --format "{{.Names}}" | grep -q "dev-postgres"; then
                            run_sql_docker "CREATE DATABASE $db_name;" "dev-postgres" "postgres" 2>/dev/null
                            echo -e "${GREEN}✅ Database '$db_name' criado${NC}"
                            echo -e "${CYAN}Backend: postgresql://$DB_USER:$DB_PASSWORD@localhost:$DB_PORT/$db_name${NC}"
                            echo -e "${CYAN}Frontend: http://localhost:3000${NC}"
                        fi
                        ;;
                esac
                
                # Criar arquivo de configuração
                local config_file="$HOME/docker-workspace/${project_name}-db-config.env"
                cat > "$config_file" << EOF
# Database configuration for $project_name
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:$DB_PORT/$db_name
DB_HOST=localhost
DB_PORT=$DB_PORT
DB_NAME=$db_name
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
EOF
                echo -e "${GREEN}✅ Arquivo de configuração criado: $config_file${NC}"
            fi
            ;;
        5)
            echo -e "${CYAN}🔄 Resetando para configurações padrão...${NC}"
            DB_HOST="localhost"
            DB_PORT="5432"
            DB_USER="dev"
            DB_PASSWORD="devpass"
            DB_NAME="devdb"
            echo -e "${GREEN}✅ Configurações resetadas${NC}"
            ;;
        0)
            return
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

# Loop principal
main() {
    check_postgres
    
    while true; do
        show_header
        show_main_menu
        
        read choice
        case $choice in
            1) status_info ;;
            2) manage_databases ;;
            3) manage_tables ;;
            4) manage_connections ;;
            5) manage_backups ;;
            6) cleanup_maintenance ;;
            7) monitoring_performance ;;
            8) manage_configuration ;;
            0) 
                echo -e "${GREEN}🗄️ Até mais!${NC}"
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
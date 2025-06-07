#!/bin/bash

# Fedora Post-Install Docker-First Edition - VERSÃO COM PORTAS INTELIGENTES
# Sistema mínimo + Containers para TUDO - COM DETECÇÃO AUTOMÁTICA DE PORTAS
# Execute como usuário normal após fedora-setup.sh

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="$HOME/.fedora-post-install-docker.log"

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

check_docker() {
    if ! command_exists docker; then
        echo -e "${RED}❌ Docker não encontrado. Execute fedora-setup.sh primeiro${NC}"
        exit 1
    fi
    
    if ! docker ps >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Adicionando usuário ao grupo docker...${NC}"
        sudo usermod -aG docker $USER
        echo -e "${RED}🔄 NECESSÁRIO LOGOUT/LOGIN para usar Docker${NC}"
        echo -e "${CYAN}Após logout/login, execute novamente este script${NC}"
        exit 1
    fi
}

# ============================================================================
# FUNÇÕES PARA DETECÇÃO INTELIGENTE DE PORTAS
# ============================================================================

# Função para encontrar porta livre
find_free_port() {
    local start_port=$1
    local port=$start_port
    
    while netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; do
        ((port++))
    done
    
    echo $port
}

# Função para verificar múltiplas portas e retornar a configuração
get_smart_ports() {
    local service_name="$1"
    
    case "$service_name" in
        "nodejs")
            local port_dev=$(find_free_port 3000)
            local port_vite=$(find_free_port 5173)
            local port_alt=$(find_free_port 8080)
            echo "$port_dev,$port_vite,$port_alt"
            ;;
        "python")
            local port_api=$(find_free_port 8000)
            local port_flask=$(find_free_port 5000)
            local port_streamlit=$(find_free_port 8501)
            local port_pg=$(find_free_port 5432)
            local port_redis=$(find_free_port 6380)
            echo "$port_api,$port_flask,$port_streamlit,$port_pg,$port_redis"
            ;;
        "datascience")
            local port_jupyter=$(find_free_port 8888)
            local port_mlflow=$(find_free_port 5555)
            local port_pg=$(find_free_port 5433)
            echo "$port_jupyter,$port_mlflow,$port_pg"
            ;;
        *)
            echo "3000,5173,8080"
            ;;
    esac
}

# Sistema mínimo para testes rápidos
setup_minimal_system() {
    echo -e "${BLUE}⚡ Configurando sistema mínimo...${NC}"
    log_message "=== CONFIGURAÇÃO SISTEMA MÍNIMO ==="
    
    # NVM para Node.js (testes rápidos)
    if [ ! -d "$HOME/.nvm" ]; then
        echo -e "${CYAN}📦 Instalando NVM...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm alias default node
        log_message "✓ NVM e Node.js LTS instalados"
    fi
    
    # Python tools mínimos
    echo -e "${CYAN}🐍 Instalando Python tools básicos...${NC}"
    pip3 install --user --upgrade \
        pipx \
        cookiecutter \
        httpie \
        rich \
        ipython \
        black \
        flake8 \
        pytest
    
    log_message "✓ Sistema mínimo configurado"
}

# Estrutura Docker completa
setup_docker_workspace() {
    echo -e "${BLUE}🐳 Criando workspace Docker completo...${NC}"
    log_message "=== CRIANDO WORKSPACE DOCKER ==="
    
    # Estrutura
    mkdir -p "$HOME/docker-workspace"/{nodejs,python-web,datascience,databases,configs,volumes,compose-files,scripts}
    
    # Obter portas inteligentes para cada serviço
    echo -e "${CYAN}🔍 Detectando portas disponíveis...${NC}"
    
    local nodejs_ports=$(get_smart_ports "nodejs")
    local nodejs_dev=$(echo $nodejs_ports | cut -d',' -f1)
    local nodejs_vite=$(echo $nodejs_ports | cut -d',' -f2)
    local nodejs_alt=$(echo $nodejs_ports | cut -d',' -f3)
    
    local python_ports=$(get_smart_ports "python")
    local python_api=$(echo $python_ports | cut -d',' -f1)
    local python_flask=$(echo $python_ports | cut -d',' -f2)
    local python_streamlit=$(echo $python_ports | cut -d',' -f3)
    local python_pg=$(echo $python_ports | cut -d',' -f4)
    local python_redis=$(echo $python_ports | cut -d',' -f5)
    
    local ds_ports=$(get_smart_ports "datascience")
    local ds_jupyter=$(echo $ds_ports | cut -d',' -f1)
    local ds_mlflow=$(echo $ds_ports | cut -d',' -f2)
    local ds_pg=$(echo $ds_ports | cut -d',' -f3)
    
    echo -e "${GREEN}✅ Portas selecionadas:${NC}"
    echo -e "${CYAN}   Node.js: $nodejs_dev, $nodejs_vite, $nodejs_alt${NC}"
    echo -e "${CYAN}   Python: $python_api, $python_flask, $python_streamlit${NC}"
    echo -e "${CYAN}   Data Science: $ds_jupyter, $ds_mlflow${NC}"
    
    # Compose Node.js com portas dinâmicas
    cat > "$HOME/docker-workspace/compose-files/nodejs-dev.yml" << EOF
version: '3.8'
services:
  nodejs-dev:
    image: node:20-alpine
    container_name: nodejs-dev
    working_dir: /workspace
    volumes:
      - ../nodejs:/workspace
      - ../volumes/node_modules:/workspace/node_modules
    ports:
      - "$nodejs_dev:3000"
      - "$nodejs_vite:5173"
      - "$nodejs_alt:8080"
      - "3001:3001"
    command: sleep infinity
    stdin_open: true
    tty: true
    environment:
      - NODE_ENV=development
    networks:
      - dev-network

  redis:
    image: redis:7-alpine
    container_name: dev-redis
    ports:
      - "6379:6379"
    volumes:
      - ../volumes/redis-data:/data
    networks:
      - dev-network

networks:
  dev-network:
    driver: bridge
EOF

    # Compose Python Web com portas dinâmicas
    cat > "$HOME/docker-workspace/compose-files/python-web.yml" << EOF
version: '3.8'
services:
  python-web:
    image: python:3.11-slim
    container_name: python-web
    working_dir: /workspace
    volumes:
      - ../python-web:/workspace
      - ../volumes/pip-cache:/root/.cache/pip
    ports:
      - "$python_api:8000"
      - "$python_flask:5000"
      - "$python_streamlit:8501"
    command: sleep infinity
    stdin_open: true
    tty: true
    environment:
      - PYTHONUNBUFFERED=1
      - PYTHONDONTWRITEBYTECODE=1
    depends_on:
      - postgres
      - redis
    networks:
      - dev-network

  postgres:
    image: postgres:15-alpine
    container_name: dev-postgres
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    ports:
      - "$python_pg:5432"
    volumes:
      - ../volumes/postgres-data:/var/lib/postgresql/data
    networks:
      - dev-network

  redis:
    image: redis:7-alpine
    container_name: dev-redis-web
    ports:
      - "$python_redis:6379"
    volumes:
      - ../volumes/redis-web-data:/data
    networks:
      - dev-network

networks:
  dev-network:
    driver: bridge
EOF

    # Compose Data Science com portas dinâmicas
    cat > "$HOME/docker-workspace/compose-files/datascience.yml" << EOF
version: '3.8'
services:
  jupyter:
    image: jupyter/tensorflow-notebook:latest
    container_name: jupyter-lab
    working_dir: /home/jovyan/work
    volumes:
      - ../datascience:/home/jovyan/work
      - ../volumes/jupyter-config:/home/jovyan/.jupyter
    ports:
      - "$ds_jupyter:8888"
      - "6006:6006"
    environment:
      - JUPYTER_ENABLE_LAB=yes
      - JUPYTER_TOKEN=dev123
    user: root
    command: >
      bash -c "
        pip install --no-cache-dir \
          plotly dash streamlit \
          xgboost lightgbm catboost \
          optuna hyperopt \
          shap lime \
          mlflow wandb \
          geopandas folium \
          wordcloud \
          scikit-image \
          opencv-python \
          seaborn plotly \
          sqlalchemy psycopg2-binary \
          redis \
          fastapi uvicorn &&
        fix-permissions /home/jovyan &&
        start-notebook.sh --NotebookApp.token='dev123' --NotebookApp.password=''
      "
    networks:
      - dev-network

  mlflow:
    image: python:3.11-slim
    container_name: mlflow-server
    working_dir: /workspace
    volumes:
      - ../datascience:/workspace
      - ../volumes/mlflow-artifacts:/mlflow-artifacts
    ports:
      - "$ds_mlflow:5000"
    environment:
      - MLFLOW_BACKEND_STORE_URI=postgresql://mlflow:mlflow123@ml-postgres:5432/mlflow
      - MLFLOW_DEFAULT_ARTIFACT_ROOT=/mlflow-artifacts
    command: >
      bash -c "
        pip install mlflow[extras] psycopg2-binary &&
        sleep 10 &&
        mlflow server --host 0.0.0.0 --port 5000
      "
    depends_on:
      - ml-postgres
    networks:
      - dev-network

  ml-postgres:
    image: postgres:15-alpine
    container_name: ml-postgres
    environment:
      POSTGRES_DB: mlflow
      POSTGRES_USER: mlflow
      POSTGRES_PASSWORD: mlflow123
    ports:
      - "$ds_pg:5432"
    volumes:
      - ../volumes/ml-postgres-data:/var/lib/postgresql/data
    networks:
      - dev-network

networks:
  dev-network:
    driver: bridge
EOF

    # Salvar configuração de portas
    cat > "$HOME/docker-workspace/configs/ports.conf" << EOF
# Configuração de Portas - Gerada automaticamente
NODEJS_DEV_PORT=$nodejs_dev
NODEJS_VITE_PORT=$nodejs_vite
NODEJS_ALT_PORT=$nodejs_alt

PYTHON_API_PORT=$python_api
PYTHON_FLASK_PORT=$python_flask
PYTHON_STREAMLIT_PORT=$python_streamlit
PYTHON_POSTGRES_PORT=$python_pg
PYTHON_REDIS_PORT=$python_redis

DATASCIENCE_JUPYTER_PORT=$ds_jupyter
DATASCIENCE_MLFLOW_PORT=$ds_mlflow
DATASCIENCE_POSTGRES_PORT=$ds_pg
EOF

    log_message "✓ Docker Compose files criados com portas inteligentes"
}

# Scripts de conveniência com portas dinâmicas
create_convenience_scripts() {
    echo -e "${BLUE}📜 Criando scripts de conveniência com portas inteligentes...${NC}"
    
    # Carregar configuração de portas
    source "$HOME/docker-workspace/configs/ports.conf"
    
    # Start Node.js
    cat > "$HOME/docker-workspace/scripts/start-nodejs.sh" << EOF
#!/bin/bash
cd ~/docker-workspace/compose-files
echo "🚀 Iniciando ambiente Node.js com portas inteligentes..."
docker-compose -f nodejs-dev.yml up -d
echo ""
echo "✅ Ambiente Node.js ativo!"
echo "📂 Workspace: ~/docker-workspace/nodejs/"
echo "🔗 Acesso: docker exec -it nodejs-dev sh"
echo "🌐 Portas detectadas automaticamente:"
echo "   Main: http://localhost:$NODEJS_DEV_PORT"
echo "   Vite: http://localhost:$NODEJS_VITE_PORT" 
echo "   Alt:  http://localhost:$NODEJS_ALT_PORT"
echo ""
echo "💡 Comandos rápidos:"
echo "   docker exec -it nodejs-dev npm create vite@latest my-app"
echo "   docker exec -it nodejs-dev npx create-react-app my-app"
echo "   docker exec -it nodejs-dev npm create svelte@latest my-app"
EOF

    # Start Python
    cat > "$HOME/docker-workspace/scripts/start-python.sh" << EOF
#!/bin/bash
cd ~/docker-workspace/compose-files
echo "🐍 Iniciando ambiente Python Web com portas inteligentes..."
docker-compose -f python-web.yml up -d
echo ""
echo "✅ Ambiente Python ativo!"
echo "📂 Workspace: ~/docker-workspace/python-web/"
echo "🔗 Acesso: docker exec -it python-web bash"
echo "🌐 Portas detectadas automaticamente:"
echo "   FastAPI:    http://localhost:$PYTHON_API_PORT"
echo "   Flask:      http://localhost:$PYTHON_FLASK_PORT"
echo "   Streamlit:  http://localhost:$PYTHON_STREAMLIT_PORT"
echo "🗄️ Databases:"
echo "   PostgreSQL: localhost:$PYTHON_POSTGRES_PORT (dev/devpass/devdb)"
echo "   Redis:      localhost:$PYTHON_REDIS_PORT"
echo ""
echo "💡 Comandos rápidos:"
echo "   docker exec -it python-web pip install fastapi uvicorn"
echo "   docker exec -it python-web pip install django djangorestframework"
echo "   docker exec -it python-web pip install streamlit"
EOF

    # Start Data Science
    cat > "$HOME/docker-workspace/scripts/start-datascience.sh" << EOF
#!/bin/bash
cd ~/docker-workspace/compose-files

# Verificar GPU
if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
    echo "🚀 GPU NVIDIA detectada!"
    # Substituir imagem por versão GPU
    sed -i 's/jupyter\/tensorflow-notebook:latest/tensorflow\/tensorflow:latest-gpu-jupyter/' datascience.yml
    echo "   Usando imagem com suporte GPU"
else
    echo "💻 Modo CPU apenas"
fi

echo "🔬 Iniciando ambiente Data Science com portas inteligentes..."
docker-compose -f datascience.yml up -d

echo ""
echo "✅ Ambiente Data Science ativo!"
echo "📂 Workspace: ~/docker-workspace/datascience/"
echo "🌐 Portas detectadas automaticamente:"
echo "   Jupyter Lab: http://localhost:$DATASCIENCE_JUPYTER_PORT (token: dev123)"
echo "   MLflow:      http://localhost:$DATASCIENCE_MLFLOW_PORT"
echo "🗄️ PostgreSQL: localhost:$DATASCIENCE_POSTGRES_PORT (mlflow/mlflow123/mlflow)"
echo ""
echo "💡 Primeiro acesso:"
echo "   1. Abra http://localhost:$DATASCIENCE_JUPYTER_PORT"
echo "   2. Token: dev123"
echo "   3. Crie um novo notebook"
EOF

    # Stop all
    cat > "$HOME/docker-workspace/scripts/stop-all.sh" << 'EOF'
#!/bin/bash
cd ~/docker-workspace/compose-files
echo "⏹️ Parando todos os ambientes..."
docker-compose -f nodejs-dev.yml down 2>/dev/null
docker-compose -f python-web.yml down 2>/dev/null
docker-compose -f datascience.yml down 2>/dev/null
echo "✅ Todos os ambientes parados"
EOF

    # Status com portas dinâmicas
    cat > "$HOME/docker-workspace/scripts/status.sh" << EOF
#!/bin/bash
# Carregar configuração de portas
source ~/docker-workspace/configs/ports.conf

echo "📊 STATUS DOS AMBIENTES - PORTAS INTELIGENTES"
echo "=============================================="
echo ""
echo "🐳 Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "(nodejs-dev|python-web|jupyter-lab|dev-postgres|dev-redis|mlflow)"
echo ""
echo "🌐 Serviços disponíveis (portas auto-detectadas):"
echo "   Node.js Dev:     \$NODEJS_DEV_PORT, \$NODEJS_VITE_PORT, \$NODEJS_ALT_PORT"
echo "   Python Web:      FastAPI (\$PYTHON_API_PORT), Flask (\$PYTHON_FLASK_PORT), Streamlit (\$PYTHON_STREAMLIT_PORT)"
echo "   Data Science:    Jupyter (\$DATASCIENCE_JUPYTER_PORT), MLflow (\$DATASCIENCE_MLFLOW_PORT)"
echo "   Bancos:          PostgreSQL (\$PYTHON_POSTGRES_PORT/\$DATASCIENCE_POSTGRES_PORT), Redis (\$PYTHON_REDIS_PORT)"
echo ""
echo "🔧 Portas atuais:"
echo "   Node.js: $NODEJS_DEV_PORT, $NODEJS_VITE_PORT, $NODEJS_ALT_PORT"
echo "   Python:  $PYTHON_API_PORT, $PYTHON_FLASK_PORT, $PYTHON_STREAMLIT_PORT"
echo "   DS:      $DATASCIENCE_JUPYTER_PORT, $DATASCIENCE_MLFLOW_PORT"
EOF

    chmod +x "$HOME/docker-workspace/scripts/"*.sh
    log_message "✓ Scripts de conveniência criados com portas inteligentes"
}

# Templates de projeto
create_project_templates() {
    echo -e "${BLUE}📁 Criando templates...${NC}"
    
    # Carregar configuração de portas
    source "$HOME/docker-workspace/configs/ports.conf"
    
    # FastAPI template
    mkdir -p "$HOME/docker-workspace/python-web/fastapi-template"
    cat > "$HOME/docker-workspace/python-web/fastapi-template/main.py" << EOF
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os

app = FastAPI(title="FastAPI Template", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {
        "message": "Hello FastAPI!", 
        "status": "running",
        "port": os.getenv("PORT", $PYTHON_API_PORT)
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", $PYTHON_API_PORT)), reload=True)
EOF

    cat > "$HOME/docker-workspace/python-web/fastapi-template/requirements.txt" << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
redis==5.0.1
python-multipart==0.0.6
pydantic==2.5.0
requests==2.31.0
python-dotenv==1.0.0
EOF

    # React template package.json
    mkdir -p "$HOME/docker-workspace/nodejs/react-template"
    cat > "$HOME/docker-workspace/nodejs/react-template/package.json" << 'EOF'
{
  "name": "react-template",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^4.0.0"
  }
}
EOF

    # Data Science notebook template
    mkdir -p "$HOME/docker-workspace/datascience/notebooks"
    cat > "$HOME/docker-workspace/datascience/notebooks/template_analysis.ipynb" << EOF
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 📊 Template de Análise de Dados\\n",
    "\\n",
    "**MLflow**: http://localhost:$DATASCIENCE_MLFLOW_PORT\\n",
    "**Jupyter**: http://localhost:$DATASCIENCE_JUPYTER_PORT\\n",
    "\\n",
    "## 1. Setup e Imports"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Imports essenciais\\n",
    "import pandas as pd\\n",
    "import numpy as np\\n",
    "import matplotlib.pyplot as plt\\n",
    "import seaborn as sns\\n",
    "import plotly.express as px\\n",
    "import plotly.graph_objects as go\\n",
    "\\n",
    "# Configurações\\n",
    "plt.style.use('seaborn-v0_8')\\n",
    "sns.set_palette('husl')\\n",
    "pd.set_option('display.max_columns', None)\\n",
    "pd.set_option('display.max_rows', 100)\\n",
    "\\n",
    "# MLflow\\n",
    "import mlflow\\n",
    "mlflow.set_tracking_uri('http://mlflow-server:5000')\\n",
    "mlflow.set_experiment('default')\\n",
    "\\n",
    "print(\\\"✅ Setup completo!\\\")\\n",
    "print(f\\\"🧪 MLflow: http://localhost:$DATASCIENCE_MLFLOW_PORT\\\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 2. Carregamento de Dados"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Exemplo de conexão PostgreSQL\\n",
    "from sqlalchemy import create_engine\\n",
    "\\n",
    "# engine = create_engine('postgresql://mlflow:mlflow123@ml-postgres:5432/mlflow')\\n",
    "# df = pd.read_sql('SELECT * FROM table', engine)\\n",
    "\\n",
    "# Para CSV\\n",
    "# df = pd.read_csv('data.csv')\\n",
    "\\n",
    "print(\\\"📁 Pronto para carregar dados\\\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.11.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    log_message "✓ Templates criados com portas inteligentes"
}

# Função principal
main() {
    case "$1" in
        "all")
            check_not_root
            check_docker
            setup_minimal_system
            setup_docker_workspace
            create_convenience_scripts
            create_project_templates
            
            echo -e "${GREEN}🎉 CONFIGURAÇÃO DOCKER-FIRST COM PORTAS INTELIGENTES CONCLUÍDA!${NC}"
            echo -e "${PURPLE}=================================================================${NC}"
            echo ""
            
            # Carregar e mostrar portas configuradas
            source "$HOME/docker-workspace/configs/ports.conf"
            
            echo -e "${BLUE}📁 ESTRUTURA:${NC}"
            echo -e "${CYAN}~/docker-workspace/nodejs/       ${NC}→ Projetos Node.js/React/Vue"
            echo -e "${CYAN}~/docker-workspace/python-web/   ${NC}→ APIs Python (FastAPI/Django)"
            echo -e "${CYAN}~/docker-workspace/datascience/  ${NC}→ ML, Data Science, Notebooks"
            echo ""
            echo -e "${BLUE}🚀 COMANDOS PRINCIPAIS:${NC}"
            echo -e "${YELLOW}~/docker-workspace/scripts/start-nodejs.sh      ${NC}→ Ambiente Node.js completo"
            echo -e "${YELLOW}~/docker-workspace/scripts/start-python.sh      ${NC}→ Ambiente Python Web + DB"
            echo -e "${YELLOW}~/docker-workspace/scripts/start-datascience.sh ${NC}→ Jupyter Lab + MLflow + GPU"
            echo -e "${YELLOW}~/docker-workspace/scripts/status.sh            ${NC}→ Status de todos ambientes"
            echo -e "${YELLOW}~/docker-workspace/scripts/stop-all.sh          ${NC}→ Parar todos containers"
            echo ""
            echo -e "${BLUE}🌐 PORTAS INTELIGENTES CONFIGURADAS:${NC}"
            echo -e "${GREEN}• Node.js:${NC} $NODEJS_DEV_PORT, $NODEJS_VITE_PORT, $NODEJS_ALT_PORT"
            echo -e "${GREEN}• Python Web:${NC} FastAPI ($PYTHON_API_PORT), Flask ($PYTHON_FLASK_PORT), Streamlit ($PYTHON_STREAMLIT_PORT)"
            echo -e "${GREEN}• Data Science:${NC} Jupyter ($DATASCIENCE_JUPYTER_PORT), MLflow ($DATASCIENCE_MLFLOW_PORT)"
            echo -e "${GREEN}• Databases:${NC} PostgreSQL ($PYTHON_POSTGRES_PORT/$DATASCIENCE_POSTGRES_PORT), Redis ($PYTHON_REDIS_PORT)"
            echo ""
            echo -e "${RED}🔥 TESTE RÁPIDO:${NC}"
            echo -e "${CYAN}1. Execute: ~/docker-workspace/scripts/start-datascience.sh${NC}"
            echo -e "${CYAN}2. Abra: http://localhost:$DATASCIENCE_JUPYTER_PORT${NC}"
            echo -e "${CYAN}3. Token: dev123${NC}"
            echo -e "${CYAN}4. Teste o template notebook${NC}"
            echo ""
            echo -e "${PURPLE}🎯 VANTAGENS DAS PORTAS INTELIGENTES:${NC}"
            echo -e "${CYAN}• ✅ Zero conflitos de porta${NC}"
            echo -e "${CYAN}• ✅ Múltiplos ambientes simultâneos${NC}"
            echo -e "${CYAN}• ✅ Detecção automática de portas livres${NC}"
            echo -e "${CYAN}• ✅ Configuração salva em ~/docker-workspace/configs/ports.conf${NC}"
            ;;
        *)
            echo -e "${PURPLE}🐳 Fedora Post-Install Docker-First Edition - PORTAS INTELIGENTES${NC}"
            echo -e "${CYAN}Sistema com detecção automática de portas para evitar conflitos${NC}"
            echo ""
            echo -e "${YELLOW}Uso: $0 all${NC}"
            echo ""
            echo -e "${GREEN}✨ NOVO: Detecção inteligente de portas!${NC}"
            echo -e "${CYAN}• Detecta portas ocupadas automaticamente${NC}"
            echo -e "${CYAN}• Configura cada serviço com porta livre${NC}"
            echo -e "${CYAN}• Salva configuração para reutilização${NC}"
            echo -e "${CYAN}• Scripts ajustam portas dinamicamente${NC}"
            exit 1
            ;;
    esac
}

main "$@"
#!/bin/bash

# Fedora Post-Install Docker-First Edition - VERSÃO CORRIGIDA
# Sistema mínimo + Containers para TUDO - SEM ALIASES DUPLICADOS
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
    
    # Compose Node.js
    cat > "$HOME/docker-workspace/compose-files/nodejs-dev.yml" << 'EOF'
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
      - "3000:3000"
      - "5173:5173"
      - "8080:8080"
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

    # Compose Python Web
    cat > "$HOME/docker-workspace/compose-files/python-web.yml" << 'EOF'
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
      - "8000:8000"
      - "5000:5000"
      - "8501:8501"
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
      - "5432:5432"
    volumes:
      - ../volumes/postgres-data:/var/lib/postgresql/data
    networks:
      - dev-network

  redis:
    image: redis:7-alpine
    container_name: dev-redis-web
    ports:
      - "6380:6379"
    volumes:
      - ../volumes/redis-web-data:/data
    networks:
      - dev-network

networks:
  dev-network:
    driver: bridge
EOF

    # Compose Data Science
    cat > "$HOME/docker-workspace/compose-files/datascience.yml" << 'EOF'
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
      - "8888:8888"
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
      - "5555:5000"
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
      - "5433:5432"
    volumes:
      - ../volumes/ml-postgres-data:/var/lib/postgresql/data
    networks:
      - dev-network

networks:
  dev-network:
    driver: bridge
EOF

    log_message "✓ Docker Compose files criados"
}

# Scripts de conveniência
create_convenience_scripts() {
    echo -e "${BLUE}📜 Criando scripts de conveniência...${NC}"
    
    # Start Node.js
    cat > "$HOME/docker-workspace/scripts/start-nodejs.sh" << 'EOF'
#!/bin/bash
cd ~/docker-workspace/compose-files
echo "🚀 Iniciando ambiente Node.js..."
docker-compose -f nodejs-dev.yml up -d
echo ""
echo "✅ Ambiente Node.js ativo!"
echo "📂 Workspace: ~/docker-workspace/nodejs/"
echo "🔗 Acesso: docker exec -it nodejs-dev sh"
echo "🌐 Portas: 3000, 5173 (Vite), 8080"
echo ""
echo "💡 Comandos rápidos:"
echo "   docker exec -it nodejs-dev npm create vite@latest my-app"
echo "   docker exec -it nodejs-dev npx create-react-app my-app"
echo "   docker exec -it nodejs-dev npm create svelte@latest my-app"
EOF

    # Start Python
    cat > "$HOME/docker-workspace/scripts/start-python.sh" << 'EOF'
#!/bin/bash
cd ~/docker-workspace/compose-files
echo "🐍 Iniciando ambiente Python Web..."
docker-compose -f python-web.yml up -d
echo ""
echo "✅ Ambiente Python ativo!"
echo "📂 Workspace: ~/docker-workspace/python-web/"
echo "🔗 Acesso: docker exec -it python-web bash"
echo "🌐 Portas: 8000 (FastAPI), 5000 (Flask), 8501 (Streamlit)"
echo "🗄️ PostgreSQL: localhost:5432 (dev/devpass/devdb)"
echo ""
echo "💡 Comandos rápidos:"
echo "   docker exec -it python-web pip install fastapi uvicorn"
echo "   docker exec -it python-web pip install django djangorestframework"
echo "   docker exec -it python-web pip install streamlit"
EOF

    # Start Data Science
    cat > "$HOME/docker-workspace/scripts/start-datascience.sh" << 'EOF'
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

echo "🔬 Iniciando ambiente Data Science..."
docker-compose -f datascience.yml up -d

echo ""
echo "✅ Ambiente Data Science ativo!"
echo "📂 Workspace: ~/docker-workspace/datascience/"
echo "📊 Jupyter Lab: http://localhost:8888 (token: dev123)"
echo "🧪 MLflow: http://localhost:5555"
echo "🗄️ PostgreSQL: localhost:5433 (mlflow/mlflow123/mlflow)"
echo ""
echo "💡 Primeiro acesso:"
echo "   1. Abra http://localhost:8888"
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

    # Status
    cat > "$HOME/docker-workspace/scripts/status.sh" << 'EOF'
#!/bin/bash
echo "📊 STATUS DOS AMBIENTES"
echo "======================="
echo ""
echo "🐳 Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "(nodejs-dev|python-web|jupyter-lab|dev-postgres|dev-redis|mlflow)"
echo ""
echo "🌐 Serviços disponíveis:"
echo "   Node.js: Containers disponíveis nas portas 3000, 5173, 8080"
echo "   Python Web: FastAPI (8000), Flask (5000), Streamlit (8501)"
echo "   Data Science: Jupyter (8888), MLflow (5555)"
echo "   Bancos: PostgreSQL (5432/5433), Redis (6379/6380)"
EOF

    chmod +x "$HOME/docker-workspace/scripts/"*.sh
    log_message "✓ Scripts de conveniência criados"
}

# Templates de projeto
create_project_templates() {
    echo -e "${BLUE}📁 Criando templates...${NC}"
    
    # FastAPI template
    mkdir -p "$HOME/docker-workspace/python-web/fastapi-template"
    cat > "$HOME/docker-workspace/python-web/fastapi-template/main.py" << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

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
    return {"message": "Hello FastAPI!", "status": "running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
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
    cat > "$HOME/docker-workspace/datascience/notebooks/template_analysis.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 📊 Template de Análise de Dados\n",
    "\n",
    "## 1. Setup e Imports"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Imports essenciais\n",
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "import plotly.express as px\n",
    "import plotly.graph_objects as go\n",
    "\n",
    "# Configurações\n",
    "plt.style.use('seaborn-v0_8')\n",
    "sns.set_palette('husl')\n",
    "pd.set_option('display.max_columns', None)\n",
    "pd.set_option('display.max_rows', 100)\n",
    "\n",
    "# MLflow\n",
    "import mlflow\n",
    "mlflow.set_tracking_uri('http://mlflow-server:5000')\n",
    "mlflow.set_experiment('default')\n",
    "\n",
    "print(\"✅ Setup completo!\")"
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
    "# Exemplo de conexão PostgreSQL\n",
    "from sqlalchemy import create_engine\n",
    "\n",
    "# engine = create_engine('postgresql://mlflow:mlflow123@ml-postgres:5432/mlflow')\n",
    "# df = pd.read_sql('SELECT * FROM table', engine)\n",
    "\n",
    "# Para CSV\n",
    "# df = pd.read_csv('data.csv')\n",
    "\n",
    "print(\"📁 Pronto para carregar dados\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 3. Análise Exploratória"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# df.info()\n",
    "# df.describe()\n",
    "# df.head()"
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

    log_message "✓ Templates criados"
}

# VS Code configuração
setup_vscode() {
    echo -e "${BLUE}📝 Configurando VS Code...${NC}"
    
    # Extensões essenciais
    local extensions=(
        "ms-python.python"
        "ms-python.black-formatter"
        "ms-toolsai.jupyter"
        "ms-vscode.vscode-typescript-next"
        "bradlc.vscode-tailwindcss"
        "esbenp.prettier-vscode"
        "ms-vscode-remote.remote-containers"
        "ms-azuretools.vscode-docker"
        "eamodio.gitlens"
        "ms-vscode.remote-explorer"
        "redhat.vscode-yaml"
        "ms-vscode.vscode-json"
        "charliermarsh.ruff"
    )
    
    for extension in "${extensions[@]}"; do
        if ! code --list-extensions | grep -q "^$extension$"; then
            code --install-extension "$extension" >/dev/null 2>&1 || true
        fi
    done
    
    # Configurações VS Code
    mkdir -p "$HOME/.config/Code/User"
    cat > "$HOME/.config/Code/User/settings.json" << 'EOF'
{
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.terminal.activateEnvironment": false,
    "jupyter.askForKernelRestart": false,
    "jupyter.alwaysTrustNotebooks": true,
    "docker.showStartPage": false,
    "files.associations": {
        "*.yml": "yaml",
        "docker-compose*.yml": "yaml"
    },
    "workbench.colorTheme": "Dark+ (default dark)",
    "editor.formatOnSave": true,
    "python.formatting.provider": "none",
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "[python]": {
        "editor.defaultFormatter": "ms-python.black-formatter"
    },
    "remote.containers.showAdvanced": true
}
EOF
    
    log_message "✓ VS Code configurado"
}

# Configurar aliases referência (NÃO duplicados)
setup_alias_reference() {
    echo -e "${BLUE}📋 Configurando referência de aliases...${NC}"
    
    # Criar referência de aliases disponíveis
    mkdir -p "$HOME/.config/shell"
    cat > "$HOME/.config/shell/aliases-reference.md" << 'EOF'
# 📋 Aliases Disponíveis

## ⚠️ ALIASES DEFINIDOS EM OUTROS ARQUIVOS
Este script NÃO define aliases para evitar duplicação.

## 📁 Localização dos Aliases:
- **Git aliases**: eza_aliases.sh, zsh-setup.sh
- **Docker aliases**: zsh-setup.sh  
- **Node.js aliases**: node_aliases.sh, zsh-setup.sh
- **Python aliases**: python_aliases.sh, zsh-setup.sh
- **File management**: eza_aliases.sh

## 🔧 Para usar aliases:
```bash
# Carregue os arquivos de alias específicos:
source eza_aliases.sh
source node_aliases.sh  
source python_aliases.sh

# Ou configure ZSH que carrega tudo automaticamente:
./zsh-setup.sh install
```

## 💡 Aliases Principais:
- `gs` - git status
- `ga` - git add
- `dps` - docker ps
- `py` - python3
- `ll` - listar arquivos detalhado
EOF
    
    echo -e "${CYAN}📋 Referência de aliases criada em: ~/.config/shell/aliases-reference.md${NC}"
    echo -e "${YELLOW}💡 Este script NÃO define aliases para evitar duplicação${NC}"
    echo -e "${CYAN}Use zsh-setup.sh ou source dos arquivos de alias específicos${NC}"
    
    log_message "✓ Referência de aliases configurada"
}

# Summary final
show_summary() {
    echo -e "${GREEN}🎉 CONFIGURAÇÃO DOCKER-FIRST CONCLUÍDA!${NC}"
    echo -e "${PURPLE}=====================================${NC}"
    echo ""
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
    echo -e "${BLUE}📋 ALIASES:${NC}"
    echo -e "${CYAN}📁 Aliases NÃO definidos aqui para evitar duplicação${NC}"
    echo -e "${CYAN}Use: source eza_aliases.sh node_aliases.sh python_aliases.sh${NC}"
    echo -e "${CYAN}Ou: ./zsh-setup.sh install (carrega tudo automaticamente)${NC}"
    echo ""
    echo -e "${BLUE}📊 SERVIÇOS APÓS INICIAR:${NC}"
    echo -e "${GREEN}• Jupyter Lab:${NC} http://localhost:8888 (token: dev123)"
    echo -e "${GREEN}• MLflow:${NC} http://localhost:5555"
    echo -e "${GREEN}• PostgreSQL:${NC} localhost:5432 (dev) / 5433 (ml)"
    echo -e "${GREEN}• Apps:${NC} 3000, 5000, 8000, 8501"
    echo ""
    echo -e "${RED}🔥 TESTE RÁPIDO:${NC}"
    echo -e "${CYAN}1. Execute: ~/docker-workspace/scripts/start-datascience.sh${NC}"
    echo -e "${CYAN}2. Abra: http://localhost:8888${NC}"
    echo -e "${CYAN}3. Token: dev123${NC}"
    echo -e "${CYAN}4. Teste o template notebook${NC}"
    echo ""
    echo -e "${PURPLE}🎯 PRÓXIMOS PASSOS:${NC}"
    echo -e "${CYAN}• Use CLI scripts para Git/Docker management${NC}"
    echo -e "${CYAN}• Configure SSH com 03-ssh-setup.sh${NC}"
    echo -e "${CYAN}• Configure terminal com zsh-setup.sh para aliases completos${NC}"
}

# Main
main() {
    case "$1" in
        "all")
            check_not_root
            check_docker
            setup_minimal_system
            setup_docker_workspace
            create_convenience_scripts
            create_project_templates
            setup_vscode
            setup_alias_reference
            show_summary
            ;;
        "docker")
            check_not_root && check_docker && setup_docker_workspace && create_convenience_scripts
            ;;
        "vscode")
            check_not_root && setup_vscode
            ;;
        "templates")
            check_not_root && create_project_templates
            ;;
        *)
            echo -e "${PURPLE}🐳 Fedora Post-Install Docker-First Edition - CORRIGIDO${NC}"
            echo -e "${CYAN}Sistema mínimo + Docker para desenvolvimento - SEM ALIASES DUPLICADOS${NC}"
            echo ""
            echo -e "${YELLOW}Uso: $0 {all|docker|vscode|templates}${NC}"
            echo ""
            echo -e "${CYAN}Comandos:${NC}"
            echo -e "${YELLOW}  all${NC}       - Configuração completa (recomendado)"
            echo -e "${YELLOW}  docker${NC}    - Configurar apenas workspace Docker"
            echo -e "${YELLOW}  vscode${NC}    - Configurar apenas VS Code"
            echo -e "${YELLOW}  templates${NC} - Criar apenas templates de projeto"
            echo ""
            echo -e "${GREEN}✨ VERSÃO CORRIGIDA - Sem aliases duplicados!${NC}"
            echo -e "${CYAN}Aliases devem ser carregados de arquivos específicos ou zsh-setup.sh${NC}"
            exit 1
            ;;
    esac
}

main "$@"
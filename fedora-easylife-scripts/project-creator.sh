#!/bin/bash

# Project Creator - Interactive Project Scaffolding
# Cria projetos automaticamente com templates e configurações
# Usage: ./project-creator.sh

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

WORKSPACE_DIR="$HOME/docker-workspace"

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
    echo -e "${PURPLE}║                  🚀 PROJECT CREATOR                          ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📁 Workspace: ${YELLOW}$WORKSPACE_DIR${NC}"
    echo ""
}

# Menu principal
show_main_menu() {
    echo -e "${BLUE}═══════════════════ TIPOS DE PROJETO ═══════════════════${NC}"
    echo -e "${YELLOW}1.${NC}  ⚛️  React App (Vite)"
    echo -e "${YELLOW}2.${NC}  🟢 Node.js API (Express)"
    echo -e "${YELLOW}3.${NC}  ⚡ FastAPI Project"
    echo -e "${YELLOW}4.${NC}  🐍 Django Project"
    echo -e "${YELLOW}5.${NC}  📊 Data Science Project"
    echo -e "${YELLOW}6.${NC}  🌐 Full-Stack (React + FastAPI)"
    echo -e "${YELLOW}7.${NC}  📋 Generic Project"
    echo -e "${YELLOW}0.${NC}  ❌ Sair"
    echo ""
    echo -ne "${PURPLE}Escolha o tipo de projeto [0-7]: ${NC}"
}

# Verificar workspace
check_workspace() {
    if [ ! -d "$WORKSPACE_DIR" ]; then
        print_error "Docker workspace não encontrado"
        print_info "Execute fedora-post-install.sh primeiro"
        print_info "Comando: ./02-fedora-post-install.sh all"
        exit 1
    fi
}

# Função para ler input com default
read_with_default() {
    local prompt="$1"
    local default="$2"
    local result
    
    echo -ne "${CYAN}$prompt${NC}"
    if [ -n "$default" ]; then
        echo -ne " [${YELLOW}$default${NC}]: "
    else
        echo -ne ": "
    fi
    
    read result
    echo "${result:-$default}"
}

# Criar estrutura básica
create_basic_structure() {
    local project_name="$1"
    local project_type="$2"
    local base_dir="$3"
    
    local project_dir="$base_dir/$project_name"
    
    if [ -d "$project_dir" ]; then
        print_error "Projeto '$project_name' já existe"
        return 1
    fi
    
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    # README.md básico
    cat > README.md << EOF
# $project_name

$project_type project created with Project Creator.

## Setup

\`\`\`bash
# TODO: Add setup instructions
\`\`\`

## Usage

\`\`\`bash
# TODO: Add usage instructions
\`\`\`

---
Created: $(date)
EOF

    # .gitignore básico
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
__pycache__/
*.pyc
.env
.venv/
venv/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Build
dist/
build/
*.egg-info/
EOF

    echo "$project_dir"
}

# ============================================================================
# CRIADORES DE PROJETO
# ============================================================================

# 1. React App
create_react_app() {
    print_info "Criando React App..."
    
    local project_name=$(read_with_default "Nome do projeto" "my-react-app")
    
    local project_dir=$(create_basic_structure "$project_name" "React" "$WORKSPACE_DIR/nodejs")
    [ $? -ne 0 ] && return
    
    print_info "Gerando React app via Docker..."
    
    # Criar via container Node.js
    docker run --rm -v "$project_dir:/workspace" -w /workspace node:18-alpine \
        sh -c "npm create vite@latest . -- --template react && npm install" || {
        print_error "Falha ao criar React app"
        return 1
    }
    
    # Script de execução
    cd "$project_dir"
    cat > docker-run.sh << 'EOF'
#!/bin/bash
echo "🚀 Executando React app..."
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 5173:5173 \
  node:18-alpine \
  npm run dev -- --host 0.0.0.0
EOF
    chmod +x docker-run.sh
    
    # Atualizar README
    cat >> README.md << 'EOF'

## Quick Start

```bash
# Via Docker (recomendado)
./docker-run.sh

# Ou local (se tiver Node.js)
npm run dev
```

Access: http://localhost:5173
EOF
    
    print_success "React app criado em: $project_dir"
    print_info "Para executar: cd $project_dir && ./docker-run.sh"
}

# 2. Node.js API
create_nodejs_api() {
    print_info "Criando Node.js API..."
    
    local project_name=$(read_with_default "Nome do projeto" "my-node-api")
    
    local project_dir=$(create_basic_structure "$project_name" "Node.js API" "$WORKSPACE_DIR/nodejs")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # package.json
    cat > package.json << EOF
{
  "name": "$project_name",
  "version": "1.0.0",
  "description": "Node.js API",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

    # Server básico
    cat > index.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from Node.js API!', 
    timestamp: new Date().toISOString() 
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    uptime: process.uptime()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
EOF
    
    # .env template
    cat > .env.example << 'EOF'
PORT=3000
NODE_ENV=development
EOF
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
echo "🚀 Executando Node.js API..."
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 3000:3000 \
  node:18-alpine \
  sh -c "npm install && npm run dev"
EOF
    chmod +x docker-run.sh
    
    print_success "Node.js API criado em: $project_dir"
    print_info "Para executar: cd $project_dir && ./docker-run.sh"
}

# 3. FastAPI Project
create_fastapi_project() {
    print_info "Criando FastAPI Project..."
    
    local project_name=$(read_with_default "Nome do projeto" "my-fastapi")
    
    local project_dir=$(create_basic_structure "$project_name" "FastAPI" "$WORKSPACE_DIR/python-web")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # requirements.txt
    cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
EOF
    
    # main.py
    cat > main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os

app = FastAPI(
    title="My FastAPI",
    description="FastAPI project created with Project Creator",
    version="1.0.0"
)

# CORS
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
        "message": "Hello from FastAPI!",
        "docs": "/docs"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
        reload=True
    )
EOF
    
    # .env template
    cat > .env.example << 'EOF'
PORT=8000
DEBUG=true
EOF
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
echo "🚀 Executando FastAPI..."
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 8000:8000 \
  python:3.11-slim \
  sh -c "pip install -r requirements.txt && python main.py"
EOF
    chmod +x docker-run.sh
    
    print_success "FastAPI project criado em: $project_dir"
    print_info "Para executar: cd $project_dir && ./docker-run.sh"
    print_info "Docs: http://localhost:8000/docs"
}

# 4. Django Project
create_django_project() {
    print_info "Criando Django Project..."
    
    local project_name=$(read_with_default "Nome do projeto" "my-django")
    
    local project_dir=$(create_basic_structure "$project_name" "Django" "$WORKSPACE_DIR/python-web")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # requirements.txt
    cat > requirements.txt << 'EOF'
Django==4.2.7
python-dotenv==1.0.0
EOF
    
    # Criar projeto Django via Docker
    print_info "Criando projeto Django via Docker..."
    docker run --rm -v "$project_dir:/workspace" -w /workspace python:3.11-slim \
        sh -c "pip install Django && django-admin startproject $project_name ." || {
        print_error "Falha ao criar Django project"
        return 1
    }
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
echo "🚀 Executando Django..."
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 8000:8000 \
  python:3.11-slim \
  sh -c "pip install -r requirements.txt && python manage.py runserver 0.0.0.0:8000"
EOF
    chmod +x docker-run.sh
    
    print_success "Django project criado em: $project_dir"
    print_info "Para executar: cd $project_dir && ./docker-run.sh"
}

# 5. Data Science Project
create_datascience_project() {
    print_info "Criando Data Science Project..."
    
    local project_name=$(read_with_default "Nome do projeto" "my-datascience")
    
    local project_dir=$(create_basic_structure "$project_name" "Data Science" "$WORKSPACE_DIR/datascience")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # Estrutura
    mkdir -p {data/{raw,processed},notebooks,src,reports}
    
    # requirements.txt
    cat > requirements.txt << 'EOF'
pandas==2.1.3
numpy==1.24.3
matplotlib==3.7.2
seaborn==0.12.2
jupyter==1.0.0
scikit-learn==1.3.2
EOF
    
    # Notebook inicial
    cat > notebooks/01_analysis.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Analysis\n",
    "\n",
    "## Setup"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "print(\"✅ Setup completo!\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF
    
    # Script para ambiente
    cat > docker-run.sh << 'EOF'
#!/bin/bash
echo "🔬 Iniciando ambiente Data Science..."
cd ~/docker-workspace/compose-files
docker-compose -f datascience.yml up -d

echo ""
echo "✅ Ambiente ativo!"
echo "📊 Jupyter Lab: http://localhost:8888 (token: dev123)"
echo "🧪 MLflow: http://localhost:5555"
EOF
    chmod +x docker-run.sh
    
    print_success "Data Science project criado em: $project_dir"
    print_info "Para executar: cd $project_dir && ./docker-run.sh"
}

# 6. Full-Stack Project
create_fullstack_project() {
    print_info "Criando Full-Stack Project..."
    
    local project_name=$(read_with_default "Nome do projeto" "my-fullstack")
    
    # Criar diretório em projects (não na raiz)
    mkdir -p "$WORKSPACE_DIR/projects"
    local project_dir="$WORKSPACE_DIR/projects/$project_name"
    
    if [ -d "$project_dir" ]; then
        print_error "Projeto '$project_name' já existe"
        return 1
    fi
    
    mkdir -p "$project_dir"/{frontend,backend}
    
    # Backend FastAPI
    print_info "Criando backend FastAPI..."
    cat > "$project_dir/backend/requirements.txt" << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
EOF
    
    cat > "$project_dir/backend/main.py" << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Full-Stack Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Full-Stack Backend API"}

@app.get("/api/health")
def health_check():
    return {"status": "healthy"}
EOF
    
    # Frontend - criar estrutura manual para evitar problemas do Docker
    print_info "Criando frontend React..."
    
    cat > "$project_dir/frontend/package.json" << EOF
{
  "name": "$project_name-frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
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
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.0.8"
  }
}
EOF

    # Criar estrutura do React
    mkdir -p "$project_dir/frontend/src"
    mkdir -p "$project_dir/frontend/public"
    
    cat > "$project_dir/frontend/index.html" << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Full-Stack App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

    cat > "$project_dir/frontend/vite.config.js" << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 3000
  }
})
EOF

    cat > "$project_dir/frontend/src/main.jsx" << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

    cat > "$project_dir/frontend/src/App.jsx" << 'EOF'
import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [message, setMessage] = useState('')

  useEffect(() => {
    fetch('http://localhost:8000/')
      .then(res => res.json())
      .then(data => setMessage(data.message))
      .catch(err => console.error(err))
  }, [])

  return (
    <div className="App">
      <h1>Full-Stack App</h1>
      <p>Backend says: {message}</p>
    </div>
  )
}

export default App
EOF

    cat > "$project_dir/frontend/src/App.css" << 'EOF'
.App {
  text-align: center;
  padding: 2rem;
}
EOF

    cat > "$project_dir/frontend/src/index.css" << 'EOF'
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
EOF
    
    # Docker Compose
    cat > "$project_dir/docker-compose.yml" << 'EOF'
services:
  backend:
    image: python:3.11-slim
    working_dir: /workspace
    volumes:
      - ./backend:/workspace
    ports:
      - "8000:8000"
    command: sh -c "pip install -r requirements.txt && uvicorn main:app --host 0.0.0.0 --reload"
    networks:
      - app-network

  frontend:
    image: node:18-alpine
    working_dir: /workspace
    volumes:
      - ./frontend:/workspace
    ports:
      - "3000:3000"
    command: sh -c "npm install && npm run dev"
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
EOF
    
    # Start script
    cat > "$project_dir/start.sh" << 'EOF'
#!/bin/bash
echo "🚀 Starting Full-Stack Application..."
docker-compose up -d

echo ""
echo "✅ Application started!"
echo "🌐 Frontend: http://localhost:3000"
echo "⚡ Backend: http://localhost:8000"
echo "📖 API Docs: http://localhost:8000/docs"
EOF
    chmod +x "$project_dir/start.sh"
    
    # README
    cat > "$project_dir/README.md" << EOF
# $project_name

Full-Stack application with React + FastAPI.

## Quick Start

\`\`\`bash
./start.sh
\`\`\`

## Services

- Frontend: http://localhost:3000
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs

## Development

\`\`\`bash
# Start services
docker-compose up -d

# Stop services  
docker-compose down

# View logs
docker-compose logs -f
\`\`\`
EOF
    
    print_success "Full-Stack project criado em: $project_dir"
    print_info "Para executar: cd $project_dir && ./start.sh"
}

# 7. Generic Project
create_generic_project() {
    print_info "Criando Generic Project..."
    
    local project_name=$(read_with_default "Nome do projeto" "my-project")
    local base_location=$(read_with_default "Localização (nodejs/python-web/datascience/projects)" "projects")
    
    local project_dir=$(create_basic_structure "$project_name" "Generic" "$WORKSPACE_DIR/$base_location")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # Estrutura básica
    mkdir -p {src,tests,docs}
    
    # Makefile
    cat > Makefile << 'EOF'
.PHONY: help install test clean

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

install:  ## Install dependencies
	@echo "Installing dependencies..."

test:  ## Run tests
	@echo "Running tests..."

clean:  ## Clean build artifacts
	@echo "Cleaning..."
EOF
    
    # Estrutura básica
    touch src/.gitkeep
    touch tests/.gitkeep
    touch docs/.gitkeep
    
    print_success "Generic project criado em: $project_dir"
    print_info "Estrutura básica com src/, tests/, docs/"
}

# ============================================================================
# LOOP PRINCIPAL
# ============================================================================

main() {
    check_workspace
    
    while true; do
        show_header
        show_main_menu
        
        read choice
        case $choice in
            1) 
                create_react_app
                ;;
            2) 
                create_nodejs_api
                ;;
            3) 
                create_fastapi_project
                ;;
            4) 
                create_django_project
                ;;
            5) 
                create_datascience_project
                ;;
            6) 
                create_fullstack_project
                ;;
            7) 
                create_generic_project
                ;;
            0) 
                print_success "Happy coding!"
                exit 0
                ;;
            *)
                print_error "Opção inválida"
                ;;
        esac
        
        echo ""
        echo -ne "${YELLOW}Criar outro projeto? (y/N): ${NC}"
        read -n 1 create_another
        echo
        if [[ ! $create_another =~ ^[Yy]$ ]]; then
            break
        fi
    done
    
    print_success "Até mais!"
}

# Executar
main
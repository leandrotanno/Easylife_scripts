#!/bin/bash

# Project Creator - Interactive Project Scaffolding
# Cria projetos automaticamente com templates e configurações
# Usage: ./project-creator.sh ou create-project (se instalado)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

WORKSPACE_DIR="$HOME/docker-workspace"

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
    echo -e "${YELLOW}6.${NC}  📓 Jupyter Notebook Project"
    echo -e "${YELLOW}7.${NC}  🌐 Full-Stack (React + FastAPI)"
    echo -e "${YELLOW}8.${NC}  📱 Next.js App"
    echo -e "${YELLOW}9.${NC}  🎨 Vue.js App"
    echo -e "${YELLOW}10.${NC} 📋 Generic Project"
    echo -e "${YELLOW}0.${NC}  ❌ Sair"
    echo ""
    echo -ne "${PURPLE}Escolha o tipo de projeto [0-10]: ${NC}"
}

# Verificar workspace
check_workspace() {
    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo -e "${RED}❌ Docker workspace não encontrado${NC}"
        echo -e "${CYAN}💡 Execute fedora-post-install.sh primeiro${NC}"
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
        echo -e "${RED}❌ Projeto '$project_name' já existe${NC}"
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

## Development

\`\`\`bash
# TODO: Add development instructions
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
*.swo

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

# 1. React App
create_react_app() {
    echo -e "${BLUE}⚛️  CRIANDO REACT APP${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-react-app")
    local use_typescript=$(read_with_default "Usar TypeScript? (y/N)" "n")
    
    local project_dir=$(create_basic_structure "$project_name" "React" "$WORKSPACE_DIR/nodejs")
    [ $? -ne 0 ] && return
    
    echo -e "${CYAN}🚀 Criando React app via Docker...${NC}"
    
    # Criar via container Node.js
    if [ "$use_typescript" = "y" ] || [ "$use_typescript" = "Y" ]; then
        docker run --rm -v "$project_dir:/workspace" -w /workspace node:18-alpine \
            sh -c "npm create vite@latest . -- --template react-ts && npm install"
    else
        docker run --rm -v "$project_dir:/workspace" -w /workspace node:18-alpine \
            sh -c "npm create vite@latest . -- --template react && npm install"
    fi
    
    # Scripts úteis
    cd "$project_dir"
    cat > docker-run.sh << 'EOF'
#!/bin/bash
# Executar React app via Docker
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

# Ou usando Node.js local
npm run dev
```

Access: http://localhost:5173
EOF
    
    echo -e "${GREEN}✅ React app criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para executar: cd $project_dir && ./docker-run.sh${NC}"
}

# 2. Node.js API
create_nodejs_api() {
    echo -e "${BLUE}🟢 CRIANDO NODE.JS API${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-node-api")
    local use_typescript=$(read_with_default "Usar TypeScript? (y/N)" "n")
    
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
    "dev": "nodemon index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
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
    if [ "$use_typescript" = "y" ] || [ "$use_typescript" = "Y" ]; then
        # TypeScript setup
        cat > index.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Hello from Node.js API!', timestamp: new Date().toISOString() });
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', uptime: process.uptime() });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
EOF
        
        # tsconfig.json
        cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
EOF
        
        # Atualizar package.json para TS
        sed -i 's/"main": "index.js"/"main": "dist\/index.js"/' package.json
        sed -i 's/"start": "node index.js"/"start": "node dist\/index.js"/' package.json
        sed -i 's/"dev": "nodemon index.js"/"dev": "nodemon --exec ts-node index.ts"/' package.json
        
    else
        # JavaScript setup
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
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
EOF
    fi
    
    # .env template
    cat > .env.example << 'EOF'
PORT=3000
NODE_ENV=development
# DATABASE_URL=
# JWT_SECRET=
EOF
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
# Executar Node.js API via Docker
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 3000:3000 \
  -e NODE_ENV=development \
  node:18-alpine \
  sh -c "npm install && npm run dev"
EOF
    chmod +x docker-run.sh
    
    echo -e "${GREEN}✅ Node.js API criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para executar: cd $project_dir && ./docker-run.sh${NC}"
}

# 3. FastAPI Project
create_fastapi_project() {
    echo -e "${BLUE}⚡ CRIANDO FASTAPI PROJECT${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-fastapi")
    local use_database=$(read_with_default "Incluir SQLAlchemy? (Y/n)" "y")
    local use_auth=$(read_with_default "Incluir autenticação JWT? (y/N)" "n")
    
    local project_dir=$(create_basic_structure "$project_name" "FastAPI" "$WORKSPACE_DIR/python-web")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # requirements.txt
    cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
python-dotenv==1.0.0
pydantic==2.5.0
EOF
    
    if [ "$use_database" = "y" ] || [ "$use_database" = "Y" ]; then
        cat >> requirements.txt << 'EOF'
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
alembic==1.13.1
EOF
    fi
    
    if [ "$use_auth" = "y" ] || [ "$use_auth" = "Y" ]; then
        cat >> requirements.txt << 'EOF'
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
EOF
    fi
    
    # Estrutura de diretórios
    mkdir -p app/{routers,models,schemas,crud,core}
    
    # main.py
    cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="My FastAPI",
    description="FastAPI project created with Project Creator",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {
        "message": "Hello from FastAPI!",
        "docs": "/docs",
        "redoc": "/redoc"
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
    
    # Config
    cat > app/core/config.py << 'EOF'
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "FastAPI App"
    database_url: str = "postgresql://dev:devpass@localhost:5432/devdb"
    secret_key: str = "your-secret-key-here"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    class Config:
        env_file = ".env"

settings = Settings()
EOF
    
    if [ "$use_database" = "y" ] || [ "$use_database" = "Y" ]; then
        # Database setup
        cat > app/core/database.py << 'EOF'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .config import settings

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF
        
        # Example model
        cat > app/models/user.py << 'EOF'
from sqlalchemy import Column, Integer, String, Boolean
from app.core.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
EOF
        
        # Example schema
        cat > app/schemas/user.py << 'EOF'
from pydantic import BaseModel

class UserBase(BaseModel):
    email: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool
    
    class Config:
        from_attributes = True
EOF
    fi
    
    # .env template
    cat > .env.example << 'EOF'
DATABASE_URL=postgresql://dev:devpass@localhost:5432/devdb
SECRET_KEY=your-secret-key-here
PORT=8000
DEBUG=true
EOF
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
# Executar FastAPI via Docker
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 8000:8000 \
  python:3.11-slim \
  sh -c "pip install -r requirements.txt && python -m app.main"
EOF
    chmod +x docker-run.sh
    
    echo -e "${GREEN}✅ FastAPI project criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para executar: cd $project_dir && ./docker-run.sh${NC}"
    echo -e "${CYAN}📖 Docs: http://localhost:8000/docs${NC}"
}

# 4. Django Project
create_django_project() {
    echo -e "${BLUE}🐍 CRIANDO DJANGO PROJECT${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-django")
    local use_rest=$(read_with_default "Incluir Django REST Framework? (Y/n)" "y")
    
    local project_dir=$(create_basic_structure "$project_name" "Django" "$WORKSPACE_DIR/python-web")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # requirements.txt
    cat > requirements.txt << 'EOF'
Django==4.2.7
python-dotenv==1.0.0
psycopg2-binary==2.9.9
Pillow==10.1.0
EOF
    
    if [ "$use_rest" = "y" ] || [ "$use_rest" = "Y" ]; then
        cat >> requirements.txt << 'EOF'
djangorestframework==3.14.0
django-cors-headers==4.3.1
EOF
    fi
    
    # Criar projeto Django via Docker
    echo -e "${CYAN}🚀 Criando projeto Django via Docker...${NC}"
    docker run --rm -v "$project_dir:/workspace" -w /workspace python:3.11-slim \
        sh -c "pip install Django && django-admin startproject $project_name ."
    
    # settings.py updates
    cat >> "$project_name/settings.py" << 'EOF'

# Custom settings
import os
from dotenv import load_dotenv

load_dotenv()

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'devdb'),
        'USER': os.getenv('DB_USER', 'dev'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'devpass'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
EOF
    
    if [ "$use_rest" = "y" ] || [ "$use_rest" = "Y" ]; then
        # Add DRF to installed apps
        sed -i "/INSTALLED_APPS = \[/a\\    'rest_framework',\n    'corsheaders'," "$project_name/settings.py"
        
        # Add middleware
        sed -i "/MIDDLEWARE = \[/a\\    'corsheaders.middleware.CorsMiddleware'," "$project_name/settings.py"
        
        # DRF settings
        cat >> "$project_name/settings.py" << 'EOF'

# Django REST Framework
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20
}

# CORS settings
CORS_ALLOW_ALL_ORIGINS = True  # Configure for production
EOF
    fi
    
    # .env template
    cat > .env.example << 'EOF'
DEBUG=True
SECRET_KEY=your-secret-key-here
DB_NAME=devdb
DB_USER=dev
DB_PASSWORD=devpass
DB_HOST=localhost
DB_PORT=5432
EOF
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
# Executar Django via Docker
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 8000:8000 \
  python:3.11-slim \
  sh -c "pip install -r requirements.txt && python manage.py runserver 0.0.0.0:8000"
EOF
    chmod +x docker-run.sh
    
    echo -e "${GREEN}✅ Django project criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para executar: cd $project_dir && ./docker-run.sh${NC}"
}

# 5. Data Science Project
create_datascience_project() {
    echo -e "${BLUE}📊 CRIANDO DATA SCIENCE PROJECT${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-datascience")
    local project_type=$(read_with_default "Tipo (analysis/ml/experiment)" "analysis")
    
    local project_dir=$(create_basic_structure "$project_name" "Data Science" "$WORKSPACE_DIR/datascience")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # Estrutura
    mkdir -p {data/{raw,processed,external},notebooks,src,models,reports,references}
    
    # requirements.txt
    cat > requirements.txt << 'EOF'
pandas==2.1.3
numpy==1.24.3
matplotlib==3.7.2
seaborn==0.12.2
plotly==5.17.0
jupyter==1.0.0
scikit-learn==1.3.2
scipy==1.11.4
statsmodels==0.14.0
openpyxl==3.1.2
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
python-dotenv==1.0.0
EOF
    
    case $project_type in
        "ml")
            cat >> requirements.txt << 'EOF'
xgboost==2.0.1
lightgbm==4.1.0
optuna==3.4.0
mlflow==2.8.1
shap==0.43.0
EOF
            ;;
        "experiment")
            cat >> requirements.txt << 'EOF'
mlflow==2.8.1
wandb==0.16.0
optuna==3.4.0
EOF
            ;;
    esac
    
    # Notebook inicial
    cat > notebooks/01_exploratory_analysis.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Análise Exploratória - Project Name\n",
    "\n",
    "## Objetivo\n",
    "Descreva o objetivo da análise aqui.\n",
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
    "import plotly.express as px\n",
    "\n",
    "# Configurações\n",
    "plt.style.use('seaborn-v0_8')\n",
    "pd.set_option('display.max_columns', None)\n",
    "\n",
    "print(\"✅ Setup completo!\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Carregamento dos Dados"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Carregar dados\n",
    "# df = pd.read_csv('../data/raw/data.csv')\n",
    "# df.head()"
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
    
    # Estrutura src
    cat > src/__init__.py << 'EOF'
"""
Data Science project package
"""
EOF
    
    cat > src/data_processing.py << 'EOF'
"""
Data processing utilities
"""
import pandas as pd
import numpy as np

def load_data(filepath):
    """Load data from file"""
    return pd.read_csv(filepath)

def clean_data(df):
    """Basic data cleaning"""
    # Remove duplicates
    df = df.drop_duplicates()
    
    # Handle missing values
    # df = df.dropna()  # or df.fillna()
    
    return df
EOF
    
    if [ "$project_type" = "ml" ]; then
        cat > src/model.py << 'EOF'
"""
Machine Learning models
"""
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import mlflow

class MLModel:
    def __init__(self):
        self.model = None
        
    def train(self, X, y):
        """Train the model"""
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        with mlflow.start_run():
            # Train model here
            # self.model.fit(X_train, y_train)
            
            # Log metrics
            # predictions = self.model.predict(X_test)
            # accuracy = accuracy_score(y_test, predictions)
            # mlflow.log_metric("accuracy", accuracy)
            pass
            
    def predict(self, X):
        """Make predictions"""
        if self.model is None:
            raise ValueError("Model not trained yet")
        return self.model.predict(X)
EOF
    fi
    
    # .env template
    cat > .env.example << 'EOF'
# Database
DATABASE_URL=postgresql://mlflow:mlflow123@localhost:5433/mlflow

# MLflow
MLFLOW_TRACKING_URI=http://localhost:5555

# Experiment settings
EXPERIMENT_NAME=my-experiment
EOF
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
# Executar ambiente Data Science
echo "🔬 Iniciando ambiente Data Science..."
cd ~/docker-workspace/compose-files
docker-compose -f datascience.yml up -d

echo "✅ Ambiente ativo!"
echo "📊 Jupyter Lab: http://localhost:8888 (token: dev123)"
echo "🧪 MLflow: http://localhost:5555"
EOF
    chmod +x docker-run.sh
    
    echo -e "${GREEN}✅ Data Science project criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para executar: cd $project_dir && ./docker-run.sh${NC}"
}

# 6. Jupyter Notebook Project
create_jupyter_project() {
    echo -e "${BLUE}📓 CRIANDO JUPYTER PROJECT${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-notebooks")
    local project_type=$(read_with_default "Foco (analysis/tutorial/research)" "analysis")
    
    local project_dir=$(create_basic_structure "$project_name" "Jupyter Notebooks" "$WORKSPACE_DIR/datascience")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # Estrutura de notebooks
    mkdir -p notebooks/{exploratory,analysis,modeling,reporting}
    mkdir -p {data,assets,utils}
    
    # requirements.txt básico
    cat > requirements.txt << 'EOF'
jupyter==1.0.0
jupyterlab==4.0.7
pandas==2.1.3
numpy==1.24.3
matplotlib==3.7.2
seaborn==0.12.2
plotly==5.17.0
ipywidgets==8.1.1
EOF
    
    # Notebook template baseado no tipo
    case $project_type in
        "tutorial")
            cat > notebooks/00_setup_tutorial.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Tutorial Setup\n",
    "\n",
    "## Pré-requisitos\n",
    "- Python 3.8+\n",
    "- Jupyter Lab\n",
    "\n",
    "## Instalação\n",
    "```bash\n",
    "pip install -r requirements.txt\n",
    "```"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Verificar instalações\n",
    "import sys\n",
    "print(f\"Python version: {sys.version}\")\n",
    "\n",
    "try:\n",
    "    import pandas as pd\n",
    "    import numpy as np\n",
    "    import matplotlib.pyplot as plt\n",
    "    print(\"✅ Todas as bibliotecas instaladas corretamente!\")\n",
    "except ImportError as e:\n",
    "    print(f\"❌ Erro na importação: {e}\")"
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
            ;;
        "research")
            cat > notebooks/research_template.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Research Title\n",
    "\n",
    "**Author:** Your Name  \n",
    "**Date:** $(date)  \n",
    "**Objective:** Brief description of research objective\n",
    "\n",
    "## Abstract\n",
    "Brief summary of the research.\n",
    "\n",
    "## Methodology\n",
    "Describe the approach used.\n",
    "\n",
    "## Data\n",
    "Describe the data sources and characteristics."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Setup and imports\n",
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "# Configuration\n",
    "plt.style.use('seaborn-v0_8')\n",
    "pd.set_option('display.max_columns', None)"
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
            ;;
        *)
            # Analysis template (default)
            cat > notebooks/analysis_template.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Analysis Template\n",
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
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "import plotly.express as px\n",
    "\n",
    "# Configurações\n",
    "plt.style.use('seaborn-v0_8')\n",
    "sns.set_palette('husl')\n",
    "pd.set_option('display.max_columns', None)\n",
    "\n",
    "print(\"✅ Setup completo!\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 2. Carregamento dos Dados"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Carregar dados\n",
    "# df = pd.read_csv('../data/sample_data.csv')\n",
    "# df.head()"
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
            ;;
    esac
    
    # Utility functions
    cat > utils/helpers.py << 'EOF'
"""
Utility functions for notebook projects
"""
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def setup_plotting():
    """Configure plotting defaults"""
    plt.style.use('seaborn-v0_8')
    sns.set_palette('husl')
    plt.rcParams['figure.figsize'] = (12, 8)

def quick_info(df):
    """Quick dataset information"""
    print(f"Shape: {df.shape}")
    print(f"Memory usage: {df.memory_usage().sum() / 1024**2:.2f} MB")
    print(f"Missing values: {df.isnull().sum().sum()}")
    print(f"Duplicates: {df.duplicated().sum()}")

def plot_missing(df):
    """Plot missing values heatmap"""
    plt.figure(figsize=(12, 6))
    sns.heatmap(df.isnull(), cbar=True, yticklabels=False)
    plt.title('Missing Values Heatmap')
    plt.show()
EOF
    
    echo -e "${GREEN}✅ Jupyter project criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para usar: Inicie o ambiente Data Science e navegue até o projeto${NC}"
}

# 7. Full-Stack Project
create_fullstack_project() {
    echo -e "${BLUE}🌐 CRIANDO FULL-STACK PROJECT${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-fullstack")
    
    local project_dir="$WORKSPACE_DIR/fullstack/$project_name"
    
    if [ -d "$project_dir" ]; then
        echo -e "${RED}❌ Projeto '$project_name' já existe${NC}"
        return 1
    fi
    
    mkdir -p "$project_dir"/{frontend,backend}
    cd "$project_dir"
    
    echo -e "${CYAN}🚀 Criando backend FastAPI...${NC}"
    cd backend
    
    # Backend FastAPI
    cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
python-dotenv==1.0.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
EOF
    
    cat > main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Full-Stack Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # React dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Full-Stack Backend API"}

@app.get("/api/health")
def health_check():
    return {"status": "healthy", "service": "backend"}
EOF
    
    echo -e "${CYAN}🚀 Criando frontend React...${NC}"
    cd ../frontend
    
    # Frontend React via Docker
    docker run --rm -v "$(pwd):/workspace" -w /workspace node:18-alpine \
        sh -c "npm create vite@latest . -- --template react && npm install"
    
    # Docker Compose para full-stack
    cd ..
    cat > docker-compose.yml << 'EOF'
services:
  backend:
    image: python:3.11-slim
    working_dir: /workspace
    volumes:
      - ./frontend:/workspace
    ports:
      - "3000:3000"
    command: sh -c "npm install && npm run dev -- --host 0.0.0.0"
    networks:
      - app-network

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: fullstack_db
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
EOF
    
    # README para full-stack
    cat > README.md << EOF
# $project_name

Full-Stack application with React frontend and FastAPI backend.

## Architecture

- **Frontend**: React (Vite)
- **Backend**: FastAPI
- **Database**: PostgreSQL
- **Containerization**: Docker Compose

## Quick Start

\`\`\`bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps
\`\`\`

## Services

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- PostgreSQL: localhost:5432

## Development

### Backend
\`\`\`bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
\`\`\`

### Frontend
\`\`\`bash
cd frontend
npm install
npm run dev
\`\`\`
EOF
    
    # Start script
    cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting Full-Stack Application..."
docker-compose up -d

echo ""
echo "✅ Application started!"
echo "🌐 Frontend: http://localhost:3000"
echo "⚡ Backend: http://localhost:8000"
echo "📖 API Docs: http://localhost:8000/docs"
EOF
    chmod +x start.sh
    
    echo -e "${GREEN}✅ Full-Stack project criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para executar: cd $project_dir && ./start.sh${NC}"
}

# 8. Next.js App
create_nextjs_app() {
    echo -e "${BLUE}📱 CRIANDO NEXT.JS APP${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-nextjs-app")
    local use_typescript=$(read_with_default "Usar TypeScript? (Y/n)" "y")
    local use_tailwind=$(read_with_default "Usar Tailwind CSS? (Y/n)" "y")
    
    local project_dir=$(create_basic_structure "$project_name" "Next.js" "$WORKSPACE_DIR/nodejs")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    echo -e "${CYAN}🚀 Criando Next.js app via Docker...${NC}"
    
    # Criar Next.js app
    local create_cmd="npx create-next-app@latest . --app"
    
    if [ "$use_typescript" = "y" ] || [ "$use_typescript" = "Y" ]; then
        create_cmd="$create_cmd --typescript"
    else
        create_cmd="$create_cmd --javascript"
    fi
    
    if [ "$use_tailwind" = "y" ] || [ "$use_tailwind" = "Y" ]; then
        create_cmd="$create_cmd --tailwind"
    fi
    
    create_cmd="$create_cmd --eslint --src-dir --import-alias '@/*'"
    
    docker run --rm -v "$(pwd):/workspace" -w /workspace node:18-alpine \
        sh -c "$create_cmd"
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
# Executar Next.js via Docker
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 3000:3000 \
  node:18-alpine \
  sh -c "npm install && npm run dev"
EOF
    chmod +x docker-run.sh
    
    echo -e "${GREEN}✅ Next.js app criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para executar: cd $project_dir && ./docker-run.sh${NC}"
}

# 9. Vue.js App
create_vue_app() {
    echo -e "${BLUE}🎨 CRIANDO VUE.JS APP${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-vue-app")
    local use_typescript=$(read_with_default "Usar TypeScript? (y/N)" "n")
    
    local project_dir=$(create_basic_structure "$project_name" "Vue.js" "$WORKSPACE_DIR/nodejs")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    echo -e "${CYAN}🚀 Criando Vue.js app via Docker...${NC}"
    
    if [ "$use_typescript" = "y" ] || [ "$use_typescript" = "Y" ]; then
        docker run --rm -v "$(pwd):/workspace" -w /workspace node:18-alpine \
            sh -c "npm create vue@latest . -- --typescript --router --pinia --vitest --eslint --prettier"
    else
        docker run --rm -v "$(pwd):/workspace" -w /workspace node:18-alpine \
            sh -c "npm create vue@latest . -- --router --pinia --vitest --eslint --prettier"
    fi
    
    # Docker run script
    cat > docker-run.sh << 'EOF'
#!/bin/bash
# Executar Vue.js via Docker
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  -p 5173:5173 \
  node:18-alpine \
  sh -c "npm install && npm run dev -- --host 0.0.0.0"
EOF
    chmod +x docker-run.sh
    
    echo -e "${GREEN}✅ Vue.js app criado em: $project_dir${NC}"
    echo -e "${CYAN}🚀 Para executar: cd $project_dir && ./docker-run.sh${NC}"
}

# 10. Generic Project
create_generic_project() {
    echo -e "${BLUE}📋 CRIANDO PROJETO GENÉRICO${NC}"
    echo ""
    
    local project_name=$(read_with_default "Nome do projeto" "my-project")
    local project_type=$(read_with_default "Tipo de projeto" "generic")
    local base_location=$(read_with_default "Localização (nodejs/python-web/datascience)" "nodejs")
    
    local project_dir=$(create_basic_structure "$project_name" "$project_type" "$WORKSPACE_DIR/$base_location")
    [ $? -ne 0 ] && return
    
    cd "$project_dir"
    
    # Estrutura básica
    mkdir -p {src,tests,docs,config}
    
    # Makefile
    cat > Makefile << 'EOF'
.PHONY: help install test clean lint format

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $1, $2}'

install:  ## Install dependencies
	@echo "Installing dependencies..."
	# Add install commands here

test:  ## Run tests
	@echo "Running tests..."
	# Add test commands here

clean:  ## Clean build artifacts
	@echo "Cleaning..."
	# Add clean commands here

lint:  ## Run linter
	@echo "Running linter..."
	# Add lint commands here

format:  ## Format code
	@echo "Formatting code..."
	# Add format commands here
EOF
    
    # .editorconfig
    cat > .editorconfig << 'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.{py,pyx}]
indent_size = 4

[*.md]
trim_trailing_whitespace = false
EOF
    
    # Basic src structure
    touch src/.gitkeep
    touch tests/.gitkeep
    touch docs/.gitkeep
    touch config/.gitkeep
    
    echo -e "${GREEN}✅ Projeto genérico criado em: $project_dir${NC}"
    echo -e "${CYAN}📋 Estrutura básica com src/, tests/, docs/, config/${NC}"
}

# Loop principal
main() {
    check_workspace
    
    while true; do
        show_header
        show_main_menu
        
        read choice
        case $choice in
            1) create_react_app ;;
            2) create_nodejs_api ;;
            3) create_fastapi_project ;;
            4) create_django_project ;;
            5) create_datascience_project ;;
            6) create_jupyter_project ;;
            7) create_fullstack_project ;;
            8) create_nextjs_app ;;
            9) create_vue_app ;;
            10) create_generic_project ;;
            0) 
                echo -e "${GREEN}🚀 Happy coding!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opção inválida. Pressione Enter...${NC}"
                read
                ;;
        esac
        
        echo ""
        echo -e "${YELLOW}Criar outro projeto? (y/N):${NC}"
        read -n 1 create_another
        echo
        if [[ ! $create_another =~ ^[Yy]$ ]]; then
            break
        fi
    done
    
    echo -e "${GREEN}👋 Até mais!${NC}"
}

# Executar
main
      - ./backend:/workspace
    ports:
      - "8000:8000"
    command: sh -c "pip install -r requirements.txt && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
    environment:
      - PYTHONUNBUFFERED=1
    networks:
      - app-network

  frontend:
    image: node:18-alpine
    working_dir: /workspace
    volumes:
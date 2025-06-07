# ======================
# ALIASES PYTHON
# ======================

# ======================
# PYTHON BÁSICO
# ======================
alias py='python3'
alias python='python3'
alias py2='python2'  # Para compatibilidade se necessário
alias pip='pip3'
alias pip2='pip2'    # Para compatibilidade se necessário

# ======================
# AMBIENTES VIRTUAIS
# ======================
# Criar ambiente virtual
alias venv='python3 -m venv'
alias mkv='python3 -m venv venv'              # Criar venv na pasta atual
alias mkvenv='python3 -m venv'                # Criar venv com nome personalizado

# Ativar/Desativar ambiente virtual
alias av='source venv/bin/activate'           # Ativar venv local
alias dv='deactivate'                         # Desativar venv
alias sv='source bin/activate'                # Ativar venv em pasta bin/

# Conda (se instalado)
if command -v conda >/dev/null 2>&1; then
    alias ca='conda activate'
    alias cda='conda deactivate'
    alias cenv='conda env list'
    alias cinfo='conda info --envs'
    alias ccreate='conda create -n'
    alias cinstall='conda install'
    alias cupdate='conda update'
    alias cremove='conda remove'
fi

# Pipenv (se instalado)
if command -v pipenv >/dev/null 2>&1; then
    alias penv='pipenv'
    alias pshell='pipenv shell'
    alias pinstall='pipenv install'
    alias puninstall='pipenv uninstall'
    alias prun='pipenv run'
    alias pcheck='pipenv check'
    alias pgraph='pipenv graph'
fi

# ======================
# GERENCIAMENTO DE PACOTES
# ======================
alias pipi='pip install'
alias pipu='pip install --upgrade'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze'
alias pipfr='pip freeze > requirements.txt'   # Gerar requirements.txt
alias pipl='pip list'
alias pips='pip show'
alias pipout='pip list --outdated'            # Pacotes desatualizados
alias pipun='pip uninstall'

# Poetry (se instalado)
if command -v poetry >/dev/null 2>&1; then
    alias po='poetry'
    alias poadd='poetry add'
    alias poinstall='poetry install'
    alias porun='poetry run'
    alias poshell='poetry shell'
    alias pobuild='poetry build'
    alias poshow='poetry show'
    alias poupdate='poetry update'
fi

# ======================
# EXECUÇÃO E DEBUGGING
# ======================
alias pyr='python3 -c'                        # Executar código Python inline
alias pypath='python3 -c "import sys; print(\"\n\".join(sys.path))"'
alias pyver='python3 --version'
alias pipver='pip --version'

# IPython (se instalado)
if command -v ipython >/dev/null 2>&1; then
    alias ipy='ipython'
    alias ipython3='ipython'
fi

# Jupyter (se instalado)
if command -v jupyter >/dev/null 2>&1; then
    alias jnb='jupyter notebook'
    alias jlab='jupyter lab'
    alias jlist='jupyter notebook list'
fi

# ======================
# TESTING
# ======================
# Pytest (se instalado)
if command -v pytest >/dev/null 2>&1; then
    alias pyt='pytest'
    alias pytv='pytest -v'                     # Verbose
    alias pyts='pytest -s'                     # Não capturar output
    alias pytx='pytest -x'                     # Parar no primeiro erro
    alias pytc='pytest --cov'                 # Com coverage
    alias pytw='pytest --lf'                  # Rodar apenas os que falharam
fi

# Unittest
alias pyu='python3 -m unittest'
alias pyud='python3 -m unittest discover'     # Descobrir e rodar todos os testes

# Coverage (se instalado)
if command -v coverage >/dev/null 2>&1; then
    alias cov='coverage'
    alias covrun='coverage run'
    alias covrep='coverage report'
    alias covhtml='coverage html'
fi

# ======================
# LINTING E FORMATAÇÃO
# ======================
# Black (se instalado)
if command -v black >/dev/null 2>&1; then
    alias black='black'
    alias blackd='black --diff'                # Mostrar diff sem aplicar
    alias blackc='black --check'               # Verificar sem aplicar
fi

# Flake8 (se instalado)
if command -v flake8 >/dev/null 2>&1; then
    alias f8='flake8'
    alias flake='flake8'
fi

# Autopep8 (se instalado)
if command -v autopep8 >/dev/null 2>&1; then
    alias pep8='autopep8'
    alias pep8i='autopep8 --in-place'         # Aplicar correções
    alias pep8d='autopep8 --diff'             # Mostrar diff
fi

# Isort (se instalado)
if command -v isort >/dev/null 2>&1; then
    alias isort='isort'
    alias isortd='isort --diff'
    alias isortc='isort --check-only'
fi

# Pylint (se instalado)
if command -v pylint >/dev/null 2>&1; then
    alias pylint='pylint'
    alias pyl='pylint'
fi

# Mypy (se instalado) 
if command -v mypy >/dev/null 2>&1; then
    alias mypy='mypy'
    alias mpy='mypy'
fi

# ======================
# DJANGO
# ======================
alias dj='python manage.py'
alias djrun='python manage.py runserver'
alias djm='python manage.py migrate'
alias djmm='python manage.py makemigrations'
alias djs='python manage.py shell'
alias djc='python manage.py collectstatic'
alias djt='python manage.py test'
alias djsu='python manage.py createsuperuser'
alias djdb='python manage.py dbshell'

# ======================
# FLASK
# ======================
alias flaskrun='flask run'
alias flasksh='flask shell'
alias flaskdb='flask db'

# ======================
# FASTAPI
# ======================
alias uvrun='uvicorn main:app --reload'       # Rodar FastAPI com reload
alias uvhost='uvicorn main:app --host 0.0.0.0 --port 8000'

# ======================
# DESENVOLVIMENTO WEB
# ======================
# Servidor HTTP simples
alias pyserver='python3 -m http.server'
alias pyserver8='python3 -m http.server 8080'

# ======================
# UTILITÁRIOS
# ======================
# Instalar pacotes comuns para data science
alias pypkgds='pip install numpy pandas matplotlib seaborn jupyter scikit-learn'

# Instalar pacotes comuns para web
alias pypkgweb='pip install flask django fastapi requests beautifulsoup4'

# Instalar ferramentas de desenvolvimento
alias pypkgdev='pip install black flake8 pytest mypy isort'

# ======================
# FUNÇÕES ÚTEIS
# ======================

# Criar projeto Python básico
function pynew() {
    if [ -z "$1" ]; then
        echo "Uso: pynew <nome_do_projeto>"
        return 1
    fi
    
    mkdir -p "$1"
    cd "$1"
    
    # Criar estrutura básica
    mkdir -p src tests docs
    touch README.md
    touch requirements.txt
    touch .gitignore
    
    # Criar venv
    python3 -m venv venv
    
    # Criar arquivos básicos
    cat > src/main.py << 'EOF'
#!/usr/bin/env python3
"""
Módulo principal do projeto.
"""

def main():
    """Função principal."""
    print("Hello, World!")

if __name__ == "__main__":
    main()
EOF

    cat > tests/test_main.py << 'EOF'
"""
Testes para o módulo main.
"""
import unittest
import sys
import os

# Adicionar src ao path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from main import main

class TestMain(unittest.TestCase):
    def test_main(self):
        # Este é um teste básico
        self.assertTrue(True)

if __name__ == '__main__':
    unittest.main()
EOF

    cat > .gitignore << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Virtual environment
venv/
env/
ENV/

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Jupyter Notebook
.ipynb_checkpoints

# pyenv
.python-version

# celery beat schedule file
celerybeat-schedule

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
EOF

    echo "📁 Projeto Python '$1' criado com sucesso!"
    echo "📋 Estrutura:"
    echo "   ├── src/main.py"
    echo "   ├── tests/test_main.py"
    echo "   ├── venv/ (ambiente virtual)"
    echo "   ├── requirements.txt"
    echo "   ├── README.md"
    echo "   └── .gitignore"
    echo ""
    echo "🚀 Para começar:"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt"
}

# Ativar ambiente virtual automaticamente se existir
function pyauto() {
    if [[ -f "venv/bin/activate" ]]; then
        source venv/bin/activate
        echo "✅ Ambiente virtual ativado automaticamente"
    elif [[ -f "bin/activate" ]]; then
        source bin/activate
        echo "✅ Ambiente virtual ativado automaticamente"
    else
        echo "❌ Nenhum ambiente virtual encontrado"
    fi
}

# Instalar e salvar dependência
function pyins() {
    if [ -z "$1" ]; then
        echo "Uso: pyins <pacote>"
        return 1
    fi
    
    pip install "$1"
    pip freeze > requirements.txt
    echo "📦 Pacote '$1' instalado e requirements.txt atualizado"
}

# Verificar saúde do projeto Python
function pycheck() {
    echo "🔍 Verificando projeto Python..."
    echo ""
    
    # Verificar Python
    echo "🐍 Versão do Python:"
    python3 --version
    echo ""
    
    # Verificar ambiente virtual
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "✅ Ambiente virtual ativo: $VIRTUAL_ENV"
    else
        echo "⚠️  Nenhum ambiente virtual ativo"
    fi
    echo ""
    
    # Verificar requirements.txt
    if [[ -f "requirements.txt" ]]; then
        echo "📋 requirements.txt encontrado:"
        cat requirements.txt
    else
        echo "⚠️  requirements.txt não encontrado"
    fi
    echo ""
    
    # Verificar estrutura do projeto
    echo "📁 Estrutura do projeto:"
    if command -v eza >/dev/null 2>&1; then
        eza --tree --level=2 --icons
    else
        find . -maxdepth 2 -type d | head -10
    fi
    echo ""
    
    # Verificar testes
    if [[ -d "tests" ]] || [[ -f "test_*.py" ]] || [[ -f "*_test.py" ]]; then
        echo "✅ Testes encontrados"
    else
        echo "⚠️  Nenhum teste encontrado"
    fi
}

# Limpar cache Python
function pyclean() {
    echo "🧹 Limpando cache Python..."
    
    # Remover __pycache__
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    
    # Remover arquivos .pyc
    find . -name "*.pyc" -delete 2>/dev/null
    
    # Remover arquivos .pyo
    find . -name "*.pyo" -delete 2>/dev/null
    
    # Remover .pytest_cache
    find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null
    
    # Remover .coverage
    find . -name ".coverage" -delete 2>/dev/null
    
    echo "✅ Cache Python limpo!"
}

# Backup do ambiente virtual
function pybackup() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        pip freeze > "requirements_$(date +%Y%m%d_%H%M%S).txt"
        echo "💾 Backup do ambiente salvo em requirements_$(date +%Y%m%d_%H%M%S).txt"
    else
        echo "❌ Nenhum ambiente virtual ativo"
    fi
}
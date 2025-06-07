# 🛠️ Scripts de Setup e CLI Tools

Este diretório contém **scripts de setup do sistema** e **ferramentas CLI interativas** para desenvolvimento Docker-first no Fedora.

## 📦 **Scripts de Setup (Execute em ordem)**

### **🚀 express-installer.sh**
**Instalador automático - Executa todos os scripts em sequência**
- Gerencia privilégios automaticamente (root → usuário)
- Salva estado para recuperação de falhas
- Solicita logout/login quando necessário
- **Uso**: `sudo ./express-installer.sh` → logout/login → `./express-installer.sh`

### **1. 01-fedora-setup.sh**
**Sistema base e repositórios (como root)**
- Instala Docker CE oficial, VS Code, Git, Build tools
- Configura RPM Fusion, Flathub, repositórios essenciais
- Bibliotecas Python científicas, codecs multimídia
- **Uso**: `sudo ./01-fedora-setup.sh install`

### **2. 02-fedora-post-install.sh**
**Docker workspace e ambiente de desenvolvimento (como usuário)**
- Cria workspace Docker organizado em `~/docker-workspace/`
- Instala NVM + Node.js, Python tools mínimos
- Configura VS Code + extensões para containers
- **Uso**: `./02-fedora-post-install.sh all`

### **3. 04-ssh-setup.sh**
**Configuração de chaves SSH (como usuário - opcional)**
- Setup interativo para GitHub, GitLab, VPS
- Gera chaves ed25519, configura SSH config
- Testa conexões automaticamente
- **Uso**: `./04-ssh-setup.sh` → menu interativo

### **4. 05-zsh-setup.sh**
**Terminal ZSH completo (como usuário)**
- Instala ZSH + Oh My Zsh + Spaceship theme
- Plugins: autosuggestions, completions, syntax highlighting
- Aliases para Git, Docker, Node.js, Python, CLI tools
- **Uso**: `./05-zsh-setup.sh install`

---

## 🛠️ **CLI Tools Interativos (Use quando precisar)**

### **git-helper.sh**
**Gerenciamento Git via menu**
- Status, add/commit, push/pull, branches, merge/rebase
- Logs e histórico, stash, configurações, operações de emergência
- **Uso**: `./git-helper.sh`

### **docker-helper.sh**
**Gerenciamento Docker completo**
- Status e info, containers, images, compose, networks, volumes
- Ambientes de desenvolvimento (Node.js, Python, Data Science)
- Cleanup e logs
- **Uso**: `./docker-helper.sh`

### **project-creator.sh**
**Scaffold projetos automaticamente** ⭐
- **10 tipos**: React, Node.js API, FastAPI, Django, Data Science
- Next.js, Vue.js, Full-Stack, Jupyter, projetos genéricos
- **TypeScript support**, banco de dados, autenticação JWT
- **Detecta conflitos** com database-helper e adapta portas
- Cria estrutura completa com docker-run.sh
- **Uso**: `./project-creator.sh`

### **dev-switcher.sh**
**Navegação entre projetos**
- Lista projetos por categoria com status Git
- Quick search, abrir VS Code/terminal/browser
- Gerenciamento de ambientes Docker
- **Uso**: `./dev-switcher.sh`

### **database-helper.sh**
**PostgreSQL management**
- Gerencia databases e schemas
- Backup/restore, queries SQL, export CSV
- Conecta automaticamente aos containers PostgreSQL
- **Uso**: `./database-helper.sh`

### **compose-templates.sh**
**Templates Docker Compose**
- Stacks: MEAN, LAMP, React+FastAPI, Django, Data Science, Microservices
- Cria projetos com docker-compose.yml configurado
- **Uso**: `./compose-templates.sh`

---

## 📚 **Arquivos de Referência**

### **eza_aliases.sh**
Aliases para gerenciamento de arquivos e navegação (documentação)

### **node_aliases.sh**
Aliases para Node.js, NPM, Yarn, PNPM, frameworks (documentação)

### **python_aliases.sh**
Aliases para Python, pip, ambientes virtuais, Django, Flask (documentação)

---

## 🎯 **Comandos Rápidos Após Setup**

### **Ambientes de desenvolvimento:**
```bash
start-node        # Node.js + Redis (ports 3000, 5173, 8080)
start-python      # FastAPI + PostgreSQL + Redis (8000, 5000, 8501)
start-ds          # Jupyter Lab + MLflow + GPU (8888, 5555)
stop-all          # Parar todos os ambientes
dev-status        # Status de todos containers
```

### **CLI Tools principais:**
```bash
git-helper        # Git management via menu
docker-helper     # Docker management completo
project-creator   # Criar projetos automaticamente
dev-switcher      # Navegar entre projetos
database-helper   # PostgreSQL management
```

---

## 🔥 **Quick Start**

```bash
# 1. Setup completo (execute uma vez)
sudo ./01-fedora-setup.sh install
# (logout/login)
./02-fedora-post-install.sh all
./04-ssh-setup.sh  # opcional
./05-zsh-setup.sh install

# 2. Criar um projeto
./project-creator.sh
# Escolha tipo → Digite nome → Pronto!

# 3. Iniciar ambiente
start-python      # ou start-node, start-ds

# 4. Gerenciar projetos
dev-switcher      # navegar projetos
git-helper        # operações Git
docker-helper     # gerenciar containers
```

---

## ⚠️ **Notas Importantes**

- **Ordem dos scripts**: Execute 01 → 02 → (03) → (04) na sequência
- **Privilégios**: Script 01 precisa de `sudo`, os outros como usuário normal
- **Database conflicts**: project-creator detecta database-helper e adapta configurações
- **Port conflicts**: Portas são ajustadas automaticamente se houver conflito
- **ZSH**: Após install, faça logout/login para ativar como shell padrão

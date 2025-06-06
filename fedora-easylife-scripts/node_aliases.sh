# ======================
# ALIASES NODE.JS
# ======================

# ======================
# NODE BÁSICO
# ======================
alias node='node'
alias n='node'
alias nodeie='node --inspect'                 # Debug mode
alias nodev='node --version'

# ======================
# NPM - GERENCIAMENTO DE PACOTES
# ======================
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'                    # Global
alias nis='npm install --save'
alias nu='npm uninstall'
alias nug='npm uninstall -g'
alias nud='npm uninstall --save-dev'
alias nup='npm update'
alias nupg='npm update -g'

# Scripts NPM
alias nr='npm run'
alias nrs='npm run start'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'
alias nrl='npm run lint'

# Informações NPM
alias nl='npm list'
alias nlg='npm list -g --depth=0'             # Pacotes globais
alias nls='npm list --depth=0'                # Pacotes locais (nível 0)
alias no='npm outdated'                       # Pacotes desatualizados
alias ni='npm info'
alias nv='npm view'

# Outras operações NPM
alias nc='npm cache clean --force'
alias ncc='npm cache clean --force'
alias nf='npm fund'                           # Ver funding info
alias na='npm audit'                          # Auditoria de segurança
alias naf='npm audit fix'                     # Corrigir vulnerabilidades
alias npx='npx'

# ======================
# YARN (se instalado)
# ======================
if command -v yarn >/dev/null 2>&1; then
    alias y='yarn'
    alias ya='yarn add'
    alias yad='yarn add --dev'
    alias yag='yarn global add'
    alias yr='yarn remove'
    alias yug='yarn global remove'
    alias yu='yarn upgrade'
    alias yui='yarn upgrade-interactive'
    
    # Scripts Yarn
    alias ys='yarn start'
    alias yd='yarn dev'
    alias yb='yarn build'
    alias yt='yarn test'
    alias yl='yarn lint'
    
    # Informações Yarn
    alias yls='yarn list'
    alias ylsg='yarn global list'
    alias yo='yarn outdated'
    alias yi='yarn info'
    alias ya='yarn audit'
    alias yaf='yarn audit --fix'
fi

# ======================
# PNPM (se instalado)
# ======================
if command -v pnpm >/dev/null 2>&1; then
    alias p='pnpm'
    alias pi='pnpm install'
    alias pa='pnpm add'
    alias pad='pnpm add --save-dev'
    alias pag='pnpm add --global'
    alias pr='pnpm remove'
    alias pug='pnpm remove --global'
    alias pu='pnpm update'
    
    # Scripts PNPM
    alias ps='pnpm start'
    alias pd='pnpm dev'
    alias pb='pnpm build'
    alias pt='pnpm test'
    alias pl='pnpm lint'
    
    # Informações PNPM
    alias pls='pnpm list'
    alias plsg='pnpm list --global'
    alias po='pnpm outdated'
    alias pa='pnpm audit'
    alias paf='pnpm audit --fix'
fi

# ======================
# BUN (se instalado)
# ======================
if command -v bun >/dev/null 2>&1; then
    alias b='bun'
    alias bi='bun install'
    alias ba='bun add'
    alias bad='bun add --development'
    alias bag='bun add --global'
    alias br='bun remove'
    alias brug='bun remove --global'
    alias bu='bun update'
    
    # Scripts Bun
    alias bs='bun start'
    alias bd='bun dev'
    alias bb='bun build'
    alias bt='bun test'
    alias brun='bun run'
fi

# ======================
# NVM (Node Version Manager)
# ======================
if command -v nvm >/dev/null 2>&1; then
    alias nvmi='nvm install'
    alias nvmu='nvm use'
    alias nvml='nvm list'
    alias nvmls='nvm ls'
    alias nvmlr='nvm ls-remote'
    alias nvmc='nvm current'
    alias nvma='nvm alias'
    alias nvmua='nvm unalias'
fi

# ======================
# DESENVOLVIMENTO
# ======================
# Nodemon (se instalado)
if command -v nodemon >/dev/null 2>&1; then
    alias nmon='nodemon'
    alias ndev='nodemon --watch'
fi

# PM2 (se instalado)
if command -v pm2 >/dev/null 2>&1; then
    alias pm='pm2'
    alias pms='pm2 start'
    alias pmst='pm2 stop'
    alias pmr='pm2 restart'
    alias pml='pm2 list'
    alias pmlog='pm2 logs'
    alias pmm='pm2 monit'
    alias pmd='pm2 delete'
    alias pmk='pm2 kill'
fi

# Forever (se instalado)
if command -v forever >/dev/null 2>&1; then
    alias fs='forever start'
    alias fst='forever stop'
    alias fr='forever restart'
    alias fl='forever list'
    alias flog='forever logs'
fi

# ======================
# TESTING
# ======================
# Jest (se instalado)
if command -v jest >/dev/null 2>&1; then
    alias j='jest'
    alias jw='jest --watch'
    alias jwc='jest --watchAll --coverage'
    alias jc='jest --coverage'
    alias ju='jest --updateSnapshot'
fi

# Mocha (se instalado)
if command -v mocha >/dev/null 2>&1; then
    alias m='mocha'
    alias mw='mocha --watch'
    alias mg='mocha --grep'
fi

# Cypress (se instalado)
if command -v cypress >/dev/null 2>&1; then
    alias cy='cypress'
    alias cyo='cypress open'
    alias cyr='cypress run'
fi

# Playwright (se instalado)
if command -v playwright >/dev/null 2>&1; then
    alias pw='playwright'
    alias pwt='playwright test'
    alias pwo='playwright test --ui'
fi

# ======================
# LINTING E FORMATAÇÃO
# ======================
# ESLint (se instalado)
if command -v eslint >/dev/null 2>&1; then
    alias es='eslint'
    alias esf='eslint --fix'
    alias esc='eslint --cache'
fi

# Prettier (se instalado)
if command -v prettier >/dev/null 2>&1; then
    alias pret='prettier'
    alias pretw='prettier --write'
    alias pretc='prettier --check'
fi

# Standard (se instalado)
if command -v standard >/dev/null 2>&1; then
    alias std='standard'
    alias stdf='standard --fix'
fi

# ======================
# BUILD TOOLS
# ======================
# Webpack (se instalado)
if command -v webpack >/dev/null 2>&1; then
    alias wp='webpack'
    alias wpd='webpack --mode development'
    alias wpp='webpack --mode production'
    alias wpw='webpack --watch'
    alias wps='webpack serve'
fi

# Vite (se instalado)
if command -v vite >/dev/null 2>&1; then
    alias v='vite'
    alias vd='vite dev'
    alias vb='vite build'
    alias vp='vite preview'
fi

# Parcel (se instalado)
if command -v parcel >/dev/null 2>&1; then
    alias par='parcel'
    alias pars='parcel serve'
    alias parb='parcel build'
fi

# Rollup (se instalado)
if command -v rollup >/dev/null 2>&1; then
    alias roll='rollup'
    alias rollc='rollup --config'
    alias rollw='rollup --watch'
fi

# ======================
# FRAMEWORKS ESPECÍFICOS
# ======================
# Next.js
alias next='npx next'
alias nextd='npx next dev'
alias nextb='npx next build'
alias nexts='npx next start'

# Nuxt.js
alias nuxt='npx nuxt'
alias nuxtd='npx nuxt dev'
alias nuxtb='npx nuxt build'
alias nuxts='npx nuxt start'
alias nuxtg='npx nuxt generate'

# React
alias cra='npx create-react-app'
alias react='npx create-react-app'

# Vue
alias vue='npx @vue/cli'
alias vuec='npx @vue/cli create'
alias vues='npx @vue/cli-service serve'
alias vueb='npx @vue/cli-service build'

# Angular
if command -v ng >/dev/null 2>&1; then
    alias ng='ng'
    alias ngs='ng serve'
    alias ngb='ng build'
    alias ngt='ng test'
    alias nge='ng e2e'
    alias ngg='ng generate'
fi

# Svelte
alias svelte='npx create-svelte'

# ======================
# UTILITÁRIOS
# ======================
# Servidor HTTP simples
alias serve='npx serve'
alias serve3000='npx serve -p 3000'
alias serve8080='npx serve -p 8080'

# Live Server
alias live='npx live-server'

# JSON Server
alias jsonserver='npx json-server'

# ======================
# FUNÇÕES ÚTEIS
# ======================

# Criar projeto Node.js básico
function nodeinit() {
    local project_name=${1:-"my-node-app"}
    
    mkdir -p "$project_name"
    cd "$project_name"
    
    # Inicializar package.json
    npm init -y
    
    # Criar estrutura básica
    mkdir -p src tests docs
    touch README.md
    touch .gitignore
    touch .env.example
    
    # Criar arquivo principal
    cat > src/index.js << 'EOF'
#!/usr/bin/env node

/**
 * Aplicação Node.js
 */

const main = () => {
    console.log('Hello, Node.js!');
};

if (require.main === module) {
    main();
}

module.exports = { main };
EOF

    # Criar teste básico
    cat > tests/index.test.js << 'EOF'
const { main } = require('../src/index');

describe('Main function', () => {
    test('should run without errors', () => {
        expect(() => main()).not.toThrow();
    });
});
EOF

    # Criar .gitignore
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
.nyc_output

# Grunt intermediate storage
.grunt

# Bower dependency directory
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons
build/Release

# Dependency directories
jspm_packages/

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.test
.env.production

# parcel-bundler cache
.cache
.parcel-cache

# next.js build output
.next

# nuxt.js build output
.nuxt

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
logs
*.log

# Build outputs
dist/
build/
EOF

    # Criar .env.example
    cat > .env.example << 'EOF'
# Environment variables example
NODE_ENV=development
PORT=3000
EOF

    # Atualizar package.json com scripts úteis
    npm pkg set scripts.start="node src/index.js"
    npm pkg set scripts.dev="nodemon src/index.js"
    npm pkg set scripts.test="jest"
    npm pkg set scripts.lint="eslint src/"
    npm pkg set scripts.lint:fix="eslint src/ --fix"
    
    echo "🚀 Projeto Node.js '$project_name' criado com sucesso!"
    echo "📋 Estrutura:"
    echo "   ├── src/index.js"
    echo "   ├── tests/index.test.js"
    echo "   ├── package.json"
    echo "   ├── .gitignore"
    echo "   ├── .env.example"
    echo "   └── README.md"
    echo ""
    echo "📦 Para instalar dependências de desenvolvimento:"
    echo "   npm install --save-dev nodemon jest eslint"
    echo ""
    echo "🏃 Para executar:"
    echo "   npm start      # Produção"
    echo "   npm run dev    # Desenvolvimento com nodemon"
    echo "   npm test       # Testes"
}

# Instalar dependências comuns para diferentes tipos de projeto
function nodecommon() {
    case "$1" in
        "web")
            npm install express cors helmet morgan dotenv
            npm install --save-dev nodemon
            echo "📦 Pacotes para desenvolvimento web instalados"
            ;;
        "api")
            npm install express cors helmet morgan dotenv express-rate-limit
            npm install --save-dev nodemon jest supertest
            echo "📦 Pacotes para API REST instalados"
            ;;
        "cli")
            npm install commander inquirer chalk
            npm install --save-dev jest
            echo "📦 Pacotes para aplicação CLI instalados"
            ;;
        "react")
            npx create-react-app .
            echo "📦 Projeto React criado"
            ;;
        "vue")
            npx @vue/cli create .
            echo "📦 Projeto Vue criado"
            ;;
        "next")
            npx create-next-app .
            echo "📦 Projeto Next.js criado"
            ;;
        *)
            echo "Uso: nodecommon [web|api|cli|react|vue|next]"
            ;;
    esac
}

# Verificar saúde do projeto Node.js
function nodecheck() {
    echo "🔍 Verificando projeto Node.js..."
    echo ""
    
    # Verificar Node.js
    echo "📗 Versão do Node.js:"
    node --version
    echo ""
    
    # Verificar NPM
    echo "📦 Versão do NPM:"
    npm --version
    echo ""
    
    # Verificar package.json
    if [[ -f "package.json" ]]; then
        echo "📋 package.json encontrado"
        echo "Dependências principais:"
        npm list --depth=0 --prod 2>/dev/null | grep -E "^[├└]" | head -10
        echo ""
        echo "Dependências de desenvolvimento:"
        npm list --depth=0 --dev 2>/dev/null | grep -E "^[├└]" | head -10
    else
        echo "⚠️  package.json não encontrado"
    fi
    echo ""
    
    # Verificar node_modules
    if [[ -d "node_modules" ]]; then
        echo "✅ node_modules presente"
    else
        echo "⚠️  node_modules não encontrado - execute 'npm install'"
    fi
    echo ""
    
    # Verificar scripts disponíveis
    if [[ -f "package.json" ]] && command -v jq >/dev/null 2>&1; then
        echo "🏃 Scripts disponíveis:"
        jq -r '.scripts | to_entries[] | "  \(.key): \(.value)"' package.json 2>/dev/null || echo "  (instale jq para ver scripts)"
    fi
    echo ""
    
    # Auditoria de segurança
    echo "🔒 Auditoria de segurança:"
    npm audit --audit-level moderate 2>/dev/null | head -5 || echo "  Nenhuma vulnerabilidade crítica encontrada"
}

# Limpar cache e reinstalar dependências
function nodeclean() {
    echo "🧹 Limpando projeto Node.js..."
    
    # Remover node_modules
    if [[ -d "node_modules" ]]; then
        rm -rf node_modules
        echo "✅ node_modules removido"
    fi
    
    # Remover package-lock.json
    if [[ -f "package-lock.json" ]]; then
        rm package-lock.json
        echo "✅ package-lock.json removido"
    fi
    
    # Limpar cache npm
    npm cache clean --force
    echo "✅ Cache NPM limpo"
    
    # Reinstalar dependências
    if [[ -f "package.json" ]]; then
        echo "📦 Reinstalando dependências..."
        npm install
        echo "✅ Dependências reinstaladas"
    fi
    
    echo "🎉 Limpeza concluída!"
}

# Atualizar todas as dependências
function nodeupdate() {
    echo "⬆️  Atualizando dependências..."
    
    # Verificar atualizações disponíveis
    npm outdated
    
    echo ""
    echo "Deseja atualizar? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        npm update
        echo "✅ Dependências atualizadas"
        
        # Auditoria após atualização
        npm audit fix
        echo "✅ Vulnerabilidades corrigidas"
    fi
}
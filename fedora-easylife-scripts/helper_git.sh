#!/bin/bash

# Git Helper - Interactive Git Management
# Facilita operações Git via menu interativo
# Usage: ./git-helper.sh ou git-help (se instalado)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verificar se está em repo git
check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}❌ Não está em um repositório Git${NC}"
        echo -e "${CYAN}💡 Execute 'git init' ou navegue para um repo existente${NC}"
        exit 1
    fi
}

# Header
show_header() {
    clear
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                     🚀 GIT HELPER                            ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Info do repo
    local repo_name=$(basename "$(git rev-parse --show-toplevel)")
    local branch=$(git branch --show-current)
    local status_count=$(git status --porcelain | wc -l)
    
    echo -e "${CYAN}📁 Repo: ${YELLOW}$repo_name${NC}"
    echo -e "${CYAN}🌿 Branch: ${YELLOW}$branch${NC}"
    echo -e "${CYAN}📊 Arquivos modificados: ${YELLOW}$status_count${NC}"
    echo ""
}

# Menu principal
show_main_menu() {
    echo -e "${BLUE}═══════════════════ MENU PRINCIPAL ═══════════════════${NC}"
    echo -e "${YELLOW}1.${NC}  📊 Status & Info"
    echo -e "${YELLOW}2.${NC}  📝 Add & Commit"
    echo -e "${YELLOW}3.${NC}  🚀 Push & Pull"
    echo -e "${YELLOW}4.${NC}  🌿 Branches"
    echo -e "${YELLOW}5.${NC}  🔄 Merge & Rebase"
    echo -e "${YELLOW}6.${NC}  📋 Logs & History"
    echo -e "${YELLOW}7.${NC}  🗂️  Stash"
    echo -e "${YELLOW}8.${NC}  ⚙️  Config & Remote"
    echo -e "${YELLOW}9.${NC}  🆘 Emergência (Reset/Revert)"
    echo -e "${YELLOW}0.${NC}  ❌ Sair"
    echo ""
    echo -ne "${PURPLE}Escolha uma opção [0-9]: ${NC}"
}

# 1. Status & Info
status_info() {
    clear
    echo -e "${BLUE}📊 STATUS & INFORMAÇÕES${NC}"
    echo -e "${BLUE}======================${NC}"
    echo ""
    
    echo -e "${CYAN}🔍 Git Status:${NC}"
    git status
    echo ""
    
    echo -e "${CYAN}📈 Commits ahead/behind:${NC}"
    git log --oneline @{u}.. 2>/dev/null && echo -e "${GREEN}↑ Commits para push${NC}" || echo -e "${YELLOW}✓ Atualizado com remote${NC}"
    git log --oneline ..@{u} 2>/dev/null && echo -e "${YELLOW}↓ Commits para pull${NC}" || true
    echo ""
    
    echo -e "${CYAN}🏷️  Último commit:${NC}"
    git log -1 --pretty=format:"%h - %s (%cr) <%an>" 2>/dev/null || echo "Nenhum commit ainda"
    echo ""
    
    read -p "Pressione Enter para continuar..."
}

# 2. Add & Commit
add_commit() {
    clear
    echo -e "${BLUE}📝 ADD & COMMIT${NC}"
    echo -e "${BLUE}===============${NC}"
    echo ""
    
    # Mostrar arquivos modificados
    if [ $(git status --porcelain | wc -l) -eq 0 ]; then
        echo -e "${GREEN}✅ Nenhuma alteração para commit${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi
    
    echo -e "${CYAN}📁 Arquivos modificados:${NC}"
    git status --short
    echo ""
    
    echo -e "${YELLOW}1.${NC} Add todos os arquivos (git add .)"
    echo -e "${YELLOW}2.${NC} Add arquivos específicos"
    echo -e "${YELLOW}3.${NC} Add interativo (git add -p)"
    echo -e "${YELLOW}4.${NC} Só commit (assumindo já fez add)"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-4]: ${NC}"
    
    read choice
    case $choice in
        1)
            git add .
            echo -e "${GREEN}✅ Todos os arquivos adicionados${NC}"
            ;;
        2)
            echo -e "${CYAN}Digite os arquivos (separados por espaço):${NC}"
            read -e files
            git add $files
            echo -e "${GREEN}✅ Arquivos adicionados: $files${NC}"
            ;;
        3)
            git add -p
            ;;
        4)
            echo -e "${CYAN}Assumindo que já fez git add...${NC}"
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
    
    # Verificar se tem algo no stage
    if [ $(git diff --cached --name-only | wc -l) -eq 0 ]; then
        echo -e "${YELLOW}⚠️ Nenhum arquivo no stage para commit${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    echo ""
    echo -e "${CYAN}📝 Arquivos no stage:${NC}"
    git diff --cached --name-only
    echo ""
    
    # Commit message
    echo -e "${CYAN}💬 Mensagem do commit:${NC}"
    read -e commit_msg
    
    if [ -z "$commit_msg" ]; then
        echo -e "${RED}❌ Mensagem não pode ser vazia${NC}"
        read -p "Pressione Enter..."
        return
    fi
    
    git commit -m "$commit_msg"
    echo -e "${GREEN}✅ Commit realizado com sucesso!${NC}"
    read -p "Pressione Enter..."
}

# 3. Push & Pull
push_pull() {
    clear
    echo -e "${BLUE}🚀 PUSH & PULL${NC}"
    echo -e "${BLUE}==============${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 📤 Push (enviar commits)"
    echo -e "${YELLOW}2.${NC} 📥 Pull (baixar commits)"
    echo -e "${YELLOW}3.${NC} 📤 Push --force-with-lease (seguro)"
    echo -e "${YELLOW}4.${NC} 📥 Pull --rebase"
    echo -e "${YELLOW}5.${NC} 🔄 Fetch (só baixar refs)"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}🚀 Fazendo push...${NC}"
            git push
            ;;
        2)
            echo -e "${CYAN}📥 Fazendo pull...${NC}"
            git pull
            ;;
        3)
            echo -e "${CYAN}🚀 Push force-with-lease (mais seguro)...${NC}"
            git push --force-with-lease
            ;;
        4)
            echo -e "${CYAN}📥 Pull com rebase...${NC}"
            git pull --rebase
            ;;
        5)
            echo -e "${CYAN}🔄 Fazendo fetch...${NC}"
            git fetch
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}❌ Opção inválida${NC}"
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 4. Branches
manage_branches() {
    clear
    echo -e "${BLUE}🌿 GERENCIAMENTO DE BRANCHES${NC}"
    echo -e "${BLUE}============================${NC}"
    echo ""
    
    echo -e "${CYAN}📋 Branches existentes:${NC}"
    git branch -v
    echo ""
    
    echo -e "${YELLOW}1.${NC} 🌱 Criar nova branch"
    echo -e "${YELLOW}2.${NC} 🔄 Trocar de branch"
    echo -e "${YELLOW}3.${NC} 📋 Listar todas as branches (local + remote)"
    echo -e "${YELLOW}4.${NC} 🗑️  Deletar branch"
    echo -e "${YELLOW}5.${NC} 📤 Push nova branch para remote"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Nome da nova branch:${NC}"
            read -e branch_name
            git checkout -b "$branch_name"
            echo -e "${GREEN}✅ Branch '$branch_name' criada e ativada${NC}"
            ;;
        2)
            echo -e "${CYAN}Nome da branch para trocar:${NC}"
            read -e branch_name
            git checkout "$branch_name"
            ;;
        3)
            echo -e "${CYAN}📋 Todas as branches:${NC}"
            git branch -a
            ;;
        4)
            echo -e "${CYAN}Nome da branch para deletar:${NC}"
            read -e branch_name
            echo -e "${YELLOW}⚠️ Tem certeza? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                git branch -d "$branch_name"
            fi
            ;;
        5)
            current_branch=$(git branch --show-current)
            echo -e "${CYAN}🚀 Push branch '$current_branch' para remote...${NC}"
            git push -u origin "$current_branch"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 5. Merge & Rebase
merge_rebase() {
    clear
    echo -e "${BLUE}🔄 MERGE & REBASE${NC}"
    echo -e "${BLUE}=================${NC}"
    echo ""
    
    current_branch=$(git branch --show-current)
    echo -e "${CYAN}Branch atual: ${YELLOW}$current_branch${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 🔄 Merge outra branch na atual"
    echo -e "${YELLOW}2.${NC} 📐 Rebase branch atual"
    echo -e "${YELLOW}3.${NC} ❌ Abortar merge em andamento"
    echo -e "${YELLOW}4.${NC} ❌ Abortar rebase em andamento"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-4]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Branch para fazer merge:${NC}"
            read -e branch_name
            git merge "$branch_name"
            ;;
        2)
            echo -e "${CYAN}Branch base para rebase:${NC}"
            read -e branch_name
            git rebase "$branch_name"
            ;;
        3)
            git merge --abort
            echo -e "${GREEN}✅ Merge abortado${NC}"
            ;;
        4)
            git rebase --abort
            echo -e "${GREEN}✅ Rebase abortado${NC}"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 6. Logs & History
logs_history() {
    clear
    echo -e "${BLUE}📋 LOGS & HISTÓRICO${NC}"
    echo -e "${BLUE}==================${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} 📜 Log resumido (oneline)"
    echo -e "${YELLOW}2.${NC} 📖 Log detalhado"
    echo -e "${YELLOW}3.${NC} 📊 Log gráfico"
    echo -e "${YELLOW}4.${NC} 🔍 Log de arquivo específico"
    echo -e "${YELLOW}5.${NC} 👤 Log por autor"
    echo -e "${YELLOW}6.${NC} 📅 Log por período"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-6]: ${NC}"
    
    read choice
    case $choice in
        1)
            git log --oneline -10
            ;;
        2)
            git log -5 --pretty=format:"%h - %s (%cr) <%an>"
            ;;
        3)
            git log --oneline --graph --all -10
            ;;
        4)
            echo -e "${CYAN}Nome do arquivo:${NC}"
            read -e filename
            git log --oneline -- "$filename"
            ;;
        5)
            echo -e "${CYAN}Nome do autor:${NC}"
            read -e author
            git log --author="$author" --oneline -10
            ;;
        6)
            echo -e "${CYAN}Período (ex: '2 weeks ago', 'yesterday'):${NC}"
            read -e period
            git log --since="$period" --oneline
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 7. Stash
manage_stash() {
    clear
    echo -e "${BLUE}🗂️  GERENCIAMENTO STASH${NC}"
    echo -e "${BLUE}======================${NC}"
    echo ""
    
    stash_count=$(git stash list | wc -l)
    echo -e "${CYAN}📦 Stashes salvos: ${YELLOW}$stash_count${NC}"
    
    if [ $stash_count -gt 0 ]; then
        echo ""
        git stash list
    fi
    echo ""
    
    echo -e "${YELLOW}1.${NC} 💾 Salvar stash"
    echo -e "${YELLOW}2.${NC} 📂 Aplicar último stash"
    echo -e "${YELLOW}3.${NC} 📋 Listar stashes"
    echo -e "${YELLOW}4.${NC} 🗑️  Deletar stash"
    echo -e "${YELLOW}5.${NC} 👀 Ver conteúdo do stash"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Mensagem para o stash (opcional):${NC}"
            read -e stash_msg
            if [ -z "$stash_msg" ]; then
                git stash
            else
                git stash save "$stash_msg"
            fi
            echo -e "${GREEN}✅ Stash salvo${NC}"
            ;;
        2)
            git stash pop
            echo -e "${GREEN}✅ Último stash aplicado e removido${NC}"
            ;;
        3)
            git stash list
            ;;
        4)
            echo -e "${CYAN}Índice do stash para deletar (0, 1, 2...):${NC}"
            read -e stash_index
            git stash drop "stash@{$stash_index}"
            ;;
        5)
            echo -e "${CYAN}Índice do stash para ver (0, 1, 2...):${NC}"
            read -e stash_index
            git stash show -p "stash@{$stash_index}"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 8. Config & Remote
config_remote() {
    clear
    echo -e "${BLUE}⚙️  CONFIGURAÇÕES & REMOTE${NC}"
    echo -e "${BLUE}=========================${NC}"
    echo ""
    
    echo -e "${CYAN}👤 Configuração atual:${NC}"
    echo "Nome: $(git config user.name)"
    echo "Email: $(git config user.email)"
    echo ""
    echo -e "${CYAN}🌐 Remotes:${NC}"
    git remote -v
    echo ""
    
    echo -e "${YELLOW}1.${NC} 👤 Alterar nome/email"
    echo -e "${YELLOW}2.${NC} 🌐 Adicionar remote"
    echo -e "${YELLOW}3.${NC} 🗑️  Remover remote"
    echo -e "${YELLOW}4.${NC} 📋 Ver todas as configurações"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-4]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${CYAN}Novo nome:${NC}"
            read -e new_name
            echo -e "${CYAN}Novo email:${NC}"
            read -e new_email
            git config user.name "$new_name"
            git config user.email "$new_email"
            echo -e "${GREEN}✅ Configuração atualizada${NC}"
            ;;
        2)
            echo -e "${CYAN}Nome do remote (ex: origin):${NC}"
            read -e remote_name
            echo -e "${CYAN}URL do remote:${NC}"
            read -e remote_url
            git remote add "$remote_name" "$remote_url"
            echo -e "${GREEN}✅ Remote '$remote_name' adicionado${NC}"
            ;;
        3)
            echo -e "${CYAN}Nome do remote para remover:${NC}"
            read -e remote_name
            git remote remove "$remote_name"
            echo -e "${GREEN}✅ Remote '$remote_name' removido${NC}"
            ;;
        4)
            git config --list | head -20
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# 9. Emergência
emergency() {
    clear
    echo -e "${RED}🆘 OPERAÇÕES DE EMERGÊNCIA${NC}"
    echo -e "${RED}=========================${NC}"
    echo ""
    echo -e "${YELLOW}⚠️ CUIDADO: Estas operações podem ser destrutivas!${NC}"
    echo ""
    
    echo -e "${YELLOW}1.${NC} ↩️  Reset soft (manter mudanças)"
    echo -e "${YELLOW}2.${NC} ⚡ Reset hard (PERDER mudanças)"
    echo -e "${YELLOW}3.${NC} 🔄 Revert último commit"
    echo -e "${YELLOW}4.${NC} 🧹 Limpar arquivos não rastreados"
    echo -e "${YELLOW}5.${NC} 💾 Reset para commit específico"
    echo -e "${YELLOW}0.${NC} Voltar"
    echo ""
    echo -ne "${PURPLE}Escolha [0-5]: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${YELLOW}⚠️ Reset soft para HEAD~1? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                git reset --soft HEAD~1
                echo -e "${GREEN}✅ Reset soft realizado${NC}"
            fi
            ;;
        2)
            echo -e "${RED}⚠️ ATENÇÃO: Isso vai PERDER todas as mudanças não commitadas!${NC}"
            echo -e "${YELLOW}Reset hard para HEAD? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                git reset --hard HEAD
                echo -e "${GREEN}✅ Reset hard realizado${NC}"
            fi
            ;;
        3)
            echo -e "${CYAN}🔄 Revertendo último commit...${NC}"
            git revert HEAD
            ;;
        4)
            echo -e "${YELLOW}⚠️ Limpar arquivos não rastreados? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                git clean -fd
                echo -e "${GREEN}✅ Arquivos limpos${NC}"
            fi
            ;;
        5)
            echo -e "${CYAN}Hash do commit para reset:${NC}"
            read -e commit_hash
            echo -e "${YELLOW}⚠️ Reset hard para $commit_hash? (y/N):${NC}"
            read -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                git reset --hard "$commit_hash"
                echo -e "${GREEN}✅ Reset para $commit_hash realizado${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Loop principal
main() {
    check_git_repo
    
    while true; do
        show_header
        show_main_menu
        
        read choice
        case $choice in
            1) status_info ;;
            2) add_commit ;;
            3) push_pull ;;
            4) manage_branches ;;
            5) merge_rebase ;;
            6) logs_history ;;
            7) manage_stash ;;
            8) config_remote ;;
            9) emergency ;;
            0) 
                echo -e "${GREEN}👋 Até mais!${NC}"
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
# ======================
# ATALHOS DE TECLADO ESTILO WINDOWS
# ======================
# Este arquivo configura atalhos de teclado similares ao Windows para ZSH
# Para usar, adicione esta linha ao seu ~/.zshrc:
# source ~/.config/zsh/keybindings.zsh

# ======================
# CONFIGURAÇÕES BÁSICAS
# ======================
# Garantir que estamos usando o modo emacs (padrão)
bindkey -e

# ======================
# NAVEGAÇÃO E SELEÇÃO
# ======================
# Ctrl+A - Selecionar tudo (ir ao início da linha)
bindkey '^A' beginning-of-line

# Ctrl+E - Ir ao final da linha
bindkey '^E' end-of-line

# Ctrl+Left/Right - Navegar por palavras
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^[[1;5D' backward-word     # Ctrl+Left

# Alt+Left/Right - Navegar por palavras (alternativo)
bindkey '^[[1;3C' forward-word      # Alt+Right
bindkey '^[[1;3D' backward-word     # Alt+Left

# Home/End - Início e fim da linha
bindkey '^[[H' beginning-of-line    # Home
bindkey '^[[F' end-of-line          # End

# ======================
# EDIÇÃO DE TEXTO
# ======================
# Ctrl+C - Copiar linha atual (kill-line, similar ao copiar)
bindkey '^C' kill-line

# Ctrl+X - Recortar linha
bindkey '^X' kill-whole-line

# Ctrl+V - Colar (yank)
bindkey '^V' yank

# Ctrl+Z - Desfazer
bindkey '^Z' undo

# Ctrl+Y - Refazer (redo)
bindkey '^Y' redo

# Ctrl+D - Deletar caractere à direita
bindkey '^D' delete-char

# Ctrl+H - Deletar caractere à esquerda (Backspace)
bindkey '^H' backward-delete-char

# Ctrl+W - Deletar palavra anterior
bindkey '^W' backward-kill-word

# Ctrl+K - Deletar do cursor até o final da linha
bindkey '^K' kill-line

# Ctrl+U - Deletar do cursor até o início da linha
bindkey '^U' backward-kill-line

# Delete - Deletar caractere à direita
bindkey '^[[3~' delete-char

# ======================
# HISTÓRICO DE COMANDOS
# ======================
# Ctrl+R - Busca reversa no histórico
bindkey '^R' history-incremental-search-backward

# Ctrl+S - Busca forward no histórico
bindkey '^S' history-incremental-search-forward

# Page Up/Down - Navegar no histórico
bindkey '^[[5~' up-line-or-history     # Page Up
bindkey '^[[6~' down-line-or-history   # Page Down

# Up/Down - Histórico baseado no que já foi digitado
bindkey '^[[A' up-line-or-search       # Up Arrow
bindkey '^[[B' down-line-or-search     # Down Arrow

# ======================
# FUNCIONALIDADES ESPECIAIS
# ======================
# Ctrl+L - Limpar tela
bindkey '^L' clear-screen

# Ctrl+T - Trocar caracteres (transpose)
bindkey '^T' transpose-chars

# Alt+T - Trocar palavras
bindkey '^[t' transpose-words

# Ctrl+_ - Desfazer última ação
bindkey '^_' undo

# ======================
# TAB COMPLETION MELHORADO
# ======================
# Tab - Completar comando
bindkey '^I' expand-or-complete

# Shift+Tab - Completar reverso
bindkey '^[[Z' reverse-menu-complete

# ======================
# FUNÇÕES PERSONALIZADAS
# ======================

# Função para criar novo arquivo (Ctrl+N)
function new-file() {
    echo -n "Nome do arquivo: "
    read filename
    if [[ -n $filename ]]; then
        touch "$filename"
        echo "Arquivo '$filename' criado."
    fi
}
zle -N new-file
bindkey '^N' new-file

# Função para abrir arquivo/diretório (Ctrl+O)
function open-file() {
    if [[ -f "$BUFFER" ]]; then
        xdg-open "$BUFFER" &>/dev/null &
        zle clear-screen
    elif [[ -d "$BUFFER" ]]; then
        cd "$BUFFER"
        zle clear-screen
        zle reset-prompt
    else
        echo -n "Arquivo/Diretório: "
        read target
        if [[ -f "$target" ]]; then
            xdg-open "$target" &>/dev/null &
        elif [[ -d "$target" ]]; then
            cd "$target"
            zle reset-prompt
        else
            echo "Arquivo ou diretório não encontrado: $target"
        fi
    fi
}
zle -N open-file
bindkey '^O' open-file

# Função para salvar comando no histórico sem executar (Ctrl+S alternativo)
function save-command() {
    print -s "$BUFFER"
    zle kill-whole-line
    echo "Comando salvo no histórico"
}
zle -N save-command
bindkey '^[s' save-command  # Alt+S

# Função para duplicar linha atual (Ctrl+Shift+D)
function duplicate-line() {
    local current_line="$BUFFER"
    BUFFER="$current_line"$'\n'"$current_line"
    CURSOR=${#current_line}
}
zle -N duplicate-line
bindkey '^[[1;6D' duplicate-line  # Ctrl+Shift+D (pode variar por terminal)

# Função para capitalizar palavra (Alt+C)
function capitalize-word() {
    zle vi-forward-word
    zle vi-backward-word
    zle capitalize-word
}
zle -N capitalize-word
bindkey '^[c' capitalize-word

# ======================
# NAVEGAÇÃO DE DIRETÓRIOS ESTILO WINDOWS
# ======================

# Função para navegar para diretório pai (Alt+Up)
function parent-dir() {
    cd ..
    zle reset-prompt
    ls
}
zle -N parent-dir
bindkey '^[[1;3A' parent-dir  # Alt+Up

# Função para voltar ao diretório anterior (Alt+Left)
function previous-dir() {
    cd -
    zle reset-prompt
    ls
}
zle -N previous-dir
bindkey '^[h' previous-dir  # Alt+H (mais compatível)

# Função para listar diretórios (Alt+L)
function list-dirs() {
    echo
    if command -v eza >/dev/null 2>&1; then
        eza -D --icons
    else
        ls -d */
    fi
    zle reset-prompt
}
zle -N list-dirs
bindkey '^[l' list-dirs

# ======================
# UTILITÁRIOS RÁPIDOS
# ======================

# Ctrl+Alt+T - Novo terminal (simula o atalho do Windows)
function new-terminal() {
    if command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal &
    elif command -v konsole >/dev/null 2>&1; then
        konsole &
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        xfce4-terminal &
    elif command -v alacritty >/dev/null 2>&1; then
        alacritty &
    else
        echo "Terminal padrão não encontrado"
    fi
}
zle -N new-terminal
bindkey '^[^T' new-terminal  # Alt+Ctrl+T

# Ctrl+Shift+C - Copiar caminho atual
function copy-pwd() {
    pwd | tr -d '\n' | xclip -selection clipboard 2>/dev/null || echo "$(pwd)" 
    echo "Caminho copiado: $(pwd)"
}
zle -N copy-pwd
bindkey '^[[1;6C' copy-pwd  # Ctrl+Shift+C (pode variar)

# Alt+Enter - Executar comando em background
function run-background() {
    BUFFER="$BUFFER &"
    zle accept-line
}
zle -N run-background
bindkey '^[^M' run-background  # Alt+Enter

# ======================
# CONFIGURAÇÕES ADICIONAIS
# ======================

# Melhorar a busca no histórico
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Auto-completar com cores
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Avisar sobre atalhos disponíveis na primeira execução
if [[ ! -f ~/.config/zsh/.keybindings_shown ]]; then
    echo "🎯  Atalhos de teclado estilo Windows carregados!"
    echo "   Principais: Ctrl+A (início), Ctrl+E (fim), Ctrl+R (histórico)"
    echo "   Navegação: Alt+Up (diretório pai), Alt+H (voltar)"
    echo "   Use 'bindkey' para ver todos os atalhos"
    mkdir -p ~/.config/zsh
    touch ~/.config/zsh/.keybindings_shown
fi
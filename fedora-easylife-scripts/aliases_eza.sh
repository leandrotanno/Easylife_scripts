# ======================
# ALIASES EZA (LS MELHORADO)
# ======================
# Verificar se o eza está instalado antes de aplicar os aliases
if command -v eza >/dev/null 2>&1; then
  # Aliases básicos
  alias ls='eza'                                                           # ls
  alias l='eza -l --icons --group-directories-first'                       # lista detalhada
  alias la='eza -la --icons --group-directories-first'                     # mostrar ocultos
  alias ll='eza -l --icons --group-directories-first'                      # lista longa
  alias lla='eza -la --icons --group-directories-first'                    # lista longa com ocultos
  
  # Classificação e ordenação
  alias lt='eza --tree --icons --git-ignore'                               # visualização em árvore
  alias lta='eza --tree --icons'                                           # árvore com arquivos ocultos
  alias ltd='eza --tree --icons --git-ignore -D'                           # árvore só com diretórios
  alias llt='eza -l --tree --icons --git-ignore'                           # lista longa em árvore
  
  # Classificar arquivos
  alias lS='eza -l --icons --sort=size --group-directories-first'          # ordenar por tamanho
  alias lm='eza -l --icons --sort=modified --group-directories-first'      # ordenar por data de modificação
  alias lc='eza -l --icons --sort=created --group-directories-first'       # ordenar por data de criação
  alias le='eza -l --icons --sort=extension --group-directories-first'     # ordenar por extensão
  
  # Filtros especiais
  alias ld='eza -lD --icons'                                               # listar apenas diretórios
  alias lf='eza -lf --icons'                                               # listar apenas arquivos
  alias lh='eza -l --icons | head'                                         # mostrar primeiros 10 arquivos
  alias lsd='eza -D'                                                       # listar só diretórios (formato compacto)
  
  # Integração com Git
  alias lg='eza -l --icons --git --git-ignore'                             # mostrar status do Git
  alias lga='eza -la --icons --git'                                        # mostrar status do Git incluindo ocultos
  alias lgd='eza -l --icons --git-ignore --only-dirs --git'                # status git só para diretórios
  
  # Formatos avançados
  alias lb='eza -l --icons --binary'                                       # mostrar tamanhos em binário (KiB, MiB)
  alias lbh='eza -l --icons --binary --header'                             # com cabeçalho explicativo
  alias lhg='eza -l --icons --header --grid'                               # formato grid com cabeçalho
  alias lx='eza -l --icons --extended'                                     # mostrar metadados estendidos
  
  # Combinações úteis
  alias lr='eza -l --icons --sort=modified --reverse'                      # mais recentes por último
  alias lR='eza -l --icons --sort=modified'                                # mais recentes primeiro
  alias lz='eza -l --icons --sort=size --reverse'                          # menores primeiro
  alias lZ='eza -l --icons --sort=size'                                    # maiores primeiro
  alias l1='eza -1'                                                        # um arquivo por linha
  
  # Formatação e cores customizadas
  alias lc1='eza -1 --icons --color=always | grep -E "^\S+"'               # colorido, listagem compacta
  alias lcl='eza --color=always --icons | less -R'                         # paginado com cores
else
  # Fallback para os aliases ls padrão caso eza não esteja instalado
  alias ls='ls --color=auto'
  alias l='ls -lah'
  alias ll='ls -lh'
  alias la='ls -lAh'
  alias ld='ls -ld */'               # Lista apenas diretórios
fi

# ======================
# NAVEGAÇÃO
# ======================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'
alias cd.='cd $(readlink -f .)'    # Resolve diretório com links simbólicos

# ======================
# GERENCIAMENTO DE ARQUIVOS
# ======================
alias rm='rm -i'                   # Pede confirmação antes de remover
alias cp='cp -i'                   # Pede confirmação antes de sobrescrever
alias mv='mv -i'                   # Pede confirmação antes de sobrescrever
alias mkdir='mkdir -p'             # Cria diretórios pai se necessário
alias md='mkdir -p'
alias rd='rmdir'
alias df='df -h'                   # Mostra em formato humano (GB, MB)
alias du='du -h'                   # Mostra em formato humano (GB, MB)
alias dud='du -d 1 -h'             # Mostra tamanho dos diretórios no nível atual
alias duf='du -sh *'               # Mostra tamanho dos arquivos no diretório atual

# ======================
# BUSCA
# ======================
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ff='find . -type f -name'    # Busca arquivos ex: ff "*.txt"
alias fd='find . -type d -name'    # Busca diretórios ex: fd "projeto*"
alias h='history | grep'           # Busca no histórico ex: h ssh

# ======================
# GIT
# ======================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gc='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gf='git fetch'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'
alias gcl='git clone'
alias gst='git stash'
alias gstp='git stash pop'
alias grh='git reset HEAD'
alias gpom='git push origin master'
alias glast='git log -1 HEAD'      # Mostra último commit

# ======================
# DOCKER
# ======================
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dip='docker image prune -a'  # Remove imagens não usadas
alias dvp='docker volume prune'    # Remove volumes não usados
alias dsp='docker system prune'    # Limpa tudo não usado

# ======================
# SISTEMA
# ======================
alias path='echo -e ${PATH//:/\\n}'
alias ports='netstat -tulanp'      # Mostra portas abertas
alias mem='free -m'                # Uso de memória
alias cpu='top -bn1 | grep "Cpu(s)"' # Uso de CPU
alias psg='ps aux | grep'          # Procura processo ex: psg firefox
alias ssha='eval $(ssh-agent) && ssh-add'
alias ping='ping -c 5'             # Ping com 5 pacotes
alias ipe='curl ipinfo.io/ip'      # Mostra IP externo
alias ipi='hostname -I | cut -d" " -f1'  # IP interno (Linux)

# ======================
# UTILITÁRIOS
# ======================
alias c='clear'
alias cls='clear;ls'
alias e='exit'
alias vim='nvim'                   # Usar neovim se instalado
alias vi='nvim'
alias v='nvim'
alias sz='source ~/.zshrc'         # Recarrega zsh
alias ez='nvim ~/.zshrc'           # Edita zshrc
alias ea='nvim ~/.config/zsh/eza_aliases.zsh'  # Edita aliases do eza
alias update='sudo apt update && sudo apt upgrade' # Ubuntu/Debian
# alias update='brew update && brew upgrade'       # macOS
# alias update='sudo pacman -Syu'                 # Arch

# ======================
# PERFORMANCE
# ======================
alias wget='wget -c'               # Continua downloads interrompidos
alias http='python3 -m http.server' # Servidor HTTP simples na porta 8000

# ======================
# ATALHOS ÚTEIS
# ======================
alias zz='z -'                     # Volta para o último diretório (com z instalado)
alias todo='grep -r "TODO:" --include="*.{js,py,rb,go,java,c,cpp,h}" .'
alias weather='curl wttr.in'       # Previsão do tempo no terminal
alias myip='curl http://ipecho.net/plain; echo'
alias lsblk='lsblk -o name,mountpoint,label,size,uuid' # Informações detalhadas sobre discos

# ======================
# ASSOCIAÇÃO DE ARQUIVOS (ZSH)
# ======================
alias -s {md,txt}=nvim             # Abre arquivos .md e .txt com nvim
alias -s {jpg,jpeg,png,gif}=xdg-open   # Abre imagens com o aplicativo padrão
alias -s {html,htm}=xdg-open           # Abre HTML com navegador padrão
alias -s {pdf}=xdg-open               # Abre PDF com o aplicativo padrão

# ======================
# FUNÇÕES ÚTEIS 
# ======================
# Cria e entra no diretório
function mkcd() { mkdir -p "$1" && cd "$1"; }

# Extrai qualquer arquivo compactado
function extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' não pode ser extraído via extract()" ;;
    esac
  else
    echo "'$1' não é um arquivo válido"
  fi
}

# Cria um backup de um arquivo
function bak() {
  cp "$1"{,.bak}
}
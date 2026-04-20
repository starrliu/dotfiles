# ═══════════════════════════════════════════
# ~/.zshrc
# ═══════════════════════════════════════════

# ── 1. 环境变量 ─────────────────────────────
export EDITOR='vim'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ── 2. 历史记录 ─────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY

# ── 3. 目录行为 ─────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CDABLE_VARS

# ── 4. 其他选项 ─────────────────────────────
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# ── 5. 补全系统 ─────────────────────────────
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zmodload zsh/complist

# ── 6. 键位绑定 ─────────────────────────────
bindkey -e
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Ctrl+左/右：按单词移动光标
bindkey "^[[1;5C" forward-word      # Ctrl+Right
bindkey "^[[1;5D" backward-word     # Ctrl+Left
# 兼容不同终端（如 tmux, screen, 某些 xterm）
bindkey "^[^[[C" forward-word       # Esc+Right (某些终端)
bindkey "^[^[[D" backward-word      # Esc+Left (某些终端)

# Home/End 键
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[1~" beginning-of-line   # 兼容
bindkey "^[[4~" end-of-line         # 兼容

# Delete 键
bindkey "^[[3~" delete-char

# ── 7. Alias ────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lhF'
alias la='ls -lahF'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias ..='cd ..'
alias ...='cd ../..'
alias zshrc='${EDITOR} ~/.zshrc'
alias reload='source ~/.zshrc'

# ── 8. Prompt ───────────────────────────────
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{red}(%b|%a)%f'
setopt PROMPT_SUBST
_conda_prompt() {
    [[ -n "$CONDA_DEFAULT_ENV" ]] && print -n "[%B%F{cyan}${CONDA_DEFAULT_ENV}%f%b] "
}
PROMPT='$(_conda_prompt)%F{blue}%~%f${vcs_info_msg_0_} %F{%(?.green.red)}%#%f '

# ── 9. 插件 ─────────────────────────────────
if [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# ── 10. 工具初始化 ───────────────────────────
# syntax-highlighting 必须最后 source
if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ── 11. 本地配置 ─────────────────────────────
# 主机特定配置（conda, nvm, fzf 等）放在 .zshrc.local
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
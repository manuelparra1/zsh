export BAT_THEME="Catppuccin Mocha"

# export QT_QPA_PLATFORM=xcb vlc
alias ls='eza -1rs oldest'
alias ll='eza -lhs newest'
alias zmv='mv "$@" "$(zoxide query -i)"'

export CLICOLOR=true

# Add ~/.local/bin to PATH for custom scripts
export PATH="$HOME/.local/bin:$PATH"
path+=('/Users/dusts/.bin')

alias chatgpt4o-mini='chatgpt.sh -i "respond in a simple and concise manner" --model gpt-4o-mini --max-tokens 500'
alias chatgpt4o='chatgpt.sh -i "respond in a simple and concise manner" --model chatgpt-4o-latest --max-tokens 250'

# BlueBirdBack/groq
alias groq='python ~/.bin/groq/scripts/run_groq.py short'

find_nearby() {
    local term1 term2 target_dir selected_file

    print -n "\033[1;36mSearch Files for (Primary Term):\033[0m "
    read -r term1
    [[ -z "$term1" ]] && return 1

    print -n "\033[1;35mSearch within those results for (Secondary Term):\033[0m "
    read -r term2
    [[ -z "$term2" ]] && return 1

    target_dir="${1:-.}"

    # 1. The Fast Filter (Now restricted to Markdown and TXT files)
    selected_file=$(
        rg -t md -i -l --null "$term1" "$target_dir" 2>/dev/null |
        xargs -0 -r rg -i -l "$term2" 2>/dev/null |
        
        while IFS= read -r file; do
            awk -v t1="$term1" -v t2="$term2" '
                BEGIN { 
                    t1 = tolower(t1); 
                    t2 = tolower(t2); 
                    min_dist = 999999 
                }
                
                {
                    lower_line = tolower($0)
                    if (lower_line ~ t1) lines1[++count1] = FNR
                    if (lower_line ~ t2) lines2[++count2] = FNR
                }
                
                END {
                    for (i=1; i<=count1; i++) {
                        for (j=1; j<=count2; j++) {
                            dist = lines1[i] - lines2[j]
                            if (dist < 0) dist = -dist
                            if (dist < min_dist) min_dist = dist
                        }
                    }
                    printf "%05d:%s\n", min_dist, FILENAME
                }
            ' "$file"
        done |
        
        sort -n |
        cut -d':' -f2- |
        
        fzf --preview "rg -i -C 3 --color=always '$term2' {}" \
            --preview-window="right:60%:wrap" \
            --header="Ranked by proximity: '$term1' + '$term2'" \
            --prompt="Filter files > "
    )

    if [[ -n "$selected_file" ]]; then
        nvim "$selected_file"
    fi
}

search() {
    local rg_flags=()
    local pos_args=()
    
    # 1. Parse arguments: separate hyphenated flags from text
    for arg in "$@"; do
        if [[ "$arg" == -* ]]; then
            rg_flags+=("$arg")
        else
            pos_args+=("$arg")
        fi
    done

    # Fail gracefully if no query is provided
    if [[ ${#pos_args[@]} -eq 0 ]]; then
        echo "Usage: search [flags] <query> [directory]"
        echo "Example: search -H \"sla.*dynamic\" ."
        return 1
    fi

    # 2. Assign the positional arguments (Zsh uses 1-based arrays)
    local query="${pos_args[1]}"
    local target="."
    if [[ ${#pos_args[@]} -ge 2 ]]; then
        target="${pos_args[2]}"
    fi

    # 3. Create the FZF proximity filter (strip all symbols)
    # Converts "search.*regex" into "searchregex"
    local fzf_filter=$(echo "$query" | sed 's/[^a-zA-Z0-9]//g')

    # 4. Create the Highlight query 
    # Converts "search.*regex" into "search|regex"
    local hl_query=$(echo "$query" | grep -oE '[a-zA-Z0-9]+' | paste -sd '|' -)

    # 5. The Pipeline
    rg -n -i -M 120 "${rg_flags[@]}" "$query" "$target" 2>/dev/null | \
    fzf --filter="$fzf_filter" | \
    head -n 5 | \
    tail -r | \
    awk -F':' '{
        filepath = $1;
        line = $2;
        
        # Clean up the home directory path
        sub(ENVIRON["HOME"], "~", filepath);
        
        # Isolate the filename
        n = split(filepath, path_array, "/");
        filename = path_array[n];
        
        # Strip the filepath and line number from the main content
        sub(/^[^:]*:[^:]*:/, "", $0);
        content = $0;
        
        # Print the styled block
        printf "\033[1;35m%s\033[0m\n", filename;
        printf "\033[2;37m%s:%s\033[0m\n\n", filepath, line;
        printf "  %s\n\n", content;
        printf "\033[38;5;239m────────────────────────────────────────────────────────────────────────────────\033[0m\n\n";
    }' | rg --passthru -i --color=always -e "$hl_query"
}

fzfvim() {
    local query="${1:-}"
    
    FZF_DEFAULT_COMMAND="fd -H --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc" \
    FZF_DEFAULT_OPTS="--preview 'bat --style=numbers --color=always {}' --bind 'change:reload:fd -H --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc {q} || true'" \
    fzf --ansi --phony --query="$query" --exit-0 | while IFS= read -r file; do
        nvim "$file"
    done
}

livegrep() {
    # 1. Define the ripgrep command.
    # It outputs file:line:column:content. 
    # We use a glob to restrict it to your preferred file types instead of fd.
    local RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case -g '*.{md,lua,txt,sh,py,cpp,json,conf,zshrc,js,ts,html,css,yml,yaml,xml,toml,ini,cfg,log,sql,rs,go,java,c,h,rb,php,pl,vim,rc}'"

    # 2. Launch fzf
    # --disabled: Starts fzf with its fuzzy-engine turned off (acting like --phony).
    fzf --ansi --disabled --query '' \
        --prompt '1. ripgrep (regex)> ' \
        --bind "start:reload:$RG_PREFIX {q} 2>/dev/null || true" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} 2>/dev/null || true" \
        --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf (fuzzy)> )+enable-search+clear-query" \
        --delimiter ':' \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null' \
        --preview-window 'right:50%:wrap,+{2}-5' \
        --bind 'enter:execute:nvim "+{2}" {1}'
}


# Most Used API Keys


# Often Used API Keys

# Other Used API Keys

# =================================================================================================
# ZenSH
# =================================================================================================

# Plugin Settings

# fzf-tab
autoload -Uz compinit && compinit

# ZSH Plugins
source ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source ~/.config/zsh/plugins/zsh-completions/zsh-completions.plugin.zsh
source ~/.config/zsh/plugins/zsh-groq-llm/zsh-llm-suggestions.zsh

# Plugin Keybindings
bindkey '^o' zsh_llm_suggestions_groq # Ctrl + O to have Groq suggest a command

# Plugin Settings
# zsh-completions - Load completions
fpath=(~/.config/zsh/plugins/zsh-completions/src $fpath)

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Shell integrations
# eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# =================================================================================================
# ZenSH
# =================================================================================================

#  Settings
# if [[ "$TERM" == "xterm-kitty" || "$TERM" == "xterm-256color" || "$TERM_PROGRAM" == "WarpTerminal" ]]; then
# # if [[ "$TERM" == "xterm-kitty" || "$TERM" == "tmux-256color" || "$TERM_PROGRAM" == "WarpTerminal" ]]; then
#     # export TERM=xterm-256color
#     eval "$(starship init zsh)"
# fi

#eval "$(zoxide init zsh)"

export TERM="xterm-256color"

# ==================================================================================================
# Custom Prompt
# ==================================================================================================
#
setopt PROMPT_SUBST

mantle="#181825"
crust="#11111b"
surface0="#313244"
surface1="#45475a"
subtext0="#a6adc8"
overlay0="#6c7086"

os_icon() {
  case "$OSTYPE" in
    darwin*) print "" ;;
    linux*)  print "󰌽" ;;
    *)       print "" ;;
  esac
}

short_pwd() {
  local dir="${PWD/#$HOME/~}"
  local base="${dir:t}"

  case "$base" in
    Documents) print "󰈙 " ;;
    Downloads) print " " ;;
    Music) print "󰝚 " ;;
    Pictures) print " " ;;
    Developer) print "󰲋 " ;;
    "~") print "~" ;;
    "/") print "/" ;;
    *) print "…/$base" ;;
  esac
}

PROMPT='%F{$mantle}%K{$mantle}%F{$subtext0}$(os_icon)%F{$overlay0} %n %k'
PROMPT+='%F{$mantle}%K{$surface0}%F{$crust} $(short_pwd) %k'
PROMPT+='%F{$surface0}%K{$crust}%F{$surface1}  %D{%H:%M} %k'
PROMPT+='%F{$crust}%f '

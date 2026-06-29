
zsh_llm_suggestions_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'

    cleanup() {
      kill $pid
      echo -ne "\e[?25h"
    }
    trap cleanup SIGINT
    
    echo -ne "\e[?25l"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"

    echo -ne "\e[?25h"
    trap - SIGINT
}

zsh_llm_suggestions_run_query() {
  local llm="$1"
  local query="$2"
  local result_file="$3"
  local mode="$4"
  echo -n "$query" | eval $llm $mode > $result_file
}

zsh_llm_completion() {
  local llm="$1"
  local mode="$2"
  local query=${BUFFER}

  # Empty prompt, nothing to do
  if [[ "$query" == "" ]]; then
    return
  fi

  # If the prompt is the last suggestions, just get another suggestion for the same query
  if [[ "$mode" == "generate" ]]; then
    if [[ "$query" == "$ZSH_LLM_SUGGESTIONS_LAST_RESULT" ]]; then
      query=$ZSH_LLM_SUGGESTIONS_LAST_QUERY
    else
      ZSH_LLM_SUGGESTIONS_LAST_QUERY="$query"
    fi
  fi

  # Temporary file to store the result of the background process
  local result_file="/tmp/zsh-llm-suggestions-result"
  # Run the actual query in the background (since it's long-running, and so that we can show a spinner)
  read < <( zsh_llm_suggestions_run_query $llm $query $result_file $mode & echo $! )
  # Get the PID of the background process
  local pid=$REPLY
  # Call the spinner function and pass the PID
  zsh_llm_suggestions_spinner $pid
  
  if [[ "$mode" == "generate" ]]; then
    print -s $query
    ZSH_LLM_SUGGESTIONS_LAST_RESULT=$(cat $result_file)
    BUFFER="${ZSH_LLM_SUGGESTIONS_LAST_RESULT}"
    CURSOR=${#ZSH_LLM_SUGGESTIONS_LAST_RESULT}
  elif [[ "$mode" == "explain" ]]; then
    echo ""
    eval "cat $result_file"
    echo ""
    zle reset-prompt
  elif [[ "$mode" == "script" ]]; then
    local script_path=$(cat $result_file)
    BUFFER="zsh $script_path"
    CURSOR=${#BUFFER}
    zle reset-prompt
    echo "\nShell script generated and saved to: $script_path"
    echo "The command to execute script has been added to your prompt."
    echo "Press Enter to execute, or modify as needed."
  fi
}

SCRIPT_DIR=$( cd -- "$( dirname -- "$0" )" &> /dev/null && pwd )

zsh_llm_suggestions_groq() {
  zsh_llm_completion "$SCRIPT_DIR/zsh-llm-suggestions-groq.py" "generate"
}

zsh_llm_suggestions_groq_script() {
  zsh_llm_completion "$SCRIPT_DIR/zsh-llm-suggestions-groq.py" "script"
}

zsh_llm_suggestions_anthropic() {
  zsh_llm_completion "$SCRIPT_DIR/zsh-llm-suggestions-anthropic.py" "generate"
}

zsh_llm_suggestions_github_copilot() {
  zsh_llm_completion "$SCRIPT_DIR/zsh-llm-suggestions-github-copilot.py" "generate"
}

zsh_llm_suggestions_openai_explain() {
  zsh_llm_completion "$SCRIPT_DIR/zsh-llm-suggestions-openai.py" "explain"
}

zsh_llm_suggestions_github_copilot_explain() {
  zsh_llm_completion "$SCRIPT_DIR/zsh-llm-suggestions-github-copilot.py" "explain"
}

#zle -N zsh_llm_suggestions_anthropic
zle -N zsh_llm_suggestions_groq
zle -N zsh_llm_suggestions_groq_script

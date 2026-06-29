# Instalační příručka pro ZSH LLM Suggestions

## Požadavky
- Nainstalovaný ZSH shell
- Python 3.8 nebo novější
- pip (Python package manager)
- Git

## Instalační kroky

### 1. Vytvoření adresáře pro ZSH pluginy
```bash
mkdir -p ~/.zsh
cd ~/.zsh
```

### 2. Klonování repozitáře
```bash
git clone https://gitlab.apertia.cz/dstrejc/zsh-groq-llm.git
cd zsh-llm-suggestions
```

### 3. Instalace Python závislostí
```bash
pip install groq pygments
```

### 4. Nastavení API klíčů
Přidejte následující řádky do vašeho `~/.zshrc`:
```bash
export GROQ_API_KEY="váš-groq-api-klíč"
```

### 5. Konfigurace ZSH
Přidejte následující řádky na konec vašeho `~/.zshrc`:
```bash
# LLM Suggestions
source ~/.zsh/zsh-llm-suggestions/zsh-llm-suggestions.zsh

# Klávesové zkratky
bindkey '^G' zsh_llm_suggestions_groq           # Ctrl+G pro generování příkazů
bindkey '^X^G' zsh_llm_suggestions_groq_script  # Ctrl+X Ctrl+G pro generování skriptů
```

### 6. Aktivace změn
```bash
source ~/.zshrc
```

## Ověření instalace
1. Otevřete nový terminál
2. Stiskněte Ctrl+G pro generování příkazů
3. Stiskněte Ctrl+X Ctrl+G pro generování skriptů

## Řešení problémů

### Chybějící API klíč
Pokud vidíte chybu o chybějícím API klíči:
1. Jděte na [Groq Dashboard](https://console.groq.com)
2. Vytvořte nový API klíč
3. Zkopírujte ho do vašeho `~/.zshrc`

### Chybějící závislosti
Pokud vidíte chyby o chybějících Python modulech:
```bash
pip install --user groq pygments
```

### Oprávnění
Pokud máte problémy s oprávněními:
```bash
chmod +x ~/.zsh/zsh-llm-suggestions/*.py
chmod +x ~/.zsh/zsh-llm-suggestions/*.zsh
```

## Použití

### Generování příkazů
1. Napište popis požadovaného příkazu do terminálu
2. Stiskněte Ctrl+G
3. Počkejte na vygenerování příkazu
4. Stiskněte Enter pro spuštění nebo upravte příkaz dle potřeby

### Generování skriptů
1. Napište popis požadovaného skriptu
2. Stiskněte Ctrl+X Ctrl+G
3. Skript bude vygenerován a uložen do /tmp
4. Příkaz pro spuštění skriptu bude automaticky vložen do promptu

## Odinstalace
Pro odstranění rozšíření:
```bash
rm -rf ~/.zsh/zsh-llm-suggestions
```
A odstraňte přidané řádky z vašeho `~/.zshrc`

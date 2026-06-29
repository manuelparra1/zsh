#!/usr/bin/env python3
import sys
import os
import anthropic

MISSING_PREREQUISITES = "zsh-llm-suggestions missing prerequisites:"

def highlight_explanation(explanation):
    try:
        import pygments
        from pygments.lexers import MarkdownLexer
        from pygments.formatters import TerminalFormatter
        return pygments.highlight(explanation, MarkdownLexer(), TerminalFormatter(style='material'))
    except ImportError:
        return explanation

def main():
    mode = sys.argv[1]
    if mode not in ['generate', 'explain']:
        print(f"ERROR: something went wrong in zsh-llm-suggestions, please report a bug. Got unknown mode: {mode}")
        return

    api_key = os.environ.get('ANTHROPIC_API_KEY')
    if api_key is None:
        print(f'echo "{MISSING_PREREQUISITES} ANTHROPIC_API_KEY is not set." && export ANTHROPIC_API_KEY="<copy from Anthropic dashboard>"')
        return

    client = anthropic.Anthropic(api_key=api_key)

    buffer = sys.stdin.read()

    system_message = """You are a zsh shell expert, please write a ZSH command that solves my problem.
You should only output the completed command, no need to include any other explanation."""
    if mode == 'explain':
        system_message = """You are a zsh shell expert, please briefly explain how the given command works. Be as concise as possible. Use Markdown syntax for formatting."""

    response = client.messages.create(
        model="claude-3-haiku-20240307",
        max_tokens=1000,
        temperature=0.2,
        system=system_message,
        messages=[
            {"role": "user", "content": buffer}
        ]
    )

    result = response.content[0].text.strip()

    if mode == 'generate':
        result = result.replace('```zsh', '').replace('```', '').strip()
        print(result)
    if mode == 'explain':
        print(highlight_explanation(result))

if __name__ == '__main__':
    main()

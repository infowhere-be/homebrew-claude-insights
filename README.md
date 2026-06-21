# homebrew-claude-insights

Tap Homebrew oficial do InfoWhere para o `claude-insights` — um dashboard em tempo real para sessões do Claude Code.

## Instalação

```bash
brew tap infowhere-be/claude-insights
brew install claude-insights
```

Em alternativa, pode instalar diretamente sem adicionar o tap:

```bash
brew install infowhere-be/claude-insights/claude-insights
```

Após a instalação, instale o hook do Claude Code e inicie o dashboard:

```bash
claude-insights install
claude-insights start
```

O dashboard fica disponível em http://localhost:4000

## Fórmulas disponíveis

| Fórmula | Descrição |
| --- | --- |
| `claude-insights` | Real-time dashboard for Claude Code sessions |

## Atualização

```bash
brew update
brew upgrade claude-insights
```

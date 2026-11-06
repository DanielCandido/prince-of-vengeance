# Automação Windows — Etapa 1 (Godot 2D)

Este protótipo integra Gemini Planner (API), Codex Developer (CLI), Godot headless e Gemini QA (CLI). Shep é opcional via wrapper local **ainda não configurado**. Não executa merge, push ou PR automaticamente.

## Preparação

Instale Python 3.11+, Git, GitHub CLI, Godot 4, Codex CLI e Gemini CLI; autentique gh, Codex e Gemini. Crie uma chave Gemini no Google AI Studio. No PowerShell:

```powershell
$env:GEMINI_API_KEY="SUA_CHAVE"
$env:GEMINI_MODEL="gemini-2.5-flash"
git switch main
git pull
python automation/worker.py --issue 12
```

Substitua 12 por uma issue real. O primeiro comando gera uma especificação em `.automation-runs/`. **Revise-a antes de executar**:

```powershell
python automation/worker.py --issue 12 --execute
```

A execução cria uma branch local, roda Codex, testes Godot e Gemini QA. O worker imprime instruções de publicação manual caso o QA passe. O modo `--execute` **gera novamente o plano**, portanto confira a especificação desta execução antes de confiar na aprovação anterior. Não use em tarefas críticas sem corrigir esse fluxo de aprovação.

## Shep

A integração com Shep é um ponto de extensão, não uma integração nativa comprovada. Passe `--shep-command CAMINHO_DO_WRAPPER` apenas depois de verificar a CLI instalada e criar um wrapper executável que aceite o caminho da especificação e aguarde o término. Não execute Shep e Codex simultaneamente no mesmo checkout.

## Segurança e limites

- Mantenha `.automation-runs/` fora do Git; relatórios podem conter contexto interno.
- O QA textual e os testes headless não substituem playtests e revisão humana.
- Alguns testes Godot podem não terminar automaticamente; o worker aplica timeout.
- O worker não implementa fila, persistência, retries ou webhooks.
- Confira `git status` e arquivos não rastreados antes de fazer commit.
- A direção técnica é **2D exclusivamente**; não introduzir sistemas 3D.

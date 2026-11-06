# Automação Windows — Etapa 1 (Godot 2D)

Este protótipo integra Gemini Planner (API), Codex Developer (CLI), Godot headless e Gemini QA (CLI). Shep é opcional via wrapper local **ainda não configurado**. Não executa merge, push ou PR automaticamente.

## Preparação

Instale Python 3.11+, Git, GitHub CLI, Godot 4, Codex CLI e Gemini CLI; autentique gh, Codex e Gemini. Crie uma chave Gemini no Google AI Studio. No PowerShell:

```powershell
$env:GEMINI_API_KEY="SUA_CHAVE"
$env:GEMINI_MODEL="gemini-2.5-flash"
git fetch origin
git switch feat/windows-agent-automation-phase1
git pull
python automation/worker.py --issue 2
```

Substitua o número por uma issue real. O planejamento aceita alterações locais e qualquer branch; usa `git ls-files` para inventariar arquivos versionados e lê trechos limitados de scripts, cenas e testes. O arquivo `.automation-runs/issue-N-.../context.md` registra o contexto realmente enviado ao Gemini; compare com `spec.md` e observe truncamentos. **Revise o plano antes de executar**:

```powershell
python automation/worker.py --issue NUMERO --execute --approved-spec "CAMINHO_PARA_SPEC.md"
```

A execução cria uma branch local, roda Codex, testes Godot e Gemini QA. O worker imprime instruções de publicação manual caso o QA passe. O modo `--execute` exige uma especificação previamente aprovada, uma árvore Git limpa e uma branch nomeada. Use uma issue de implementação, não a issue #2 de auditoria. Não executa alterações durante o planejamento.

## Shep

A integração com Shep é um ponto de extensão, não uma integração nativa comprovada. O wrapper incluído é somente um exemplo desativado. A versão atual do worker ainda não aceita `--shep-command`; integrar Shep exige uma implementação posterior. Não execute Shep e Codex simultaneamente no mesmo checkout.

## Segurança e limites

- Mantenha `.automation-runs/` fora do Git; relatórios podem conter contexto interno.
- O QA textual e os testes headless não substituem playtests e revisão humana.
- Alguns testes Godot podem não terminar automaticamente; o worker aplica timeout.
- O worker não implementa fila, persistência, retries ou webhooks.
- Confira `git status` e arquivos não rastreados antes de fazer commit.
- A direção técnica é **2D exclusivamente**; não introduzir sistemas 3D.

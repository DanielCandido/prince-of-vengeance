# Automação Windows — Godot 2D

Este protótipo integra Gemini Planner (API), Codex Developer (CLI), Godot headless e Gemini QA (CLI). Shep é opcional via wrapper local **ainda não configurado**. O worker não executa merge, commit, push ou PR automaticamente.

## Preparação e fluxo padrão

Instale Python 3.11+, Git, GitHub CLI, Godot 4, Codex CLI e Gemini CLI; autentique `gh`, Codex e Gemini. Crie uma chave Gemini no Google AI Studio. No PowerShell:

```powershell
$env:GEMINI_API_KEY="SUA_CHAVE"
$env:GEMINI_MODEL="gemini-2.5-flash"
git fetch origin
git switch feat/windows-agent-automation-phase1
git pull
python automation/worker.py --issue NUMERO
```

O planejamento aceita alterações locais e qualquer branch; usa `git ls-files` para inventariar arquivos versionados e lê trechos limitados de scripts, cenas e testes. A pasta `.automation-runs/issue-N-.../` guarda o `context.md` realmente enviado ao Gemini e a `spec.md`. Compare os dois e observe eventuais truncamentos. **Revise o plano antes de executar**:

```powershell
python automation/worker.py --issue NUMERO --execute --approved-spec "CAMINHO_PARA_SPEC.md"
$LASTEXITCODE
```

O modo `--execute` exige uma especificação aprovada, uma árvore Git limpa e uma branch nomeada. Ele cria uma branch local, chama o Codex, importa o projeto, executa todas as cenas `tests/*_test.tscn` e chama o Gemini QA. Use uma issue de implementação, não a issue de auditoria. O planejamento não altera o projeto.

## Retomada do QA

Se a implementação já estiver no checkout e uma execução tiver sido interrompida, retome somente a importação, os testes e o Gemini QA na **branch atual**:

```powershell
python automation/worker.py --issue NUMERO --resume-qa --approved-spec "CAMINHO_PARA_SPEC.md"
$LASTEXITCODE
```

`--resume-qa` não cria nem troca branch, não consulta a issue no GitHub e não chama o Codex. O caminho passado a `--approved-spec` deve apontar para a especificação que já recebeu aprovação humana. Alterações locais são permitidas nesse modo para que o QA avalie o diff atual.

Cada tentativa de `--execute` ou `--resume-qa` cria uma pasta exclusiva, com precisão de microssegundos, em `.automation-runs/issue-N-TIMESTAMP/`. Logs e relatórios de tentativas anteriores não são sobrescritos.

## Evidências e códigos de saída

Durante cada etapa, `logs/*.log` recebe `stdout` e `stderr` incrementalmente, identificados pelos prefixos `[stdout]` e `[stderr]`. O arquivo `report.json` é atualizado atomicamente depois da importação e de cada cena de teste; uma falha posterior não apaga resultados anteriores. Cada registro contém comando, exit code, duração, status, cena ou alvo, timestamp e caminho do log.

Os status significam:

- `PASS`: o processo terminou e foi confirmado com exit code `0`.
- `FAIL`: o processo não iniciou ou terminou com exit code diferente de `0`.
- `TIMEOUT`: o limite terminou antes do processo; a saída parcial permanece no log.

O Gemini QA possui registro próprio no `report.json`, além de `qa.md` e `logs/qa.log`. Exit code `0` do Gemini não basta: o QA só recebe `PASS` quando a saída também contém `VERDICT: PASS`. QA não executado, com falha, sem veredito ou em timeout nunca é aprovado.

O worker encerra com código diferente de zero se qualquer etapa Godot tiver `FAIL` ou `TIMEOUT`, se `--skip-godot` for usado durante QA, ou se o Gemini QA não passar. Ao final, imprime os contadores `PASS`, `FAIL` e `TIMEOUT`, o exit code do QA e o caminho absoluto do relatório.

## Timeout no Windows

Cada processo de teste é iniciado sem `shell` e em um novo grupo de processos. Em timeout, o worker chama `taskkill /PID <pid> /T /F` para encerrar a árvore, incluindo filhos do Godot, e usa `process.kill()` como fallback. Se políticas da máquina bloquearem `taskkill`, confirme no Gerenciador de Tarefas que não restou `godot.exe` e preserve o log para diagnóstico.

## Shep

A integração com Shep é um ponto de extensão, não uma integração nativa comprovada. O wrapper incluído é somente um exemplo desativado. O worker ainda não aceita `--shep-command`; integrar Shep exige uma implementação posterior. Não execute Shep e Codex simultaneamente no mesmo checkout.

## Segurança e limites

- Mantenha `.automation-runs/` fora do Git; relatórios podem conter contexto interno.
- O QA textual e os testes headless não substituem playtests e revisão humana.
- Alguns testes Godot podem não terminar automaticamente; o worker aplica timeout e registra a saída parcial.
- O worker não implementa fila ou webhooks. A persistência é local e incremental por tentativa.
- Confira `git status` e arquivos não rastreados antes de fazer commit.
- A direção técnica é **2D exclusivamente**; não introduzir sistemas 3D.

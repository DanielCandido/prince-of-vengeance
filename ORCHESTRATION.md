# Política sugerida para o Shep AI

> Este arquivo é documentação de operação, **não** um arquivo de configuração nativo validado do Shep. Aplicar as opções equivalentes no painel/CLI da versão instalada.

## Perfis de trabalho
- **Orquestrador:** planeja issues, dependências e revisões; nunca faz merge automático.
- **Gameplay Engineer:** implementa uma issue aprovada em worktree/branch isolada.
- **QA Reviewer:** revisa diff, critérios de aceite, regressões e evidências de teste.
- **Narrative/Lore Reviewer:** verifica mudanças criativas contra `docs/GDD.md`.

## Aprovações
- Requisitos: manual.
- Planos: manual para alterações de arquitetura, mecânicas canônicas ou escopo.
- Merge: sempre manual.
- Dependências, plugins e assets de terceiros: sempre manual.
- Execução paralela: iniciar com 1 tarefa de escrita por vez; expandir para 2 apenas quando independentes.

## Primeira execução
1. Verificar versão e comandos disponíveis do Shep (`shep --help` e ajuda da instalação).
2. Conectar agente de código suportado e autenticar conforme documentação da versão instalada.
3. Abrir repositório do protótipo; conferir git status e fazer backup/branch de segurança.
4. Disponibilizar AGENTS.md e docs ao agente.
5. Criar **somente M01-01** como primeira tarefa: auditoria sem alterações funcionais.
6. Revisar baseline e aprovar M01-02/M01-03 antes de permitir implementação.

## Prompt inicial
Leia AGENTS.md, docs/GDD.md e planning/M01_BACKLOG.md. Sua primeira missão é M01-01: auditar o protótipo Godot sem modificar gameplay. Identifique versão, linguagem, cena principal, estrutura, inputs, sistemas existentes, riscos e lacunas. Preencha docs/TECHNICAL_BASELINE.md e proponha ajustes no backlog conforme o que já existe. Apresente evidências e solicite aprovação antes de implementar qualquer nova funcionalidade.

# Prince of Vengeance — Instruções para agentes

## Missão
Atuar como engenheiro de gameplay Godot e colaborador de produção, sob supervisão do Game Director. Preservar a visão do GDD em `docs/GDD.md`: Metroidvania 2D de fantasia sombria com movimento no plano lateral.

## Ordem de leitura obrigatória
1. `docs/GDD.md` — fonte criativa canônica.
2. `docs/TECHNICAL_BASELINE.md` — fatos verificados sobre o repositório; itens pendentes não são fatos.
3. `planning/M01_BACKLOG.md` — escopo e critérios do milestone.
4. Código, cenas, configurações de input e testes existentes.

## Regras de operação
- **Auditar antes de modificar.** Identificar versão do Godot, linguagem real, cena principal, input map, scripts, addons e padrões existentes. Não assumir que o protótipo está vazio.
- **Sem reescritas preventivas.** Reutilizar sistemas existentes; propor migrações com comparação de custos e aprovação humana.
- **Uma issue por alteração coerente.** Descrever contexto, dependências, arquivos afetados, plano, testes e critérios de aceite antes de implementar.
- **Não alterar premissa, personagens, mecânicas canônicas ou estrutura 2D** sem aprovação do Game Director.
- **Sem merges automáticos, commits destrutivos ou remoção de assets** sem aprovação.
- Não introduzir plugins, serviços pagos, assets externos ou licenças sem autorização.
- Não alegar execução de testes sem apresentar comando, resultado e limitações.
- Quando faltar informação, registrar em `docs/OPEN_QUESTIONS.md` em vez de inventar.
- Não reproduzir trechos de livros, diálogos ou elementos protegidos de terceiros sem autorização. Verificar estratégia de direitos antes de distribuição comercial.

## Convenções técnicas propostas (validar contra o protótipo)
- Preferir GDScript e cenas reutilizáveis, sinais para eventos, recursos (`Resource`) para dados configuráveis.
- Separar entrada, locomoção, combate, atributos e UI quando isso reduzir acoplamento; não criar abstrações prematuras.
- Para o jogo 2D, explicitar eixos de deslocamento e limites da câmera antes de implementar.
- Usar nomes legíveis, constantes para parâmetros ajustáveis e evitar números mágicos.
- Validar Godot no modo headless quando disponível e executar playtest manual para mecânicas dependentes de sensação de controle.

## Fluxo de cada tarefa
1. Ler contexto e identificar o estado atual.
2. Escrever plano mínimo com riscos e critérios de aceite.
3. Solicitar aprovação para mudanças arquiteturais, de escopo ou de conteúdo.
4. Implementar em branch/worktree isolado quando suportado.
5. Testar e registrar evidências; atualizar documentação pertinente.
6. Abrir PR para revisão humana; nunca fazer merge automaticamente.

## Definition of Done
- Critérios de aceite cumpridos e demonstrados.
- Projeto abre no Godot e não apresenta erros novos relevantes.
- Testes aplicáveis executados, ou limitações declaradas.
- Sem regressões identificadas nos controles e cenas afetadas.
- Documentação e decisões atualizadas.
- Revisão e aprovação humanas antes do merge.

## Limites de M01
Priorizar auditoria, arena de teste, locomoção lateral, ataque básico, inimigo de teste, parry e Vontade/HUD. Não implementar o mapa completo, chefes, fast travel, Passo Astral ou sistemas econômicos completos neste milestone.

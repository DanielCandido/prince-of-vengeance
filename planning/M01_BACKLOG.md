# Milestone M01 — Fundação Jogável

**Objetivo:** demonstrar o loop de movimentação + combate + Vontade em uma arena de teste, aproveitando o protótipo existente.
**Política:** executar em ordem de dependências; estimativas só após auditoria. Status inicial: *a validar*.

| ID | Prioridade | Tarefa | Dependências | Critérios de aceite |
|---|---|---|---|---|
| M01-01 | P0 | Auditar protótipo Godot | — | Baseline preenchida; cenas, scripts, inputs e funcionalidades existentes mapeados; riscos documentados; nenhuma mudança destrutiva |
| M01-02 | P0 | Definir contratos de input e plano 2D | M01-01 | Eixos, ações e câmera documentados; controles existentes preservados; aprovação humana |
| M01-03 | P0 | Preparar arena de validação | M01-01 | Cena simples reproduzível para movimento e combate; sem dependência de assets finais |
| M01-04 | P0 | Consolidar movimentação de Kaelen | M01-02, M01-03 | Movimento lateral e salto funcionais; limites do plano respeitados; sem regressão do protótipo |
| M01-05 | P1 | Dash e invulnerabilidade parametrizados | M01-04 | Dash testável no solo; janela de invulnerabilidade configurável e demonstrável; cooldown/limites definidos em playtest |
| M01-06 | P0 | Ataque básico e alvo de treino | M01-03, M01-04 | Ataque acerta alvo válido uma vez por janela prevista; feedback de hit; alvo recebe dano |
| M01-07 | P1 | Inimigo de teste com ataque telegráfico | M01-06 | Inimigo executa ataque previsível; Kaelen pode receber dano; reset da arena confiável |
| M01-08 | P1 | Afronta Implacável (parry) | M01-07 | Parry dentro da janela cancela/neutraliza golpe e atordoa inimigo; fora da janela não concede benefício |
| M01-09 | P1 | Sistema de Vontade e HUD mínimo | M01-06, M01-08 | Acertos e parry geram Vontade; limites respeitados; HUD reflete valor real; valores configuráveis |
| M01-10 | P0 | Testes, playtest e revisão de milestone | M01-05 a M01-09 | Checklist executado, problemas registrados, demo jogável, PR revisado e aprovado |

## Critérios de saída do M01
- Uma cena executável demonstra deslocamento lateral, salto, dash, ataque, parry e barra de Vontade.
- Pelo menos um inimigo/alvo permite testar acerto, dano e parry.
- Nenhum bloqueador conhecido impede abrir e jogar a cena na versão do Godot identificada.
- A equipe documentou o que foi reaproveitado e o que foi alterado.
- Game Director aprova a experiência básica antes de avançar para M02.

## Fora do escopo
Pulo duplo, Garras de Aço, Purga da Mente, Lente dos Antigos, Passo Astral, economia, chefes, mapa final e sistema de morte completo. Permanecem no GDD para milestones futuros.

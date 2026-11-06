# Plano de desenvolvimento — Prince of Vengeance

Este plano converte o GDD em entregas jogáveis. A prioridade é validar primeiro o
ritmo de movimentação e combate; conteúdo, arte final e expansão do mapa entram
somente depois que o núcleo estiver divertido e mensurável.

## Premissas técnicas

- Godot 4.7, GDScript e renderização Forward+.
- Direção visual híbrida 2.5D: personagens e inimigos em sprites 2D,
  inseridos como billboards em ambientes, iluminação e colisões 3D.
- Jogabilidade lateral bloqueada no eixo Z.
- Teclado e controle desde o início; rebinding entra na etapa de interface.
- Arte provisória (graybox) até a validação do vertical slice.

## Pipeline visual definido

- **Personagens e inimigos:** concept sheet → modelo visual frontal/lateral →
  spritesheet por estado → recorte em `SpriteFrames` → animação e eventos no Godot.
- **Animações mínimas de Kaelen:** idle, corrida, subida/queda, pouso, dash,
  combo de três golpes, Corta-Aço, parry, dano, cura e morte.
- **Ambientes:** módulos 3D, materiais PBR, vegetação, ruínas e iluminação dinâmica.
- **Integração:** sprites sempre orientados para a câmera, sombras de contato,
  normal maps opcionais e iluminação calibrada para evitar aparência de recorte plano.
- **VFX:** combinação de sprites 2D, partículas e luzes 3D para Vontade,
  impactos, tecnologia dos Construtores e energia astral.
- **Consistência:** paleta, escala, perspectiva e direção de luz compartilhadas
  entre sprites e cenários; nenhum asset final entra sem teste dentro da cena 3D.

## Etapas

### 1. Fundação e movimentação — concluída

- Estrutura de cenas e scripts desacoplados.
- Arena graybox lateral, câmera e iluminação.
- Corrida com aceleração/desaceleração, pulo com altura variável, coyote time,
  jump buffer, pulo duplo e dash terrestre/aéreo.
- Critério de aceite: atravessar a arena sem sair do plano lateral, com controles
  responsivos e parâmetros ajustáveis no Inspector.

### 2. Combate e Vontade — concluída

- Máquina de estados de Kaelen.
- Combo de três golpes, hitbox/hurtbox, dano, stagger e knockback.
- Dash com invulnerabilidade, parry com janela configurável e Corta-Aço.
- Vida, geração/gasto de Vontade e Purga da Mente (canalização de 1,5 s).
- Critério: duelo completo contra um boneco de teste e telemetria visual no HUD.

### 3. Vertical slice do Pântano — em andamento

- Saqueador, Salteador de Besta e Bruto dos Espinhos — implementados.
- Uma sala de exploração, uma arena, um segredo e uma fogueira/checkpoint.
- Relíquia simples com texto de lore e Sombra de Vingança após a morte.
- Critério: loop de 10–15 minutos do checkpoint à recuperação dos recursos.
- Substituir o graybox de Kaelen e dos inimigos por um primeiro conjunto de
  sprites 2D validando escala, leitura, iluminação e animação no ambiente 3D.

### 4. Progressão Metroidvania

- Garras de Aço, Selo do Crepúsculo, portas/barreiras e backtracking.
- Inventário, Insígnias, Sucata, Ecos de Vontade e persistência de save.
- Mapa por salas, marcadores e primeira estação de fast travel.

### 5. Chefe do Capítulo 1

- Conde Renard, duas fases, ondas de choque, queda de escombros e charge.
- Intro/outro in-engine e recompensa Garras de Aço.
- Critério: luta legível, sem dano inevitável e balanceada em três faixas de teste.

### 6. Produção dos capítulos

- Cap. 1: Pântano, Castelo dos Espinhos e Abismo dos Espelhos/Corvus.
- Cap. 2: Bunkers, Hautmont, puzzles tecnológicos e Aurélius.
- Cap. 3: Vyene, Plano Astral, Passo Astral e Rei das Sombras.
- Produção por região: graybox → gameplay → narrativa → arte → áudio → QA.
- Produção de personagens: concept → spritesheet → integração → eventos de
  combate → efeitos → revisão de legibilidade sobre os ambientes 3D.

### 7. Polimento e lançamento

- Acessibilidade, remapeamento, localização, desempenho e compatibilidade.
- Balanceamento, testes de regressão, conquistas e finais.
- Certificação de builds e checklist de lançamento.

## Backlog imediato

1. Janelas técnicas do combo, Corta-Aço e parry separadas em startup, atividade
   e recuperação, com regressão automatizada. Ajuste fino após playtest manual.
2. Telemetria de playtest implementada no HUD e exportada em JSON. Executar
   sessão manual e ajustar o percurso até concluir o critério de 10–15 minutos.
3. ~~Completar a animação idle de Kaelen.~~ Concluído; todos os estados
   essenciais estão integrados.
4. ~~Substituir os volumes dos inimigos por sprites provisórios consistentes.~~
   Saqueador, Salteador e Sombra de Vingança concluídos.
5. Segunda passada visual dos inimigos: folhas 4×2 em alta consistência,
   movimento animado e direção explícita da Sombra — concluída.
6. Normalização do pulo de Kaelen em células isoladas, com escala uniforme —
   concluída.
7. Primeira integração do cenário medieval 3D ao vertical slice — concluída;
   próxima passada: materiais, composição modular e otimização.
8. Bonfire 3D integrada aos dois checkpoints, mantendo interação, iluminação e
   respawn existentes — concluída.
9. Primeira migração de Kaelen para 3D: rig Mixamo, idle, caminhada, corrida,
   virada, subida, queda e combo consolidados em `AnimationTree` — concluída.
   Morte, cura, parry, dano, ataque pesado e coleta dedicados — concluídos.
   Pendente: animação dedicada de dash.
10. Combate temporariamente desativado por flag para a etapa de polimento da
    movimentação. Primeira passada: aceleração/desaceleração, caminhada por
    velocidade, virada suave e transições de aterrissagem — concluída.
    O modo sem combate mantém prévias de ataque, Corta-Aço, parry e cura, mas
    nunca ativa hitboxes nem aplica dano. Castelo recalibrado no plano 3D.
11. Virada 3D sem rotação óssea duplicada, Corta-Aço separado em carga e golpe
    completo, e material PBR de Kaelen com albedo, normal, roughness e metallic —
    concluído.
12. Espada medieval 3D anexada ao osso da mão direita e herdando todas as
    animações do rig — concluído.
13. `Running Slide` integrado ao dash, com duração e velocidade recalibradas
    para preservar leitura visual e distância percorrida — concluído.
14. Espada corrigida por direção, iluminação reforçada e slot de equipamento
    `HeadEquipment` preparado para capuz/acessórios — concluído.
    Correção posterior: o encaixe local da espada permanece constante; apenas o
    rig gira, evitando troca de lado durante corrida e pulo.
15. Cabo da espada reposicionado na mão e fogueiras ampliadas com partículas de
    chama emissivas — concluído. Sacerdote corrompido 3D ainda não integrado.
    Segunda passada da fogueira: chamas menores e mais baixas, base legível de
    pedras/troncos e iluminação local reforçada — concluída.
    Encaixe da espada refinado visualmente: cabo em `X=-0,55`, sem rotação local
    duplicada, mantendo a lâmina à frente do personagem — concluído.
    Material da espada configurado sem descarte de faces traseiras para permanecer
    visível nos dois facings da câmera lateral — concluído.
    Socket e espada passaram a ser recriados pelo controlador em runtime para não
    desaparecerem quando a cena principal for salva novamente no editor — concluído.
    Offset do cabo calculado pela rotação escolhida, mantendo a extremidade +X do
    GLB exatamente na origem da mão — concluído.

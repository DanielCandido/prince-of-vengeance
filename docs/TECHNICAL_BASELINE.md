# Baseline Técnica Verificável — Godot 2D

## 1. Visão geral e propósito do documento

Este documento registra a baseline técnica do protótipo de **Prince of Vengeance** a partir de auditoria estática do repositório. A implementação ativa e a direção canônica são exclusivamente 2D: o GDD define um Metroidvania com movimento no plano lateral (`docs/GDD.md`), e a cena principal usa nós 2D (`scenes/vertical_slice.tscn`). Referências 3D históricas são tratadas na seção 6 e não descrevem a arquitetura vigente.

Esta baseline separa fatos observados de inferências e limitações. Nenhum teste foi executado nesta etapa, e a versão do executável Godot não foi consultada pela CLI.

## 2. Configuração da engine e do projeto (`project.godot`)

| Item | Valor verificado | Fonte |
|---|---|---|
| Versão declarada pelo projeto | Godot `4.7`, em `config/features` | `project.godot` (`[application]`) |
| Renderer | `GL Compatibility`, com `renderer/rendering_method` e variante mobile em `gl_compatibility` | `project.godot` (`[rendering]`) |
| Cena principal | `res://scenes/vertical_slice.tscn` | `project.godot` (`run/main_scene`) |
| Autoload | `GameState` → `*res://scripts/core/game_state.gd` | `project.godot` (`[autoload]`) |
| Viewport | `1280 × 720` | `project.godot` (`[display]`) |
| Stretch | modo `canvas_items`, aspecto `expand` | `project.godot` (`[display]`) |
| Addon habilitado | `res://addons/AsepriteWizard/plugin.cfg` | `project.godot` (`[editor_plugins]`) |
| Linguagem observada | GDScript | scripts `.gd` referenciados por `project.godot` e `scenes/vertical_slice.tscn` |

A string `4.7` é a compatibilidade declarada pelo projeto, não uma comprovação da versão exata da CLI instalada na máquina do desenvolvedor.

## 3. Contrato do InputMap

As nove ações abaixo estão declaradas em `project.godot`, seção `[input]`, todas com `deadzone = 0.3`.

| Ação | Teclado | Mouse | Fonte |
|---|---|---|---|
| `move_left` | A; Seta para a esquerda | — | `project.godot` (`[input]`) |
| `move_right` | D; Seta para a direita | — | `project.godot` (`[input]`) |
| `jump` | Espaço | — | `project.godot` (`[input]`) |
| `dash` | Shift; F | — | `project.godot` (`[input]`) |
| `attack` | J | Botão esquerdo | `project.godot` (`[input]`) |
| `parry` | K | Botão direito | `project.godot` (`[input]`) |
| `heal` | L | — | `project.godot` (`[input]`) |
| `heavy_attack` | H | Botão do meio | `project.godot` (`[input]`) |
| `interact` | E | — | `project.godot` (`[input]`) |

Não há bindings de controle/gamepad configurados nesse InputMap (`project.godot`).

## 4. Arquitetura 2D e estrutura de cenas/sistemas

### Cena principal

`res://scenes/vertical_slice.tscn` possui raiz `VerticalSlice` do tipo `Node2D`, controlada por `res://scripts/vertical_slice_2d.gd`. A estrutura relevante observada é:

```text
VerticalSlice (Node2D)
├── Backdrop (Parallax2D)
├── Ground (StaticBody2D)
├── Kaelen (CharacterBody2D)
│   ├── CollisionShape2D
│   ├── Health (Node / HealthComponent)
│   ├── AttackHitbox (Area2D / Hitbox2D)
│   ├── Hurtbox (Area2D / Hurtbox2D)
│   ├── Visual (Node2D)
│   │   └── KaelenSprite (AnimatedSprite2D)
│   └── Camera2D
├── TrainingEnemy (instância de `res://scenes/enemies/swamp_raider.tscn`)
├── CrossbowGuard (instância de `res://scenes/enemies/crossbow_raider.tscn`)
├── SecondRoomBruiser (instância de `res://scenes/enemies/thorn_brute.tscn`)
├── BandFire (Area2D)
├── ToxicPool (Area2D)
├── SecretScrapCache (Area2D)
├── BlackGlassLens (Area2D)
└── HUD (CanvasLayer)
    ├── barras de vida, Vontade e inimigo
    ├── labels de sucata, status e telemetria
    └── LorePanel
```

A `Camera2D` é filha de `Kaelen` e tem limites horizontais e verticais declarados na própria cena (`scenes/vertical_slice.tscn`). O cenário, colisões, jogador, inimigos, hazards e interface usam classes 2D ou UI; não há nós 3D nessa cena.

### Componentes reutilizáveis

| Componente | Base e responsabilidade verificada | Fonte |
|---|---|---|
| `HealthComponent` | Estende `Node`; mantém `max_health`/`current_health`, aplica dano, cura e reset; emite `health_changed` e `depleted` | `scripts/components/health_component.gd` |
| `Hitbox2D` | Estende `Area2D`; controla janela ativa, dano, knockback e deduplicação de alvos; ignora a hurtbox do próprio `source`; emite `hit_landed` | `scripts/components/hitbox_2d.gd` |
| `Hurtbox2D` | Estende `Area2D`; encaminha `receive_hit()` ao `actor` configurado | `scripts/components/hurtbox_2d.gd` |

### Controlador de Kaelen

`KaelenController`, em `scripts/player/kaelen_controller_2d.gd`, estende `CharacterBody2D`. O script concentra, no estado atual do protótipo, locomoção lateral, gravidade e salto; dash; combo leve, ataque pesado, parry e cura; dano, morte e respawn; Vontade; seleção de animações em `AnimatedSprite2D`; e ativação das janelas de `Hitbox2D`. Os parâmetros principais de movimento e recursos são exportados para o Inspector, enquanto tempos e danos das janelas de combate são constantes no script.

O controlador consome as ações `move_left`, `move_right`, `jump`, `dash`, `attack`, `heavy_attack`, `parry` e `heal` de `project.godot`. A ação `interact` é configurada no InputMap, mas não é consumida por esse controlador (`scripts/player/kaelen_controller_2d.gd`).

## 5. Inventário da suíte de testes e guia de execução

Há nove testes independentes, cada um composto por um script `Node` e sua cena correspondente:

| Teste | Script | Cena executável |
|---|---|---|
| Autoacerto de combate | `tests/combat_self_hit_test.gd` | `tests/combat_self_hit_test.tscn` |
| Janelas de combate | `tests/combat_windows_test.gd` | `tests/combat_windows_test.tscn` |
| Morte e respawn | `tests/death_respawn_test.gd` | `tests/death_respawn_test.tscn` |
| Dano no inimigo | `tests/enemy_damage_test.gd` | `tests/enemy_damage_test.tscn` |
| Polimento de movimento/combate 2D | `tests/movement_polish_test.gd` | `tests/movement_polish_test.tscn` |
| Telemetria de playtest | `tests/playtest_telemetry_test.gd` | `tests/playtest_telemetry_test.tscn` |
| Direção dos sprites | `tests/sprite_direction_test.gd` | `tests/sprite_direction_test.tscn` |
| Escala/conjunto dos sprites | `tests/sprite_scale_test.gd` | `tests/sprite_scale_test.tscn` |
| Hyper-armor do Bruto | `tests/thorn_brute_hyper_armor_test.gd` | `tests/thorn_brute_hyper_armor_test.tscn` |

Os scripts estendem `Node`, executam as asserções em `_ready()` e encerram a árvore com código `0` em sucesso ou `1` em falha. Cada cena `.tscn` fornece o nó raiz necessário e anexa o script correspondente (`tests/*.gd` e `tests/*.tscn`). Não há referência ao framework GUT no projeto auditado.

Execute uma cena de teste a partir da raiz do projeto, por exemplo:

```powershell
godot --headless --path . res://tests/combat_self_hit_test.tscn
```

Para executar as nove cenas em PowerShell e interromper na primeira falha:

```powershell
$testScenes = Get-ChildItem -LiteralPath tests -Filter *_test.tscn | Sort-Object Name
foreach ($scene in $testScenes) {
    & godot --headless --path . "res://tests/$($scene.Name)"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```

Não se deve usar diretamente `godot --headless -s tests/<nome_do_teste>.gd` com os scripts atuais: `--script` espera um `MainLoop`/`SceneTree`, enquanto estes testes estendem `Node`. A execução suportada pela estrutura observada é por meio das cenas pareadas.

**Status da suíte:** **Não executados durante a auditoria de baseline. Testes não executados nesta etapa.** Os comandos acima são um guia e não constituem evidência de execução.

## 6. Log de divergências documentais

`DEVELOPMENT_PLAN.md` descreve uma direção híbrida 2.5D/3D com Forward+, billboards, ambientes e colisões 3D, fogueiras 3D e rig Mixamo. Essas declarações divergem das fontes canônicas e do repositório ativo:

- `docs/GDD.md` define sprites, cenários, câmera, partículas e shaders 2D, com movimento no plano lateral;
- `AGENTS.md` determina preservar a estrutura 2D e proíbe alterar essa premissa sem aprovação do Game Director;
- `project.godot` declara `GL Compatibility` e aponta para `res://scenes/vertical_slice.tscn`;
- `scenes/vertical_slice.tscn` é uma árvore `Node2D` com `CharacterBody2D`, `Area2D`, `AnimatedSprite2D` e `Camera2D`.

Portanto, as menções 3D/Forward+ em `DEVELOPMENT_PLAN.md` são tratadas nesta baseline como plano histórico ou obsoleto e **não** como descrição da implementação vigente. Esta conclusão é uma inferência pela comparação das fontes acima; a precedência criativa e operacional vem de `docs/GDD.md` e `AGENTS.md`. `DEVELOPMENT_PLAN.md` não foi alterado nesta issue.

## 7. Limitações e questões abertas

- A auditoria aprovada que originou esta baseline recebeu `scripts/player/kaelen_controller_2d.gd` truncado ao final da linha 90, dentro de `_build_sprite_frames()`. Na validação do repositório feita para redigir este documento, o arquivo atual foi lido integralmente (339 linhas); a limitação é registrada aqui como proveniência da evidência fornecida, não como truncamento atual do arquivo.
- Na auditoria aprovada, não houve inspeção direta de `GDD.txt`, `INSTRUCTIONS.md`, `ORCHESTRATION.md`, das cenas em `scenes/combat/` e `scenes/enemies/`, dos demais scripts em `scripts/core/`, `scripts/combat/`, `scripts/enemies/` e `scripts/world/`, nem de parte dos testes então listados. A implementação desta baseline confirmou o inventário e inspecionou os nove pares de teste, mas não promove afirmações sobre o conteúdo interno dos demais arquivos não auditados.
- A versão `4.7` documentada é a feature declarada em `project.godot`; o comando `godot --version` não foi executado nesta etapa.
- A suíte automatizada e o projeto principal não foram executados nesta etapa. Compatibilidade efetiva, ausência de erros em runtime e sensação de controle permanecem dependentes de validação headless e playtest manual posteriores.
- `docs/GDD.md` ainda registra como abertas decisões de versão, linguagem, eixos e controles. Esta baseline resolve os fatos observáveis do repositório para versão declarada, linguagem e InputMap, mas qualquer mudança desses contratos requer a issue apropriada e aprovação humana.

# GAME DESIGN DOCUMENT (GDD)

**Título do Projeto:** Prince of Vengeance

**Gênero:** Metroidvania 2D / Dark Fantasy Action RPG

**Público-Alvo:** Fãs de Metroidvania (*Hollow Knight*, *Metroid Dread*), RPGs de ação táticos e universos de fantasia sombria pós-apocalíptica.

---

## 1. VISÃO GERAL DO JOGO

### 1.1 Premissa Narrativa

Kaelen é o único sobrevivente do massacre de sua família perpetrado pelo cruel Conde Renard. Em busca de vingança, o jovem assume a liderança de um bando de mercenários implacáveis e descobre que o mundo medieval em decadência onde vive é, na verdade, a Terra séculos após um apocalipse tecnológico devastador. Para conquistar sua vingança e reivindicar o Império, Kaelen deve dominar a antiga tecnologia dos Construtores e enfrentar a ameaça necromântica do Rei das Sombras.

### 1.2 Pilares do Jogo

* **Combate Ágil e Punitivo:** Ação fluida 2D focada em esquivas (*dashes*), *parries* de precisão milimétrica e manipulação do recurso de Vontade.
* **Exploração Metroidvania & Tecnológica:** Progressão não linear guiada pela aquisição de habilidades que revelam plataformas invisíveis, destravam portas de bunkers e alternam dimensões.
* **Narrativa Híbrida & Lore Ambiental:** História contada através de cenas cinematográficas expressivas aliadas à descoberta de relíquias do mundo moderno interpretadas sob uma ótica medieval.

---

## 2. MECÂNICAS DE GAMEPLAY & SISTEMAS

### 2.1 Movimentação e Combate

* **Ataque Básico (Lâmina):** Combo rápido de 3 golpes horizontais. Atacar inimigos gera o recurso **Vontade**.
* **Afronta Implacável (Parry Tático):** Bloqueio executado no instante do impacto inimigo. Atordoa o oponente e regenera Vontade.
* **Movimentação Especial:** Pulo duplo, escalada em paredes usando adaga (*Garras de Aço*) e *dash* no ar/chão (*Impulso de Vontade*) com quadros de invulnerabilidade.

### 2.2 Sistema de Vontade & Tecnologia

* **Purga da Mente:** Concentra Vontade por 1,5s (ficando imóvel) para recuperar um segmento de vida.
* **Selo do Crepúsculo:** Explosão de energia sombria em área que empurra inimigos e destrói barreiras mágicas.
* **Lente dos Antigos:** Visor de IA antiga que revela plataformas energéticas invisíveis e pontos fracos nos chefes.
* **Passo Astral:** Transforma Kaelen em sombra por alguns segundos para atravessar portões energéticos e alternar entre o plano físico e o espiritual.

### 2.3 Economia e Progressão

* **Moedas:**
* **Sucata dos Construtores:** Caída de inimigos e baús. Usada para comprar suprimentos, mapas e aprimorar equipamentos.
* **Ecos de Vontade:** Recurso raro dropado de chefes para aprimorar o dano da espada e o limite da barra de Vontade.


* **Insígnias dos Deserdados (Charms):** Equipamentos encontrados pelo mapa que concedem efeitos passivos (ex: *Mira de Kiran* para disparos diagonais; *Escudo de Marek* para escudo temporário pós-parry).

### 2.4 Game Loop de Morte

* **Respawn:** Kaelen renasce na última *Fogueira do Bando* ou *Terminal de Contingência* ativado.
* **Sombra de Vingança (Punição):** Ao morrer, Kaelen perde sua *Sucata* e tem 50% da barra de Vontade bloqueada. É necessário retornar ao local da morte e derrotar a própria **Sombra Espiritual** para recuperar os recursos.

---

## 3. ESTRUTURA DO MUNDO & ZONAS

```
                  [O Teto do Mundo - Cap. 3]
                              |
             [Cidade Imperial de Vyene] (HUB)
             /                |               \
   [Pântano dos Afogados]   [Bunkers]    [Estepes Geladas]
            |               (Cap. 2)          |
   [Castelo dos Espinhos]               [Cidadela Hautmont]
            |                                 |
  [Abismo dos Espelhos]               [Laboratório 01]

```

### 3.1 Zonas Principais

* **Capítulo 1: As Terras Desoladas:** Pântanos sombrios, rodovias de asfalto destruídas e o Castelo dos Espinhos.
* **Capítulo 2: Os Bunkers e Hautmont:** Complexos militares subterrâneos de concreto armado combinados com castelos góticos congelados.
* **Capítulo 3: O Trono de Cinzas (Vyene):** Metrópole Imperial cercada por fendas astrais e ruínas de satélites caídos.
* **Fast Travel:** Estações de metrô antigo reativadas ao fornecer energia com baterias encontradas no mapa.

---

## 4. PERSONAGENS & INIMIGOS

### 4.1 Principais

* **Kaelen (Príncipe Espinho):** Protagonista frio, calculista e impulsionado pela vingança.
* **Varek, Kiran e Marek:** Membros do bando dos Deserdados que atuam como suporte tático e comerciantes no Hub.
* **Conde Renard:** Nobre brutal responsável pela destruição da família de Kaelen (Chefe Cap. 1).
* **Príncipe Aurélius:** O "Herói Dourado", espadachim rápido impulsionado por tecnologia de ponta (Chefe Cap. 2).
* **O Rei das Sombras:** Entidade necromântica colossal gerada pelo acúmulo de radiação e dor do apocalipse (Chefe Final).

### 4.2 Inimigos Comuns

* **Pântano/Deserdados:** Saqueadores rápidos, Salteadores de Besta e Brutos dos Espinhos com armadura pesada.
* **Imperiais:** Infantes com escudo (exigem quebra de guarda), Batedores Energizados ágeis e Artilheiros com mira laser.
* **Abominações/Astral:** Caminhantes de Cinzas que explodem ao morrer, Espectros do Bordo invisíveis no plano físico e Gardiões Exoesqueletos industriais.

---

## 5. DIREÇÃO DE ARTE & IDENTIDADE SONORA

### 5.1 Estilo Visual (2D Sombrio)

* Sprites 2D para personagens e cenários, com silhuetas fortes e animações legíveis no plano lateral.
* Luzes, partículas e shaders 2D destacam o contraste entre tecnologia azul/néon e ambientes góticos escuros.
* Transições de câmera 2D durante trocas de fase de chefes e cenas narrativas.

### 5.2 Trilha Sonora (Neoclássico Dark / Industrial)

* **Exploração:** Arranjos lentos de violoncelo, alaúde e coros guturais para a atmosfera medieval decadente.
* **Combates:** Entrada rápida de sintetizadores pesados (*Dark Synthwave*), distorção e batidas industriais mecânicas para representar a tecnologia dos Construtores.

---

## Adendo de produção — M01 (não altera o GDD original)

**Meta:** validar o núcleo de controle e combate em uma arena de teste 2D, reutilizando o protótipo existente.

**No escopo:** inspeção do projeto; movimentação lateral/câmera; ataque básico e feedback; inimigo de teste; Afronta Implacável; geração/visualização de Vontade; testes e playtest.

**Fora do escopo:** todas as zonas completas, chefes, progressão econômica, árvore de habilidades, sistemas de morte completos, fast travel, Passo Astral e narrativa cinematográfica.

**Decisões ainda abertas:** versão do Godot; linguagem atual do protótipo; esquema de eixos; dispositivo de controle prioritário; parâmetros numéricos de combate; direitos de adaptação. Nenhum desses detalhes foi verificado.

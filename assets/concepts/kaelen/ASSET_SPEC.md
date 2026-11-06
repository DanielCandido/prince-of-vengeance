# Kaelen — folha de poses v1

- Fonte: geração integrada de imagem (modo built-in).
- Uso: validação do pipeline de personagens no jogo 2D.
- Arquivo: `kaelen_pose_sheet_v1.png` (1536 × 1024, RGBA).
- Layout: 4 colunas × 2 linhas; células de 384 × 512.
- Estado: concept/protótipo. As poses ainda não formam ciclos completos de animação.

## Prompt final

Folha 2D de Kaelen em oito poses laterais: idle, duas poses de corrida, subida,
queda, ataque, parry e Corta-Aço. Jovem espadachim magro, rosto pálido, capa
preta rasgada com forro vermelho-sangue, túnica militar escura, ombreira de
ferro em forma de espinho e espada longa reta. Pintura 2D refinada, contornos
nítidos, proporções e figurino consistentes, fundo realmente transparente,
sem texto, cenário, sombras projetadas ou elementos extras.

## Próxima revisão

- Separar cada ação em arquivo próprio para preservar escala e pivô.
- Gerar 6–8 quadros por ciclo de corrida e 3–5 por ataque.
- Padronizar baseline dos pés e posição do punho da espada.
- Criar atlas final somente após aprovação das ações isoladas.

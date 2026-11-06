# Inimigos do Pântano — sprites v1

- Folhas horizontais com 3 quadros de 724 × 724 px.
- Ordem: `idle`, `telegraph`, `attack`.
- Saqueador: panos, chapéu de palha e duas adagas de vergalhão.
- Salteador: capuz, couro gasto e besta rústica.
- Fundo removido por conectividade às bordas; canal alpha validado.
- Sprites usam `AnimatedSprite2D`; colisões usam `CollisionShape2D`.
- Sombra de Vingança: duplicata violeta de Kaelen com estados `idle`,
  `pursuit` e `attack`, transparência e modulação espectral em runtime.
- Bruto dos Espinhos: elite de grande porte com `idle`, preparação vertical e
  impacto; capacete de galão, proteção de pneus e porrete industrial.
- Escala calibrada pelos limites alpha: comuns ~1,85 m, Bruto ~2,35 m e
  Sombra ~1,90 m; margens transparentes não entram no cálculo visual.
- Folhas v3 normalizadas em células 512 × 512, pivô horizontal central e linha
  dos pés em Y=480 para eliminar saltos de baseline durante os loops.

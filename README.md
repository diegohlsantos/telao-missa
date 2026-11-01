# Telão da Missa

Monta o telão da missa: busca as leituras do dia, encaixa os cantos do acervo pelo nome e projeta no padrão da paróquia (fundo preto, títulos amarelos).

- **Site:** https://diegohlsantos.github.io/telao-missa/
- **Link de uma data:** `.../telao-missa/?data=2026-11-08`
- **Banco:** Supabase, projeto *Telao da Missa* (`xbtrwvtkdsjptnpqsaom`) — tabelas `musicas`, `leituras`, `missas`, `editores`, `pedidos`.
- **Leituras:** função `liturgia` no Supabase busca a liturgia diária e guarda em `leituras`.
- Leitura aberta para todos; edição só para quem está em `editores` (liberado na aba Equipe).

No telão: → / Espaço avança, ← volta, B tela preta, Esc sai.

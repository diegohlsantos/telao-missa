"""Gera os modelos de e-mail do Supabase Auth na identidade do Telão Missa.

Uso: python3 supabase/templates/gerar.py
Saída: um .html por modelo nesta pasta + assuntos.txt.
Colar cada um em Supabase → Authentication → Email Templates.
"""
from pathlib import Path

PASTA = Path(__file__).parent

NOITE = "#14161C"
LUZ = "#FFD43B"
AMBAR = "#8A5A00"
FUNDO = "#F4F5F7"
TINTA = "#14161C"
SUAVE = "#5A5F6B"
LINHA = "#E3E5EA"
LIT = ["#2E7D4F", "#6B3FA0", "#B3261E", "#C9A227", "#D96C9A"]

SERIF = "'Cormorant Garamond', Georgia, 'Times New Roman', serif"
SANS = "'Atkinson Hyperlegible', 'Segoe UI', Arial, Helvetica, sans-serif"


def marca(cor, tam=28):
    """Quatro painéis com a cruz no vão, feita com tabela (funciona sem imagens)."""
    p = round(tam * 0.44)
    v = tam - 2 * p
    cel = f'<td width="{p}" height="{p}" style="width:{p}px;height:{p}px;background:{cor};border-radius:2px;font-size:0;line-height:0">&nbsp;</td>'
    gap_c = f'<td width="{v}" style="width:{v}px;font-size:0;line-height:0">&nbsp;</td>'
    gap_l = f'<tr><td colspan="3" height="{v}" style="height:{v}px;font-size:0;line-height:0">&nbsp;</td></tr>'
    return (f'<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="border-collapse:separate">'
            f'<tr>{cel}{gap_c}{cel}</tr>{gap_l}<tr>{cel}{gap_c}{cel}</tr></table>')


def faixa_liturgica():
    tds = "".join(f'<td height="4" style="height:4px;background:{c};font-size:0;line-height:0">&nbsp;</td>' for c in LIT)
    return f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>{tds}</tr></table>'


def botao(texto, url):
    return f'''<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:28px 0 8px">
  <tr><td style="background:{NOITE};border-radius:8px">
    <a href="{url}" target="_blank" style="display:inline-block;padding:15px 28px;font-family:{SANS};font-size:16px;font-weight:700;color:{LUZ};text-decoration:none;border-radius:8px">{texto}</a>
  </td></tr>
</table>'''


def codigo():
    return f'''<p style="margin:20px 0 6px;font-family:{SANS};font-size:13px;letter-spacing:.08em;text-transform:uppercase;color:{SUAVE}">Ou digite o código</p>
<p style="margin:0;font-family:{SANS};font-size:30px;font-weight:700;letter-spacing:.28em;color:{TINTA}">{{{{ .Token }}}}</p>'''


def link_reserva(url):
    return f'''<p style="margin:22px 0 0;font-family:{SANS};font-size:13px;line-height:1.55;color:{SUAVE}">Se o botão não abrir, copie este endereço no navegador:<br>
<a href="{url}" style="color:{AMBAR};word-break:break-all">{url}</a></p>'''


def pagina(previa, rotulo, titulo, corpo, acao, aviso):
    return f'''<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>{titulo}</title>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@600&family=Atkinson+Hyperlegible:wght@400;700&display=swap" rel="stylesheet">
</head>
<body style="margin:0;padding:0;background:{FUNDO};-webkit-text-size-adjust:100%">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:{FUNDO}">{previa}&#8199;&#65279;&#847;&#8199;&#65279;&#847;&#8199;&#65279;&#847;</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:{FUNDO}">
<tr><td align="center" style="padding:32px 16px">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px">
    <tr><td style="background:{NOITE};border-radius:14px 14px 0 0;padding:26px 32px">
      <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
        <td valign="middle">{marca(LUZ)}</td>
        <td valign="middle" style="padding-left:12px;font-family:{SERIF};font-size:26px;font-weight:600;color:#FFFFFF;line-height:1">Telão Missa</td>
      </tr></table>
    </td></tr>
    <tr><td style="font-size:0;line-height:0">{faixa_liturgica()}</td></tr>
    <tr><td style="background:#FFFFFF;padding:36px 32px 32px;border-left:1px solid {LINHA};border-right:1px solid {LINHA}">
      <p style="margin:0 0 10px;font-family:{SANS};font-size:12px;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:{AMBAR}">{rotulo}</p>
      <h1 style="margin:0 0 18px;font-family:{SERIF};font-size:32px;font-weight:600;line-height:1.15;color:{TINTA}">{titulo}</h1>
      {corpo}
      {acao}
      <p style="margin:28px 0 0;padding-top:20px;border-top:1px solid {LINHA};font-family:{SANS};font-size:14px;line-height:1.55;color:{SUAVE}">{aviso}</p>
    </td></tr>
    <tr><td style="background:#FFFFFF;border:1px solid {LINHA};border-top:0;border-radius:0 0 14px 14px;padding:0 32px 26px">
      <p style="margin:0;font-family:{SANS};font-size:13px;line-height:1.6;color:{SUAVE}">Telão Missa — a liturgia em luz, pronta em minutos.<br>
      <a href="https://telaomissa.com.br" style="color:{AMBAR};text-decoration:none">telaomissa.com.br</a> · WhatsApp <a href="https://wa.me/5543991550595" style="color:{AMBAR};text-decoration:none">(43) 99155-0595</a> · <a href="mailto:contato@telaomissa.com.br" style="color:{AMBAR};text-decoration:none">contato@telaomissa.com.br</a></p>
    </td></tr>
    <tr><td align="center" style="padding:20px 8px 0;font-family:{SERIF};font-size:16px;font-style:italic;color:{SUAVE}">“Tua palavra é lâmpada para os meus pés.” — Sl 118(119),105</td></tr>
  </table>
</td></tr>
</table>
</body>
</html>
'''


def p(t):
    return f'<p style="margin:0 0 14px;font-family:{SANS};font-size:16px;line-height:1.6;color:{TINTA}">{t}</p>'


URL = "{{ .ConfirmationURL }}"

MODELOS = [
    dict(
        arq="confirmar-cadastro", nome="Confirm signup",
        assunto="Confirme seu e-mail para começar no Telão Missa",
        previa="Falta um passo: confirme seu e-mail e monte a primeira missa.",
        rotulo="Boas-vindas",
        titulo="Confirme seu e-mail",
        corpo=p("Que bom ter você no Telão Missa. Confirme que este endereço é seu e sua paróquia já pode montar a primeira missa: leituras do dia, cantos, orações e avisos num roteiro só.")
              + p(f"A conta é de <strong>{{{{ .Email }}}}</strong>. Os 30 dias de teste começam quando a paróquia é cadastrada."),
        acao=botao("Confirmar e-mail", URL) + link_reserva(URL),
        aviso="Se você não criou uma conta no Telão Missa, ignore este e-mail. Nada será feito com este endereço.",
    ),
    dict(
        arq="recuperar-senha", nome="Reset password",
        assunto="Crie uma nova senha no Telão Missa",
        previa="Recebemos o pedido para trocar a senha da sua conta.",
        rotulo="Acesso à conta",
        titulo="Crie uma nova senha",
        corpo=p(f"Recebemos um pedido para trocar a senha da conta <strong>{{{{ .Email }}}}</strong>. Abra o link abaixo e escolha a nova senha; ele vale por 1 hora e só pode ser usado uma vez."),
        acao=botao("Criar nova senha", URL) + link_reserva(URL),
        aviso="Se não foi você que pediu, ignore este e-mail: sua senha atual continua valendo.",
    ),
    dict(
        arq="link-de-acesso", nome="Magic link",
        assunto="Seu link para entrar no Telão Missa",
        previa="Entre com um toque, sem digitar a senha.",
        rotulo="Entrar",
        titulo="Seu link para entrar",
        corpo=p("Use o botão para entrar no Telão Missa sem digitar a senha. O link vale por 1 hora e funciona uma única vez."),
        acao=botao("Entrar no Telão Missa", URL) + codigo() + link_reserva(URL),
        aviso="Se você não pediu para entrar, ignore este e-mail. Ninguém acessa sua conta sem este link.",
    ),
    dict(
        arq="convite", nome="Invite user",
        assunto="Você foi convidado para a equipe do telão",
        previa="Aceite o convite e ajude a levar a missa ao telão.",
        rotulo="Convite para a equipe",
        titulo="Você foi convidado para a equipe do telão",
        corpo=p("A coordenação da sua paróquia convidou você para servir na equipe do Telão Missa: montar o roteiro da missa, cuidar dos cantos ou conduzir o telão na celebração.")
              + p("Aceite o convite e crie sua senha para começar."),
        acao=botao("Aceitar convite", URL) + link_reserva(URL),
        aviso="Se você não esperava este convite, ignore este e-mail. Nenhuma conta é criada sem você aceitar.",
    ),
    dict(
        arq="trocar-email", nome="Change email address",
        assunto="Confirme o novo e-mail da sua conta",
        previa="Confirme a troca do e-mail de acesso ao Telão Missa.",
        rotulo="Acesso à conta",
        titulo="Confirme o novo e-mail",
        corpo=p(f"Você pediu para trocar o e-mail de acesso de <strong>{{{{ .Email }}}}</strong> para <strong>{{{{ .NewEmail }}}}</strong>. Confirme para concluir a troca."),
        acao=botao("Confirmar novo e-mail", URL) + link_reserva(URL),
        aviso="Se não foi você que pediu, não clique no botão e troque sua senha. Fale com a gente pelo WhatsApp se precisar de ajuda.",
    ),
    dict(
        arq="reautenticacao", nome="Reauthentication",
        assunto="Código de confirmação do Telão Missa",
        previa="Use este código para confirmar a alteração na sua conta.",
        rotulo="Confirmação",
        titulo="Confirme que é você",
        corpo=p("Para concluir a alteração na sua conta, digite o código abaixo no Telão Missa.")
              + f'<p style="margin:22px 0 0;font-family:{SANS};font-size:34px;font-weight:700;letter-spacing:.28em;color:{TINTA}">{{{{ .Token }}}}</p>',
        acao="",
        aviso="Se você não está alterando nada na sua conta, ignore este e-mail e troque sua senha por segurança.",
    ),
]


def main():
    linhas = []
    for m in MODELOS:
        html = pagina(m["previa"], m["rotulo"], m["titulo"], m["corpo"], m["acao"], m["aviso"])
        (PASTA / f'{m["arq"]}.html').write_text(html, encoding="utf-8")
        linhas.append(f'{m["nome"]}\t{m["arq"]}.html\t{m["assunto"]}')
    (PASTA / "assuntos.txt").write_text("\n".join(linhas) + "\n", encoding="utf-8")
    print("\n".join(linhas))


if __name__ == "__main__":
    main()

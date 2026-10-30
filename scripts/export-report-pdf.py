#!/usr/bin/env python3
"""Exportador academico opcional. Dependencia: reportlab (fora do nucleo Bash)."""
from pathlib import Path
from html import escape
import re
import sys
import textwrap
import os

try:
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_LEFT
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase import ttfonts
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, LongTable, KeepTogether, XPreformatted
except ImportError:
    raise SystemExit("Instale reportlab em um venv e configure CATALYST_PDF_PYTHON=/caminho/venv/bin/python3.")


def export(source: Path, target: Path) -> None:
    fonts = Path('/usr/share/fonts/truetype/dejavu')
    for name, filename in [('Body', 'DejaVuSans.ttf'), ('Mono', 'DejaVuSansMono.ttf')]:
        font = fonts / filename
        if not font.exists():
            raise SystemExit(f'Fonte necessaria ausente: {font}')
        pdfmetrics.registerFont(TTFont(name, str(font)))
    symbol_candidates = [os.environ.get('CATALYST_SYMBOL_FONT', ''),
                         '/usr/share/fonts/truetype/noto/NotoSansSymbols2-Regular.ttf',
                         '/mnt/c/Windows/Fonts/seguiemj.ttf']
    symbol_fonts = []
    for number, filename in enumerate(symbol_candidates):
        if filename and Path(filename).is_file():
            name = f'Symbols{number}'
            pdfmetrics.registerFont(TTFont(name, filename))
            symbol_fonts.append(name)

    def source_markup(text):
        result = []
        for character in text:
            if character in '\n\r\t' or ord(character) in pdfmetrics.getFont('Mono').face.charWidths:
                result.append(escape(character))
                continue
            for font in symbol_fonts:
                if ord(character) in pdfmetrics.getFont(font).face.charWidths:
                    result.append(f'<font name="{font}">{escape(character)}</font>')
                    break
            else:
                # Preserva a identidade do caractere quando nao existe fonte local.
                result.append(f'\\U{ord(character):08x}')
        return ''.join(result)
    body = ParagraphStyle('ReportBody', fontName='Body', fontSize=9, leading=13, spaceAfter=7)
    cell = ParagraphStyle('Cell', parent=body, fontSize=6.5, leading=9, wordWrap='CJK', spaceAfter=0)
    mono = ParagraphStyle('Source', fontName='Mono', fontSize=6, leading=8, alignment=TA_LEFT)
    title_styles = {}
    for level, size in [(1, 19), (2, 13), (3, 10)]:
        title_styles[level] = ParagraphStyle(f'Title{level}', parent=body, fontSize=size,
                                           leading=size + 5, spaceBefore=12, spaceAfter=8,
                                           keepWithNext=True)
    story = []
    lines = source.read_text(encoding='utf-8').splitlines()
    index = 0
    while index < len(lines):
        line = lines[index]
        if line.startswith('```'):
            index += 1
            code = []
            while index < len(lines) and not lines[index].startswith('```'):
                # Mantem todas as linhas e numera a linha original, mesmo com quebra visual.
                code.extend(textwrap.wrap(lines[index].expandtabs(4), width=195,
                                          subsequent_indent='      ', replace_whitespace=False,
                                          drop_whitespace=False) or [''])
                index += 1
            if index == len(lines):
                raise ValueError('Bloco de codigo sem fechamento no relatorio.')
            # Blocos pequenos permitem paginacao sem manter milhares de linhas juntas.
            for offset in range(0, len(code), 40):
                block = XPreformatted(source_markup('\n'.join(code[offset:offset + 40])), mono)
                story.append(KeepTogether([block]) if len(code) < 20 else block)
            story.append(Spacer(1, 8))
        elif line.startswith('|'):
            rows = []
            while index < len(lines) and lines[index].startswith('|'):
                values = [v.strip() for v in lines[index].strip('|').split('|')]
                if not all(re.fullmatch(r'[-:]+', v) for v in values):
                    rows.append([Paragraph(escape(v.replace('`', '').replace('&#124;', '|')), cell) for v in values])
                index += 1
            table = LongTable(rows, colWidths=[23, 48, 113, 30, 270, 285], repeatRows=1,
                              hAlign='LEFT')
            table.setStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#e8edf2')),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('GRID', (0, 0), (-1, -1), .3, colors.HexColor('#b7c1cb')),
                ('LEFTPADDING', (0, 0), (-1, -1), 5),
                ('RIGHTPADDING', (0, 0), (-1, -1), 5),
                ('TOPPADDING', (0, 0), (-1, -1), 5),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
            ])
            story.append(table)
            continue
        elif line.startswith('#'):
            match = re.match(r'^(#{1,3}) (.*)', line)
            if match:
                story.append(Paragraph(escape(match[2]), title_styles[len(match[1])]))
        elif line.strip():
            paragraph = [line]
            while index + 1 < len(lines) and lines[index + 1].strip() and not lines[index + 1].startswith(('#', '|', '```')):
                index += 1
                paragraph.append(lines[index])
            text = escape(' '.join(paragraph))
            text = re.sub(r'`([^`]+)`', r'<font name="Mono">\1</font>', text)
            story.append(Paragraph(text, body))
        index += 1

    def footer(canvas, doc):
        canvas.setFont('Body', 7)
        canvas.drawString(36, 18, 'CEFET-MG | Catalyst Shell Engine | Relatorio academico')
        canvas.drawRightString(landscape(A4)[0] - 36, 18, str(doc.page))

    target.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(str(target), pagesize=landscape(A4), leftMargin=36, rightMargin=36,
                            topMargin=30, bottomMargin=32, title='Catalyst Shell Engine - Relatorio',
                              author='Matheus Thiago de Souza Ferreira',
                              invariant='SOURCE_DATE_EPOCH' in os.environ)
    original_cmap = ttfonts.makeToUnicodeCMap

    def unicode_cmap(*args, **kwargs):
        # Algumas versoes do ReportLab emitem codepoints nao BMP como cinco
        # digitos hexadecimais. PDF exige UTF-16BE, com par substituto nesses casos.
        cmap = original_cmap(*args, **kwargs)
        return re.sub(r'<([0-9A-Fa-f]{5,6})>',
                      lambda m: '<' + chr(int(m[1], 16)).encode('utf-16-be').hex().upper() + '>', cmap)

    ttfonts.makeToUnicodeCMap = unicode_cmap
    try:
        doc.build(story, onFirstPage=footer, onLaterPages=footer)
    finally:
        ttfonts.makeToUnicodeCMap = original_cmap
    print(f'PDF gerado: {target}')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Uso: export-report-pdf.py RELATORIO.md SAIDA.pdf')
    export(Path(sys.argv[1]), Path(sys.argv[2]))

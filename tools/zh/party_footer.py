"""Compile explicit CSV footer translations; no built-in translated labels."""
import csv
from PIL import Image, ImageDraw, ImageFont

IDS = {
    'cancel': 'engine/pokemon/party_menu.asm::PlacePartyNicknames.Cancel::1',
    'prompt': 'engine/pokemon/party_menu.asm::ChooseAMonString::1',
}

def generate(source, language, font_path):
    with (source / 'translations.csv').open(encoding='utf-8-sig', newline='') as f:
        rows = {r['id']: r for r in csv.DictReader(f)}
    font = ImageFont.truetype(str(font_path), 12)
    lines = []
    for key, width, height, baseline in [('cancel',24,24,15), ('prompt',144,16,12)]:
        text = rows[IDS[key]].get('translation_' + language, '').strip().rstrip('@')
        if '\n' in text or font.getlength(text) > width:
            raise ValueError('Party footer exceeds pixel budget: ' + key)
        lines.append('DEF ZH_PARTY_' + key.upper() + ' EQU ' + str(int(bool(text))))
        canvas = Image.new('1', (width, height))
        draw = ImageDraw.Draw(canvas); draw.fontmode = '1'
        draw.text((0, baseline), text, font=font, fill=1, anchor='ls')
        data = []
        for ty in range(height//8):
            for tx in range(width//8):
                for y in range(8):
                    v = sum(128>>x for x in range(8) if canvas.getpixel((tx*8+x,ty*8+y)))
                    data.extend((v,v))
        lines.extend(['ZhParty' + key.title() + 'Tiles:', ' db ' + ','.join(map(str,data))])
    (source / 'data/zh/party_footer.asm').write_text('\n'.join(lines)+'\n')

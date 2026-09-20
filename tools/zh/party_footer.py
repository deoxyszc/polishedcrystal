"""Compile explicit CSV footer translations; no built-in translated labels."""
import csv
from PIL import ImageFont
from text_layout import text_image, encode_2bpp

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
        data = encode_2bpp(text_image(font,text,width,height,baseline=baseline))
        lines.extend(['ZhParty' + key.title() + 'Tiles:', ' db ' + ','.join(map(str,data))])
    (source / 'data/zh/party_footer.asm').write_text('\n'.join(lines)+'\n')

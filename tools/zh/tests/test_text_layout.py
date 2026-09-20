"""Shared layout preserves pixel flow, dense lines and palette tile order."""
import sys
import unittest
from pathlib import Path
from PIL import Image, ImageFont
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from text_layout import TextLayout, TextStyle, encode_2bpp

class LayoutTests(unittest.TestCase):
 def setUp(self):self.font=ImageFont.load_default()
 def test_inline_fragments_equal_whole_line(self):
  a=TextLayout(self.font,96).append('Level ').append('100')
  b=TextLayout(self.font,96).append('Level 100')
  self.assertEqual(a.x,b.x)
  self.assertEqual(a.image.tobytes(),b.image.tobytes())
 def test_overflow_and_unresolved_tokens_rejected(self):
  for text in ['a'*50,'{next}']:
   with self.assertRaises(ValueError):TextLayout(self.font,24).append(text)
  with self.assertRaises(ValueError):TextLayout(self.font,24,8).append('ABC',baseline=16)
 def test_dense_lines_cross_tile_boundary(self):
  surface=TextLayout(self.font,96,32,style=TextStyle(baseline=12,line_step=13))
  surface.lines(['First','Second'])
  self.assertEqual(surface.baseline,25)
  self.assertEqual(len(encode_2bpp(surface.image)),96*32//4)
 def test_tile_palette_and_order(self):
  im=Image.new('P',(16,8));im.putpixel((0,0),1);im.putpixel((7,0),2);im.putpixel((8,0),3)
  data=encode_2bpp(im)
  self.assertEqual(data[:2],bytes([128,1]))
  self.assertEqual(data[16:18],bytes([128,128]))
  with self.assertRaises(ValueError):encode_2bpp(Image.new('1',(12,12)))
if __name__=='__main__':unittest.main()

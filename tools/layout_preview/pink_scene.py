"""Explicit pink-page extraction; never infer transparency by global white key."""
import base64

def extract(rgb):
    raw=bytearray(base64.b64decode(rgb)); clean=bytearray(raw);elements=[]
    # Rectangles are measured on the original 160x144 English pink page.
    regions=[
        ('图鉴编号',64,16,48,8),('昵称',64,32,88,8),
        ('物种名与斜杠',72,44,80,8),('训练家',64,72,80,8),
        ('训练家ID',72,84,80,8),('页签文字',16,92,24,8),
        ('经验标签',8,104,80,8),('经验数值',96,104,56,8),
        ('升级标签',8,120,64,8),('所需经验',96,120,56,8),
        ('升级提示',104,132,48,12),('经验条',8,132,74,12),
        ('宝可梦立绘',0,16,56,56),('等级',0,72,32,8),
        ('性别',40,72,8,8),('属性',64,60,28,8),('精灵球',132,56,20,16),
    ]
    for name,x,y,w,h in regions:
        # Region background is a known flat panel color sampled at right edge.
        bg=bytes(raw[(y*160+159)*3:(y*160+159)*3+3]) if y>=104 else bytes(raw[(y*160+155)*3:(y*160+155)*3+3])
        if name=='页签文字':bg=bytes(raw[(95*160+38)*3:(95*160+38)*3+3])
        if name in ('宝可梦立绘','等级','性别'):bg=bytes(raw[:3])
        rgba=[]
        for yy in range(y,y+h):
            for xx in range(x,x+w):
                offset=(yy*160+xx)*3;p=bytes(raw[offset:offset+3]);rgba.extend((*p,0 if p==bg else 255));clean[offset:offset+3]=bg
        elements.append(dict(type='image',name=name,text=name,x=x,y=y,w=w,h=h,rgba=base64.b64encode(bytes(rgba)).decode(),cjk=4,latin=8,color='#000000',opaque=False))
    # Assert exact compositing round trip: no lost border/bar pixels.
    rebuilt=bytearray(clean)
    for e in elements:
        pixels=base64.b64decode(e['rgba'])
        for yy in range(e['h']):
            for xx in range(e['w']):
                i=(yy*e['w']+xx)*4;j=((e['y']+yy)*160+e['x']+xx)*3
                if pixels[i+3]:rebuilt[j:j+3]=pixels[i:i+3]
    if rebuilt!=raw:raise ValueError('Scene extraction does not reproduce original pixels')
    return base64.b64encode(clean).decode(),elements

import re

CANON_OUTLINE='#1f2223'; CANON_MAIN='#959379'; CANON_SHADE='#606659'; MOUTH_RED='#6b3439'
OUTLINE={'#462c16','#472c16','#482f17','#452b15','#452c15','#482d16','#482e16',
         '#462b15','#4a2d16','#462a15','#4a2f16'}
MAIN={'#f9b551','#f9b452'}
SHADE={'#c87e36','#c77a33','#cb8236','#c77a32'}

def canon(hex_):
    h=hex_.lower()
    if h in OUTLINE: return CANON_OUTLINE
    if h in MAIN: return CANON_MAIN
    if h in SHADE: return CANON_SHADE
    if h==MOUTH_RED: return MOUTH_RED
    raise SystemExit('unknown fill '+hex_)

def parse_svg(path):
    s=open(path,encoding='utf-8').read()
    classes=dict(re.findall(r'\.(st\d+)\s*\{\s*fill:\s*(#[0-9a-fA-F]{6});',s))
    recs=[]
    for p in re.findall(r'<path\b[^>]*?/>', s, re.S):
        pid=re.search(r'\bid="([^"]*)"',p).group(1)
        st=(re.search(r'style="([^"]*)"',p) or [None,''])[1]
        cls=(re.search(r'\bclass="([^"]*)"',p) or [None,''])[1]
        d=re.sub(r'\s+',' ',re.search(r'\bd="([^"]*)"',p,re.S).group(1)).strip()
        m=re.search(r'fill:\s*(#[0-9a-fA-F]{6})',st)
        fill=m.group(1) if m else classes.get(cls)
        recs.append(dict(id=pid,fill=fill,d=d,hidden='display:none' in st))
    return recs

TOK=re.compile(r'([MmLlHhVvZz])|(-?\d*\.?\d+(?:[eE][-+]?\d+)?)')

def to_points(d):
    """Return list of subpaths, each a list of absolute (x,y) vertices."""
    toks=[(a,b) for a,b in TOK.findall(d)]
    i=0; cmd=None; cx=cy=0.0; sx=sy=0.0
    subs=[]; cur=None
    def num():
        nonlocal i
        while toks[i][0]: i+=1
        v=float(toks[i][1]); i+=1; return v
    while i<len(toks):
        if toks[i][0]:
            cmd=toks[i][0]; i+=1
            if cmd in 'Zz':
                if cur: subs.append(cur); cur=None
                cx,cy=sx,sy
                continue
        if i>=len(toks): break
        if cmd in 'Mm':
            x=num(); y=num()
            if cmd=='m': x+=cx; y+=cy
            cx,cy=x,y; sx,sy=x,y
            if cur: subs.append(cur)
            cur=[(cx,cy)]
            cmd='L' if cmd=='M' else 'l'
        elif cmd in 'Ll':
            x=num(); y=num()
            if cmd=='l': x+=cx; y+=cy
            cx,cy=x,y; cur.append((cx,cy))
        elif cmd in 'Hh':
            x=num()
            if cmd=='h': x+=cx
            cx=x; cur.append((cx,cy))
        elif cmd in 'Vv':
            y=num()
            if cmd=='v': y+=cy
            cy=y; cur.append((cx,cy))
        else:
            raise SystemExit('cmd? '+str(cmd))
    if cur: subs.append(cur)
    return subs

def emit(subs, dx, dy, rnd=True):
    out=[]
    for pts in subs:
        p=[( (x+dx), (y+dy) ) for x,y in pts]
        if rnd: p=[(round(x),round(y)) for x,y in p]
        # drop consecutive duplicates
        q=[p[0]]
        for pt in p[1:]:
            if pt!=q[-1]: q.append(pt)
        if len(q)>1 and q[0]==q[-1]: q.pop()
        def fmt(v): return str(int(v)) if float(v)==int(v) else ('%g'%v)
        s='M%s %s'%(fmt(q[0][0]),fmt(q[0][1]))
        px,py=q[0]
        for x,y in q[1:]:
            if y==py: s+='H%s'%fmt(x)
            elif x==px: s+='V%s'%fmt(y)
            else: s+='L%s %s'%(fmt(x),fmt(y))
            px,py=x,y
        out.append(s+'Z')
    return ''.join(out)

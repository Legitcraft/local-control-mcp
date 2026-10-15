import ctypes, json, sys, subprocess, os

user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

INPUT_KEYBOARD = 1
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_UNICODE = 0x0004

VK = {
 "enter":0x0D,"tab":0x09,"esc":0x1B,"space":0x20,"backspace":0x08,"delete":0x2E,
 "up":0x26,"down":0x28,"left":0x25,"right":0x27,"home":0x24,"end":0x23,
 "pageup":0x21,"pagedown":0x22,
 "ctrl":0x11,"control":0x11,"shift":0x10,"alt":0x12,"win":0x5B,"windows":0x5B,
 **{f"f{i}":0x6F+i for i in range(1,13)},
}
for i,c in enumerate("abcdefghijklmnopqrstuvwxyz"):
    VK[c]=0x41+i
for i in range(10): VK[str(i)]=0x30+i

class KEYBDINPUT(ctypes.Structure):
    _fields_=[("wVk",ctypes.c_ushort),("wScan",ctypes.c_ushort),
              ("dwFlags",ctypes.c_ulong),("time",ctypes.c_ulong),
              ("dwExtraInfo",ctypes.POINTER(ctypes.c_ulong))]
class INPUT(ctypes.Structure):
    _fields_=[("type",ctypes.c_ulong),("ki",KEYBDINPUT)]

def send_key(vk, up=False):
    inp=INPUT(); inp.type=INPUT_KEYBOARD; inp.ki.wVk=vk
    if up: inp.ki.dwFlags=KEYEVENTF_KEYUP
    user32.SendInput(1,ctypes.byref(inp),ctypes.sizeof(INPUT))

def press_combo(combo):
    parts=[p.strip().lower() for p in combo.split("+")]
    mods=[]; key=None
    for p in parts:
        if p in ("ctrl","control"): mods.append(0x11)
        elif p=="shift": mods.append(0x10)
        elif p=="alt": mods.append(0x12)
        elif p in ("win","windows"): mods.append(0x5B)
        else: key=p
    for m in mods: send_key(m)
    if key:
        k=VK.get(key)
        if k is None: return f"unknown key {key}"
        send_key(k); send_key(k,True)
    for m in reversed(mods): send_key(m,True)
    return "ok"

def type_text(text):
    for ch in text:
        code=ord(ch)
        inp=INPUT(); inp.type=INPUT_KEYBOARD; inp.ki.wVk=0
        inp.ki.wScan=code; inp.ki.dwFlags=KEYEVENTF_UNICODE
        user32.SendInput(1,ctypes.byref(inp),ctypes.sizeof(INPUT))
        inp.ki.dwFlags=KEYEVENTF_UNICODE|KEYEVENTF_KEYUP
        user32.SendInput(1,ctypes.byref(inp),ctypes.sizeof(INPUT))
    return "typed"

def tools():
    return [
      {"name":"mouse_move","description":"Move mouse","inputSchema":{"type":"object","properties":{"x":{"type":"integer"},"y":{"type":"integer"}},"required":["x","y"]}},
      {"name":"mouse_click","description":"Click mouse","inputSchema":{"type":"object","properties":{"button":{"type":"string","enum":["left","right","middle","double"]},"x":{"type":"integer"},"y":{"type":"integer"}}}},
      {"name":"mouse_scroll","description":"Scroll wheel","inputSchema":{"type":"object","properties":{"delta":{"type":"integer"}},"required":["delta"]}},
      {"name":"type_text","description":"Type text","inputSchema":{"type":"object","properties":{"text":{"type":"string"}},"required":["text"]}},
      {"name":"press_key","description":"Press key combo","inputSchema":{"type":"object","properties":{"combo":{"type":"string"}},"required":["combo"]}},
      {"name":"screenshot","description":"Take screenshot","inputSchema":{"type":"object","properties":{"path":{"type":"string"}}}},
      {"name":"run_powershell","description":"Run a PowerShell command","inputSchema":{"type":"object","properties":{"command":{"type":"string"}},"required":["command"]}},
    ]

def call(name,args):
    if name=="mouse_move":
        user32.SetCursorPos(int(args["x"]),int(args["y"])); return "moved"
    if name=="mouse_click":
        b=args.get("button","left")
        x=args.get("x"); y=args.get("y")
        if x is not None and y is not None: user32.SetCursorPos(int(x),int(y))
        flags={"left":(0x0002,0x0004),"right":(0x0008,0x0010),"middle":(0x0020,0x0040)}
        if b=="double":
            for _ in range(2):
                user32.mouse_event(0x0002,0,0,0,0); user32.mouse_event(0x0004,0,0,0,0)
        else:
            d,u=flags.get(b,flags["left"]); user32.mouse_event(d,0,0,0,0); user32.mouse_event(u,0,0,0,0)
        return f"clicked {b}"
    if name=="mouse_scroll":
        user32.mouse_event(0x0800,0,0,int(args["delta"])*120,0); return "scrolled"
    if name=="type_text":
        return type_text(args["text"])
    if name=="press_key":
        return press_combo(args["combo"])
    if name=="screenshot":
        p=args.get("path") or os.path.join(os.environ["TEMP"],f"screenshot.bmp")
        # delegate to powershell for robust png
        subprocess.run(["powershell","-ExecutionPolicy","Bypass","-NoProfile","-File",os.path.join(os.path.dirname(__file__),"control.ps1"),"screenshot",p],capture_output=True)
        return p
    if name=="run_powershell":
        r=subprocess.run(["powershell","-ExecutionPolicy","Bypass","-NoProfile","-Command",args["command"]],capture_output=True,text=True)
        return r.stdout or r.stderr
    return "unknown tool"

def main():
    for line in sys.stdin:
        line=line.strip()
        if not line: continue
        req=json.loads(line)
        rid=req.get("id")
        method=req.get("method")
        if method=="initialize":
            res={"jsonrpc":"2.0","id":rid,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{}},"serverInfo":{"name":"local-control","version":"1.0"}}}
        elif method=="tools/list":
            res={"jsonrpc":"2.0","id":rid,"result":{"tools":tools()}}
        elif method=="tools/call":
            p=req.get("params",{})
            out=call(p.get("name"),p.get("arguments",{}))
            res={"jsonrpc":"2.0","id":rid,"result":{"content":[{"type":"text","text":str(out)}]}}
        elif method=="ping":
            res={"jsonrpc":"2.0","id":rid,"result":{}}
        else:
            res={"jsonrpc":"2.0","id":rid,"error":{"code":-32601,"message":"not found"}}
        sys.stdout.write(json.dumps(res)+"\n"); sys.stdout.flush()

if __name__=="__main__":
    main()

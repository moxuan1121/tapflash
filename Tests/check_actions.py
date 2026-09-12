from pathlib import Path

source = Path("Tweak.xm").read_text()
body = source.split("- (void)longPress:(id)press {", 1)[1].split("}", 1)[0]
assert 'notify_post("com.moxuan.regionshot/AICamera")' in body
assert "%orig" not in body

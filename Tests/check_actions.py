from pathlib import Path

source = Path("Tweak.xm").read_text()
assert "- (void)longPress:(id)press" not in source
assert "kDoubleVolumeDownThreshold = 1.0" in source
body = source.split("static void TapFlashHandleVolumeDownPress(void) {", 1)[1].split("\n}", 1)[0]
assert 'notify_post("com.moxuan.regionshot/AICamera")' in body
hook = source.split("- (void)volumeDecreasePressDownWithModifiers:(long long)modifiers {", 1)[1].split("}", 1)[0]
assert "%orig" in hook
assert "TapFlashHandleVolumeDownPress();" in hook

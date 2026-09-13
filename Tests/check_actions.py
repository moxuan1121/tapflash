from pathlib import Path

source = Path("Tweak.xm").read_text()
assert "- (void)longPress:(id)press" not in source
assert "SBVolumeHardwareButtonActions" not in source
assert "MRMediaRemote" not in source
double_press = source.split("- (void)doublePress:(id)press {", 1)[1].split("}", 1)[0]
assert 'notify_post("com.moxuan.regionshot/AICamera")' in double_press
assert "%orig" not in double_press
triple_press = source.split("- (void)triplePress:(id)press {", 1)[1].split("}", 1)[0]
assert "TapFlashToggleFlashlight();" in triple_press

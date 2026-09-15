from pathlib import Path

source = Path("Tweak.xm").read_text()
assert "- (void)longPress:(id)press" not in source
assert "SBVolumeHardwareButtonActions" not in source
assert "SBA_SystemOwnsDoublePress" in source
double_press = source.split("- (void)doublePress:(id)press {", 1)[1].split("}", 1)[0]
assert 'SBAActionForPress(@"DoublePressAction", @"aicamera")' in double_press
assert "%orig" in double_press
triple_press = source.split("- (void)triplePress:(id)press {", 1)[1].split("}", 1)[0]
assert "SBA_SendAction(SBAActionForPress(@\"TriplePressAction\", @\"flashlight\"));" in triple_press

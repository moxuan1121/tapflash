from pathlib import Path

source = Path("Tweak.xm").read_text()
assert "- (void)longPress:(id)press" not in source
assert "SBVolumeHardwareButtonActions" not in source
assert "SBA_SystemOwnsDoublePress" in source
assert 'SBAActionForPress(@"DoublePressAction", @"aicamera")' in source
assert "SBA_SystemOwnsDoublePress" not in source
assert "SBA_SendAction(SBAActionForPress(@\"TriplePressAction\", @\"flashlight\"));" in source

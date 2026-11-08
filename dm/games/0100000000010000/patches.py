# Super Mario Odyssey (0100000000010000): the rewriter's patches of this game's own builds. dm/tools/patch_nso.py loads every profile's patches.py and applies those of a module's NSO build ID;
# CUTS, OBS and FRAME_STEP as described there ("Registered patches"). Patches of Nintendo SDK module builds are in dm/tools/sdk_patches.py
import struct
from nso_asm import ADRP, B

# Screen shape, wider than 16:9 (the iPhone 15 Pro Max's 19.5:9): the game renders its own shape instead of a stretched or cut 16:9 one.
# The game's display size is constants, not read from the host: the display mode switch main+0x4e27b0 sets the display rectangle for docked (1600x900)
# and handheld (1280x720, the iPhone's mode), and an initial display setting main+0x4bf34c passes both sizes to main+0x924ad0. Each width becomes the
# host's layout width (state +0x44 u32, loader.c from DM_SCREEN_ASPECT; 0 = the game's own) while the height stays 720. The widths stay, so the 3D
# views (1280 wide handheld) grow in width too, and sead::PerspectiveProjection's aspect (+0xb0) follows the wider rectangle (its set(rect) computes
# aspect from the rectangle; the fovy stays, so the horizontal field of view widens by about 22% and the vertical one does not change). No fovy,
# aspect, culling or viewport stub is needed for the wider screen: the projection, the culling tests and the viewport all read the display size or
# the projection's stored fields. x16 is free at both sites: the mode switch's registers are the display object and the size being set; the initial
# setting's are the sizes and the arguments of the call that follows
def frame_step(ctx):
    here, emit, fs_site, fs_put, FS_STATE_OFF = ctx.here, ctx.emit, ctx.site, ctx.put, ctx.state

    def wider(site, orig, apply, why):
        fs_site(site, orig)
        start = here(); emit(struct.unpack('<I', bytes.fromhex(orig))[0])   # the original instruction
        emit(ADRP(16, here(), FS_STATE_OFF))
        for w in (0xb9404610, 0x34000050, apply):   # ldr w16,[x16,#0x44]; cbz w16,+8 (0: the game's width); the host's layout width
            emit(w)
        emit(B(here(), site + 4))
        fs_put(site, [B(site, start)], why)
    wider(0x4e27d8, '03a08052', 0x2a1003e3, 'handheld display width 1280 -> the host\'s layout width (state +0x44; 0 = the game\'s own)')
    wider(0x4bf354, '06a08052', 0x2a1003e6, 'initial handheld width 1280 -> the host\'s layout width (state +0x44; 0 = the game\'s own)')


FRAME_STEP = {'b424be150a8e7d78701cbe7a439d9ebf': frame_step}

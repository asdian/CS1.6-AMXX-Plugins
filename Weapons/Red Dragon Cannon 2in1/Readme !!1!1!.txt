add to cstrike/sprites/hud.txt

d_cannonex		640 640hud40	172	176	48	16


(only for zp) if you just want to use one of them just find the following code :

g_item_cannonex[0] = zp_register_extra_item("Red Dragon Cannon", 30, ZP_TEAM_HUMAN)
g_item_cannonex[1] = zp_register_extra_item("\r(+6) Red Dragon Cannon Chimera", 30, ZP_TEAM_HUMAN)

and disable one of them by adding double slash (//) in very front of the line, then recompile

example:

*for chimera version

from

g_item_cannonex[0] = zp_register_extra_item("Red Dragon Cannon", 30, ZP_TEAM_HUMAN)
g_item_cannonex[1] = zp_register_extra_item("\r(+6) Red Dragon Cannon Chimera", 30, ZP_TEAM_HUMAN)

change to

//g_item_cannonex[0] = zp_register_extra_item("Red Dragon Cannon", 30, ZP_TEAM_HUMAN)
g_item_cannonex[1] = zp_register_extra_item("\r(+6) Red Dragon Cannon Chimera", 30, ZP_TEAM_HUMAN)



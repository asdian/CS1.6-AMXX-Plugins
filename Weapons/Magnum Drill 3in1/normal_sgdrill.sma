#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>

#define PLUGIN "Magnum Drill 3in1"
#define VERSION "1.0"
#define AUTHOR "Asdian"

// Data Config
enum _:ModelType
{
	MODEL_P = 0,
	MODEL_P2 = 3,
	MODEL_V = 6,
	MODEL_W = 9
}

new const WeaponModels[][] =
{
	"models/p_sgdrill.mdl",
	"models/p_sgdrill_d3a3.mdl",
	"models/p_sgdrillgold.mdl",
	
	"models/p_sgdrill_slash.mdl",
	"models/p_sgdrill_slash_d3a3.mdl",
	"models/p_sgdrillgold_slash.mdl",
	
	"models/v_sgdrill.mdl",
	"models/v_sgdrill_d3a3.mdl",
	"models/v_sgdrillgold.mdl",
	
	"models/w_sgdrill.mdl"
}

#define MODEL_W_OLD "models/w_m3.mdl"

new const ShootSounds[][] =
{
	"weapons/sgdrill-1.wav",
	"weapons/sgdrill_slash.wav",
	"weapons/sgdrill_pslash.wav"
}

#define CSW_SGDRILL CSW_M3
#define weapon_sgdrill "weapon_m3"

#define WEAPON_CODE 7272018
#define WEAPON_EVENT "events/m3.sc"

enum _:NewAnim
{
	SGDRILL_IDLE = 0,
	SGDRILL_SHOOT,
	SGDRILL_SLASH,
	SGDRILL_RELOAD,
	SGDRILL_DRAW
}

// Weapon Config
#define DAMAGE 70
#define ACCURACY 23 // 0 - 100 ; -1 Default
#define CLIP 35
#define CLIP2 50
#define BPAMMO 70
#define SPEED 0.32
#define RECOIL 0.5
#define RELOAD_TIME 2.9

#define SLASH_ANGLE 45.0
#define SLASH_RANGE 137.0
#define SLASH_DAMAGE 112.0
#define SLASH_KNOCKBACK 22.0

new g_Had_Base[33], g_iType[33], g_Clip[33], g_OldWeapon[33], Float:g_Recoil[33][3]
new g_SmokePuff_SprId, c_ShellCustom //g_Event_Base, 
	
// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	
	// Event
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	//register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_sgdrill, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_sgdrill, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_sgdrill, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_sgdrill, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_sgdrill, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_sgdrill, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_sgdrill, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	
	// Cache
	register_clcmd("weapon_sgdrill", "hook_weapon")
	register_clcmd("weapon_sgdrillgold", "hook_weapon")
	
	register_clcmd("sgd_def", "zp_extra_item_selected")
	register_clcmd("sgd_chi", "zp_extra_item_selected2")
	register_clcmd("sgd_gold", "zp_extra_item_selected3")
	
	register_cvar("zp_sgdrillgold_unlim_bpammo", "1")
}

public hook_weapon(id) engclient_cmd(id, weapon_sgdrill)

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof(WeaponModels); i++) precache_model(WeaponModels[i])
	for(i = 0; i < sizeof(ShootSounds); i++) precache_sound(ShootSounds[i])
	
	precache_generic("sprites/weapon_sgdrill.txt")
	c_ShellCustom = engfunc(EngFunc_PrecacheModel, "models/shell_sgdrill.mdl")
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	
	//register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "m3"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_SGDRILL || !g_Had_Base[id])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "sgdrill")
	return PLUGIN_CONTINUE
}
#if 0
public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name)) g_Event_Base = get_orig_retval()		
}
#endif
public client_putinserver(id)
{
        Safety_Connected(id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}
 
public Register_HamBot(id)
{
	Register_SafetyFuncBot(id)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")	
}
public client_disconnect(id)
{
        Safety_Disconnected(id)
}

public zp_extra_item_selected(i) Get_Base(i, 0)
public zp_extra_item_selected2(i) Get_Base(i, 1)
public zp_extra_item_selected3(i) Get_Base(i, 2)

public Get_Base(id, type)
{
	Stock_Drop_Slot(id,1)
	
	if(g_Had_Base[id]) Remove_Base(id)
	g_Had_Base[id] = 1
	g_iType[id] = type
	
	fm_give_item(id, weapon_sgdrill)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SGDRILL)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, !g_iType[id]?CLIP:CLIP2)
	cs_set_user_bpammo(id, CSW_SGDRILL, BPAMMO)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_SGDRILL)
	write_byte(!g_iType[id]?CLIP:CLIP2)
	message_end()
}

public Remove_Base(id)
{
	g_Had_Base[id] = 0
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_SGDRILL && g_OldWeapon[id] != CSW_SGDRILL) && g_Had_Base[id])
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_SGDRILL && g_OldWeapon[id] == CSW_SGDRILL) && g_Had_Base[id]) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SGDRILL)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
		set_pdata_float(Ent, 46, SPEED, 4)
		set_pdata_float(Ent, 47, SPEED, 4)
	} else if(CSWID != CSW_SGDRILL && g_OldWeapon[id] == CSW_SGDRILL) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_SGDRILL)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_SGDRILL)
		
		if(pev_valid(ent) && g_Had_Base[id])
		{
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW)
			engfunc(EngFunc_SetModel, ent, WeaponModels[MODEL_P + g_iType[id]])
		}
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_SGDRILL)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_SGDRILL && g_Had_Base[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

#if 0
public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_SGDRILL || !g_Had_Base[invoker])
		return FMRES_IGNORED
	if(eventid != g_Event_Base)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	Set_WeaponAnim(invoker, SGDRILL_SHOOT)
	
	emit_sound(invoker, CHAN_WEAPON, ShootSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	return FMRES_SUPERCEDE
}
#endif

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, MODEL_W_OLD))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_sgdrill, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(g_Had_Base[iOwner])
		{
			set_pev(weapon, pev_iuser2, cs_get_user_bpammo(iOwner, CSW_SGDRILL))
			set_pev(weapon, pev_iuser3, get_pdata_int(weapon, 51, 4))
			set_pev(weapon, pev_iuser4, g_iType[iOwner])
			
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, WeaponModels[MODEL_W])
			
			set_pev(entity, pev_body, g_iType[iOwner])
			Remove_Base(iOwner)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
		
	static Id
	Id = get_pdata_cbase(Ent, 41, 4)
	
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!g_Had_Base[Id])
		return
	
	set_pev(Id, pev_viewmodel2, WeaponModels[MODEL_V + g_iType[Id]])
	set_pev(Id, pev_weaponmodel2, WeaponModels[MODEL_P + g_iType[Id]])
	Set_WeaponAnim(Id, SGDRILL_DRAW)
	
	Set_WpnList(Id)
	set_pev(Ent, pev_iuser1, 0)
	
	static iClip
	iClip = get_pdata_int(Ent, 51, 4)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, Id)
	write_byte(1)
	write_byte(CSW_SGDRILL)
	write_byte(iClip)
	message_end()
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == WEAPON_CODE)
	{
		g_Had_Base[id] = 1
		g_iType[id] = pev(Ent, pev_iuser4)
		
		static iMaxClip; iMaxClip = pev(Ent, pev_iuser3)
		static iBpAmmo; iBpAmmo = pev(Ent, pev_iuser2)
		set_pdata_int(Ent, 51, iMaxClip, 4)
		cs_set_user_bpammo(id, CSW_SGDRILL, iBpAmmo)
		
		set_pev(Ent, pev_impulse, 0)
	}
	
	return HAM_IGNORED	
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Base[id])
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_SGDRILL)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	static iMaxClip; iMaxClip = (!g_iType[id]?CLIP:CLIP2)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(iMaxClip - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		
		if(g_iType[id] == 2 && get_cvar_num("zp_sgdrillgold_unlim_bpammo") == 1)
			cs_set_user_bpammo(id, CSW_SGDRILL, bpammo)		
		else cs_set_user_bpammo(id, CSW_SGDRILL, bpammo - temp1)	
		
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
	}	
	
	WE_SGDrill(id, ent, iClip,bpammo,pev(id, pev_button))
	return HAM_IGNORED
}

public WE_SGDrill(id,iEnt,iClip, bpammo,iButton)
{
	if (get_pdata_float(iEnt, 46, 4) <= 0.0)
	{
		if (iButton & IN_ATTACK2 && iButton & ~IN_ATTACK)
		{
			set_pdata_float(id, 83, 0.6, 5)
			set_pdata_float(iEnt, 46, 1.7, 4)
			set_pdata_float(iEnt, 47, 1.7, 4)
			set_pdata_float(iEnt, 48, 2.0, 4)

			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_fuser4, get_pdata_float(id, 83) + get_gametime())

			set_pev(id, pev_weaponmodel2, WeaponModels[MODEL_P2 + g_iType[id]])
			Set_WeaponAnim(id, SGDRILL_SLASH)
			emit_sound(id, CHAN_WEAPON, ShootSounds[random_num(1,2)], VOL_NORM, ATTN_NORM, 0, random_num(95,110))
		}
		iButton &= ~IN_ATTACK2;
		set_pev(id, pev_button, iButton);
	}

	if (get_pdata_float(id, 83, 5) <= 0.0 && pev(iEnt, pev_iuser1) == 1)
	{
		new Float:fMul = !g_iType[id]?1.0:float(g_iType[id])
		KnifeAttack2(id, false, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE * fMul, SLASH_KNOCKBACK)
		set_pev(id, pev_weaponmodel2, WeaponModels[MODEL_P + g_iType[id]])
		set_pev(iEnt, pev_iuser1, 0)	
	}
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Base[id])
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_SGDRILL)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static iMaxClip; iMaxClip = (!g_iType[id]?CLIP:CLIP2)
	
	if(BPAmmo <= 0 || iClip >= iMaxClip)
		return HAM_SUPERCEDE
			
	g_Clip[id] = iClip
	return HAM_IGNORED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Base[id])
		return HAM_IGNORED	
	if(g_Clip[id] == -1)
		return HAM_IGNORED
		
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	Set_WeaponAnim(id, SGDRILL_RELOAD)
	Set_PlayerNextAttack(id, RELOAD_TIME)
	return HAM_IGNORED
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_SGDRILL || !g_Had_Base[Attacker])
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
			
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)

	new Float:fMul = !g_iType[Attacker]?1.0:float(g_iType[Attacker])
	SetHamParamFloat(3, float(DAMAGE) * fMul)
	
	return HAM_HANDLED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_SGDRILL || !g_Had_Base[Attacker])
		return HAM_IGNORED

	new Float:fMul = !g_iType[Attacker]?1.0:float(g_iType[Attacker])
	SetHamParamFloat(3, float(DAMAGE) * fMul)
	return HAM_HANDLED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!g_Had_Base[id])
		return HAM_IGNORED

	pev(id, pev_punchangle, g_Recoil[id])
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return
	if(!g_Had_Base[id])
		return

	static Float:Push[3]
	pev(id, pev_punchangle, Push)
	xs_vec_sub(Push, g_Recoil[id], Push)
	
	xs_vec_mul_scalar(Push, RECOIL, Push)
	xs_vec_add(Push, g_Recoil[id], Push)
	
	set_pev(id, pev_punchangle, Push)
	
	// Acc
	static Accena; Accena = ACCURACY
	if(Accena != -1)
	{
		static Float:Accuracy
		Accuracy = (float(100 - ACCURACY) * 1.5) / 100.0

		set_pdata_float(Ent, 62, Accuracy, 4);
	}
	
	Set_WeaponAnim(id, SGDRILL_SHOOT)
	emit_sound(id, CHAN_WEAPON, ShootSounds[0], VOL_NORM, ATTN_NORM, 0, random_num(95,120))
	
	set_pdata_int(Ent, 57, c_ShellCustom, 4)
	set_pdata_float(id, 111, get_gametime())
}

////////////////////////////
public Set_WpnList(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_Had_Base[id] ? (g_iType[id] == 2?"weapon_sgdrillgold":"weapon_sgdrill") : weapon_sgdrill)
	write_byte(5)
	write_byte(32)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(5)
	write_byte(CSW_SGDRILL)
	write_byte(0)
	message_end()
}
/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Safety_Killed_Post", 1)
}

public Safety_Connected(id)
{
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_CurWeapon(id)
{
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0

	return 1
}

public is_alive(id)
{
	if(!is_connected(id))
		return 0
	if(!Get_BitVar(g_IsAlive, id))
		return 0
		
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}

/* ===============================
--------- END OF SAFETY  ---------
=================================*/

stock Set_WeaponAnim(id, anim, iCheck=0)
{
	if(iCheck && pev(id, pev_weaponanim) == anim)
		return;

	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

stock Make_BulletSmoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock Set_WeaponIdleTime(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle, 4)
}

stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}
////////////
stock Stock_Drop_Slot(id, iSlot) 
{
	new weapons[32], num = 0
	get_user_weapons(id, weapons, num)
	
	for(new i = 0; i < num; i++)
	{
		new slot = Stock_Get_Wpn_Slot(weapons[i])

		if(iSlot == slot)
		{
			static wname[32]
			get_weaponname(weapons[i], wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock Stock_Get_Wpn_Slot(iWpn)
{
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

	if(PRIMARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 1
	else if(SECONDARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 2
	else if(iWpn == CSW_KNIFE) return 3
	else if(iWpn == CSW_HEGRENADE) return 4
	else if(iWpn == CSW_C4) return 5
	return 6 //FLASHBANG SMOKEBANG
}
/////////

/* ===============================
------------- DAMAGES ------------
=================================*/
stock KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1)
{
	new Float:vecOrigin[3], Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	pev(id, pev_origin, vecOrigin);

	new iHitResult = RESULT_HIT_NONE;
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
	
	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction < 1.0) iHitResult = RESULT_HIT_WORLD;
	
	new Float:vecEndZ = vecEnd[2];
	
	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0)
	{
		if (!pev_valid(pEntity))
			continue;
		if (id == pEntity)
			continue;
		if (!IsAlive(pEntity))
			continue;
		if (!CheckAngle(id, pEntity, fAngle))
			continue;
		if (!can_damage(id, pEntity))
			continue
		
		GetGunPosition(id, vecSrc);
		pev(pEntity, pev_origin, vecEnd);

		vecEnd[2] = vecSrc[2] + (vecEndZ - vecSrc[2]) * (get_distance_f(vecSrc, vecEnd) / flRange);

		xs_vec_sub(vecEnd, vecSrc, vecForward);
		xs_vec_normalize(vecForward, vecForward);
		xs_vec_mul_scalar(vecForward, flRange, vecForward);
		xs_vec_add(vecSrc, vecForward, vecEnd);

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction < 1.0)
		{
			if (IsPlayer(pEntity) || IsHostage(pEntity))
			{
				iHitResult = RESULT_HIT_PLAYER;
				
				if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
					flDamage *= 1.0;
			}

			if (pev_valid(pEntity) && get_tr2(tr, TR_pHit) == pEntity && !(pev(pEntity, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
			{
				engfunc(EngFunc_MakeVectors, v_angle);
				global_get(glb_v_forward, vecForward);

				if (iHitgroup != -1) set_tr2(tr, TR_iHitgroup, iHitgroup);

				ExecuteHamB(Ham_TraceAttack, pEntity, id, 20.0, vecForward, tr, DMG_NEVERGIB | DMG_CLUB);
				ExecuteHamB(Ham_TakeDamage, pEntity, id, id, flDamage, DMG_NEVERGIB | DMG_CLUB)
				
				Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			}
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock CheckAngle(iAttacker, iVictim, Float:fAngle)  return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))

stock GetGunPosition(id, Float:vecScr[3])
{
	new Float:vecViewOfs[3]
	pev(id, pev_origin, vecScr)
	pev(id, pev_view_ofs, vecViewOfs)
	xs_vec_add(vecScr, vecViewOfs, vecScr)
}

stock IsAlive(pEntity)
{
	if (pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}

stock IsPlayer(pEntity) return is_user_connected(pEntity)

stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}

stock CheckBack(iEnemy,id)
{
	new Float:anglea[3], Float:anglev[3]
	pev(iEnemy, pev_v_angle, anglea)
	pev(id, pev_v_angle, anglev)
	new Float:angle = anglea[1] - anglev[1] 
	if (angle < -180.0) angle += 360.0
	if (angle <= 45.0 && angle >= -45.0) return 1
	return 0
}

public Stock_Fake_KnockBack(id, iVic, Float:iKb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}

stock Float:Stock_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]
	pev(id, pev_origin, vId_ori)
	pev(iTarget, pev_origin, vTar_ori)
	
	pev(id,pev_angles,vId_ang)
	for(new i=0;i<2;i++) vOricross[i] = vTar_ori[i] - vId_ori[i]
	
	fLength = floatsqroot(vOricross[0]*vOricross[0] + vOricross[1]*vOricross[1])
	
	if (fLength<=0.0)
	{
		vOricross[0]=0.0
		vOricross[1]=0.0
	} else {
		vOricross[0]=vOricross[0]*(1.0/fLength)
		vOricross[1]=vOricross[1]*(1.0/fLength)
	}
	
	engfunc(EngFunc_MakeVectors,vId_ang)
	global_get(glb_v_forward,vForward)
	
	fRad = vOricross[0]*vForward[0]+vOricross[1]*vForward[1]
	return fRad   //->   RAD 90' = 0.5rad
}

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

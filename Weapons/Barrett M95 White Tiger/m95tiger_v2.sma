#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "Barrett M95 White Tiger"
#define VERSION "1.0"
#define AUTHOR "Asdian + Mellowzy"

// Data Config
#define P_M95TIGER "models/p_m95tiger.mdl"
#define V_M95TIGER "models/v_m95tiger.mdl"
#define W_M95TIGER "models/w_m95tiger.mdl"

#define MF_W "sprites/muzzleflash80.spr"
#define MODEL_W_OLD "models/w_ak47.mdl"

new const SOUND_FIRE[][] =
{
	"weapons/m95tiger-1.wav",
	"weapons/m95tiger-2.wav",
	"weapons/m95tiger-3.wav"
}

#define CSW_M95TIGER CSW_AK47
#define weapon_m95tiger "weapon_ak47"

#define WEAPON_CODE 11052018
#define WEAPON_EVENT "events/ak47.sc"

// Weapon Config
#define DAMAGE 220
#define ACCURACY -1 // 0 - 100 ; -1 Default
#define CLIP 20
#define BPAMMO 999
#define SPEED 1.83
#define RECOIL 0.75
#define RELOAD_TIME 2.03

#define DAMAGE_TIGER 220.0
#define RANGE_TIGER 80.0
#define AMMO_NET 7
#define HIT_COUNT 10

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_Base, g_Clip[33], g_OldWeapon[33], Float:g_Recoil[33][3], g_Attacking[33]
new g_Event_Base, g_SmokePuff_SprId, g_Dprd
new g_cachde_mf, Float:g_cache_frame_mf, g_cache_trail

new g_Shot_Mod[33], g_Aim_Mode[33], g_NetCount[33], g_test, g_HitCount[33], Float:g_fDelay[33]

// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

new const SpecialModels[][] =
{
	"models/ef_m95tiger_net.mdl",
	"models/ef_m95tiger_nethit.mdl",
	"models/ef_m95tiger.mdl"
}

// cache
new const TRACER_ENTITY[][] = { "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target" }
	
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
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_StartFrame, "fw_StartFrame")
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_m95tiger, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_m95tiger, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_m95tiger, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_m95tiger, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_m95tiger, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_m95tiger, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_m95tiger, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_Think, "env_sprite", "fw_MF_Think")
	RegisterHam(Ham_Think, "info_target", "HamF_InfoTarget_Think")
	RegisterHam(Ham_Touch, "info_target", "HamF_InfoTarget_Touch")
	
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack_World")
	
	// Cache
	register_clcmd("weapon_m95tiger", "hook_weapon")
	register_clcmd("weapon_m95tiger_2", "hook_weapon")
	
	g_Dprd = zp_register_extra_item(PLUGIN, 10, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR)
	g_test = CreateHudSyncObj()
}

public hook_weapon(id) engclient_cmd(id, weapon_m95tiger)

public plugin_precache()
{
	precache_model(P_M95TIGER)
	precache_model(V_M95TIGER)
	precache_model(W_M95TIGER)
	
	new i
	for(i = 0; i < sizeof(SOUND_FIRE); i++) precache_sound(SOUND_FIRE[i])
	
	precache_generic("sprites/weapon_m95tiger.txt")
	precache_generic("sprites/weapon_m95tiger_2.txt")
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	precache_model("models/grenade.mdl")
	for(i = 0; i < sizeof(SpecialModels); i++) precache_model(SpecialModels[i])
	
	g_cachde_mf = precache_model(MF_W)
	g_cache_frame_mf = float(engfunc(EngFunc_ModelFrames, g_cachde_mf))
	g_cache_trail = precache_model("sprites/laserbeam.spr")
	precache_model("sprites/ef_m95tiger_scratch.spr")
	
	precache_model("sprites/ef_m95tiger_eye1.spr")
	precache_model("sprites/ef_m95tiger_eye2.spr")
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "ak47"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_M95TIGER || !Get_BitVar(g_Had_Base, id))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "m95tiger")
	return PLUGIN_CONTINUE
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name)) g_Event_Base = get_orig_retval()		
}

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

public zp_extra_item_selected(i, d) if(d == g_Dprd) Get_Base(i)
public zp_user_infected_post(i) if(zp_get_user_zombie(i)) Remove_Base(i)
public zp_user_humanized_post(i) if(zp_get_user_survivor(i)) Remove_Base(i)

public Get_Base(id)
{
	Set_BitVar(g_Had_Base, id)
	
	Stock_Drop_Slot(id,1)
	fm_give_item(id, weapon_m95tiger)
	
	g_Aim_Mode[id] = 0
	g_HitCount[id] = 0
	g_NetCount[id] = AMMO_NET
	ShowStatusIcon(id, g_NetCount[id], 1)
	
	// Clip, Ammo, Deploy
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_M95TIGER)
	if(pev_valid(Ent)) 
	{
		cs_set_weapon_ammo(Ent, CLIP)
		ExecuteHamB(Ham_Item_Deploy, Ent)
	}
	cs_set_user_bpammo(id, CSW_M95TIGER, BPAMMO)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_M95TIGER)
	write_byte(CLIP)
	message_end()
}

public Remove_Base(id)
{
	UnSet_BitVar(g_Had_Base, id)
	g_Aim_Mode[id] = 0
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_M95TIGER && g_OldWeapon[id] != CSW_M95TIGER) && Get_BitVar(g_Had_Base, id))
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_M95TIGER && g_OldWeapon[id] == CSW_M95TIGER) && Get_BitVar(g_Had_Base, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_M95TIGER)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
	} else if(CSWID != CSW_M95TIGER && g_OldWeapon[id] == CSW_M95TIGER) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_M95TIGER)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_M95TIGER)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
		{
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW)
			//engfunc(EngFunc_SetModel, ent, P_M95TIGER)
		}
	} else {
		message_begin(MSG_ONE, get_user_msgid("HideWeapon"), {0,0,0}, id)
		write_byte(0)
		message_end()
	
		ShowStatusIcon(id, 0, 0)
		
		static ent, iFlame
		ent = fm_get_user_weapon_entity(id, CSW_M95TIGER)
		iFlame = find_ent_by_class(id, "despe_mf")
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 	
		if(pev_valid(iFlame) && pev(iFlame, pev_iuser1)) set_pev(iFlame, pev_effects, pev(iFlame, pev_effects) | EF_NODRAW)
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_M95TIGER && Get_BitVar(g_Had_Base, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_M95TIGER || !Get_BitVar(g_Had_Base, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event_Base)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	emit_sound(invoker, CHAN_WEAPON, SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, random_num(95,120))
	return FMRES_SUPERCEDE
}

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
		static weapon
		weapon = find_ent_by_owner(-1, weapon_m95tiger, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, W_M95TIGER)
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
	static id; id = get_pdata_cbase(Ent, 41, 4)
	
	if(get_pdata_cbase(id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_Base, id))
		return
	
	set_pev(id, pev_viewmodel2, V_M95TIGER)
	set_pev(id, pev_weaponmodel2, P_M95TIGER)
	
	Set_WeaponAnim(id, 3)
	Additonal_DeploySettings(Ent, id)
	
	Set_WpnList(id, 1)
	set_pdata_float(Ent, 46, 1.25, 4)
	set_pdata_float(Ent, 48, 1.25, 4)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_M95TIGER)
	write_byte(get_pdata_int(Ent, 51, 4))
	message_end()
}

public Additonal_DeploySettings(ent, id)
{
	static iFlame
	iFlame = find_ent_by_class(id, "despe_mf")
	
	if(pev_valid(iFlame) && pev(iFlame, pev_iuser1))
		set_pev(iFlame, pev_effects, pev(iFlame, pev_effects) &~ EF_NODRAW)
	
	g_Aim_Mode[id] = 0
	g_Shot_Mod[id] = 1
	
	set_pdata_int(id, 363, 89, 5)
	set_pev(ent, pev_iuser1, 0)
	
	ShowStatusIcon(id, g_NetCount[id], g_NetCount[id]?1:0)
	if(g_HitCount[id] >= HIT_COUNT) MakeMuzzleFlash(id, ent, 4, 2, "sprites/ef_m95tiger_eye2.spr", 0.01)
	else MakeMuzzleFlash(id, ent, 4, 1, "sprites/ef_m95tiger_eye1.spr", 0.01)
	
	message_begin(MSG_ONE, get_user_msgid("HideWeapon"), {0,0,0}, id)
	write_byte(g_Shot_Mod[id]?(1<<6):0)
	message_end()
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == WEAPON_CODE)
	{
		Set_BitVar(g_Had_Base, id)
		set_pev(Ent, pev_impulse, 0)
	}
	
	return HAM_IGNORED	
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_M95TIGER)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_M95TIGER, bpammo - temp1)		
		
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
		
		if(pev(ent, pev_iuser1)) cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 1)
	}		
	
	WE_M95TIGER(id, ent, iClip,bpammo,pev(id, pev_button))
	return HAM_IGNORED
}

public WE_M95TIGER(id,iEnt,iClip, bpammo,iButton)
{
	new iFov = cs_get_user_zoom(id)
	new Float:fTimer; pev(iEnt, pev_fuser1, fTimer)
	new Float:fTimer2; pev(iEnt, pev_fuser2, fTimer2)
	new iSave = pev(iEnt, pev_iuser1)
	
	if(!(iButton & IN_ATTACK) && fTimer2 < get_gametime() && iSave && g_Aim_Mode[id] == 2)
	{
		if(iSave) client_cmd(id, "spk weapons/zoom.wav")
		cs_set_user_zoom(id, iSave, 1)
		g_Aim_Mode[id] = 1
	}
	
	if(iSave && g_Aim_Mode[id] == 1 && g_HitCount[id] >= HIT_COUNT)
	{
		set_hudmessage(240, 240, 0, -1.0, -1.0, 0, 0.1, 0.1)
		ShowSyncHudMsg(id, g_test, "||||| + |||||")
	}
	
	if((iButton & IN_ATTACK) && (iButton & IN_ATTACK2) && g_HitCount[id] >= HIT_COUNT) // hold LMB and RMB while trigger to summon tiger
	{
		Shoot_Net(id, 1)
		g_HitCount[id] = 0
		
		remove_entity_name("despe_mf")
		MakeMuzzleFlash(id, iEnt, 4, 1, "sprites/ef_m95tiger_eye1.spr", 0.01)
	}
	
	if((iButton & IN_ATTACK2) && fTimer < get_gametime())
	{
		if(iFov == CS_SET_FIRST_ZOOM) 
		{
			set_pdata_int(id, 363, 89, 5)
			Set_WpnList(id, 1)
			
			g_Aim_Mode[id] = 0
			g_Shot_Mod[id] = 1
			set_pev(iEnt, pev_iuser1, 0)
		} else {
			Set_WpnList(id, 0)
			cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 1)
			
			g_Shot_Mod[id] = 0
			set_pev(iEnt, pev_iuser1, CS_SET_FIRST_ZOOM)
		}
		message_begin(MSG_ONE, get_user_msgid("HideWeapon"), {0,0,0}, id)
		write_byte(g_Shot_Mod[id]?(1<<6):0)
		message_end()
		
		g_Aim_Mode[id] = 1
		client_cmd(id, "spk weapons/zoom.wav")
		set_pev(iEnt, pev_fuser1, get_gametime() + 0.3)
	}
	
	if(iButton & IN_ATTACK)
	{
		if(g_Shot_Mod[id] && g_NetCount[id] && g_fDelay[id] < get_gametime())
		{
			Shoot_Net(id, 0)
			Set_WeaponAnim(id, 5)
			MakeMuzzleFlash(id, iEnt, 3, 0, MF_W, 0.045)
			
			set_pdata_int(id, 363, 89, 5)
			emit_sound(id, CHAN_WEAPON, SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			
			g_NetCount[id]--
			ShowStatusIcon(id, g_NetCount[id], (g_NetCount[id] > 0))
			
			g_fDelay[id] = get_gametime() + 1.87
			set_pdata_float(iEnt, 48, 2.0, 4)
		}
		
		if(!g_Shot_Mod[id] && g_Aim_Mode[id])
		{
			if(get_pdata_float(iEnt, 46, 4) > 0.0 || !iClip)
				return
			
			Set_WpnList(id, 0)
			g_Aim_Mode[id] = 2
			set_pev(iEnt, pev_fuser1, get_gametime() + 2.0)
			set_pev(iEnt, pev_fuser2, get_gametime() + 2.0)
			
			MakeMuzzleFlash(id, iEnt, 1, 0, MF_W, 0.045)
			ExecuteHamB(Ham_Weapon_PrimaryAttack, iEnt)
			Additional_Settings(id, iEnt)
		}
	}
	
	iButton &= ~IN_ATTACK
	set_pev(id, pev_button, iButton &~ IN_ATTACK)
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_M95TIGER)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0 || iClip >= CLIP)
		return HAM_SUPERCEDE
			
	g_Clip[id] = iClip
	return HAM_IGNORED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	if(g_Clip[id] == -1)
		return HAM_IGNORED
		
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	Set_WeaponAnim(id, 2)
	Set_PlayerNextAttack(id, RELOAD_TIME)
	
	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	return HAM_IGNORED
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_M95TIGER || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
			
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)

	SetHamParamFloat(3, float(DAMAGE))
	
	static Wpn; Wpn = get_pdata_cbase(Attacker, 373)
	if(pev_valid(Wpn)) set_pev(Wpn, pev_vuser1, flEnd);
	return HAM_IGNORED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_M95TIGER || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED

	SetHamParamFloat(3, float(DAMAGE))
	
	if(is_user_alive(Victim) && can_damage(Victim, Attacker) && g_Attacking[Attacker] && g_HitCount[Attacker] < HIT_COUNT)
	{
		g_HitCount[Attacker]++
		
		static Wpn; Wpn = get_pdata_cbase(Attacker, 373)
		if(pev_valid(Wpn) && g_HitCount[Attacker] >= HIT_COUNT) 
		{
			remove_entity_name("despe_mf")
			MakeMuzzleFlash(Attacker, Wpn, 4, 2, "sprites/ef_m95tiger_eye2.spr", 0.01)
		}
	}
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED
	if(g_Shot_Mod[id])
		return HAM_HANDLED
	
	g_Attacking[id] = 1
	pev(id, pev_punchangle, g_Recoil[id])
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED
	if(g_Shot_Mod[id])
		return HAM_HANDLED
	
	g_Attacking[id] = 0
	
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
	return HAM_IGNORED
}

public Additional_Settings(id, ent)
{
	set_pdata_int(id, 363, 90, 5)
	set_pdata_float(ent, 46, SPEED, 4)
	
	Set_WeaponAnim(id, 1)
	
	message_begin(MSG_ONE, get_user_msgid("HideWeapon"), {0,0,0}, id)
	write_byte(0)
	message_end()
	
	// csbtedhan + kord12.7
	new Float:originF[3], Float:aimoriginF[3]
	pev(ent, pev_vuser1, aimoriginF)
	Stock_Get_Postion(id, 40.0, get_cvar_num("cl_righthand")?7.5:-7.5, -5.0, originF)
	
	for(new i = 0; i < min(floatround(vector_distance(originF, aimoriginF)*0.1), 10) ; i++)
	{
		new iBeam = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "beam"))
		set_pev(iBeam, pev_classname, "beam");
		set_pev(iBeam, pev_flags, pev(iBeam, pev_flags) | FL_CUSTOMENTITY);
		set_pev(iBeam, pev_rendercolor, Float:{240.0, 240.0, 0.0})
		set_pev(iBeam, pev_renderamt, 255.0)
		set_pev(iBeam, pev_body, 0)
		set_pev(iBeam, pev_frame, 0.0)
		set_pev(iBeam, pev_animtime, 0.0)
		set_pev(iBeam, pev_model, "sprites/laserbeam.spr");
		set_pev(iBeam, pev_modelindex, g_cache_trail)
		set_pev(iBeam, pev_scale, 20.0)
		
		set_pev(iBeam, pev_rendermode, (pev(iBeam, pev_rendermode) & 0x0F) | 0x40 & 0xF0)
		set_pev(iBeam, pev_origin, originF)
		set_pev(iBeam, pev_angles, aimoriginF)
		set_pev(iBeam, pev_sequence, (pev(iBeam, pev_sequence) & 0x0FFF) | ((0 & 0xF) << 12))
		set_pev(iBeam, pev_skin, (pev(iBeam, pev_skin) & 0x0FFF) | ((0 & 0xF) << 12))
		Beam_RelinkBeam(iBeam);
		
		set_pev(iBeam, pev_dmgtime, get_gametime()+0.4)
		set_pev(iBeam, pev_fuser1, 0.8)
		set_pev(iBeam, pev_iuser1, 2018)
	}
}

/* =========================================
---------- Entities and Specials -----------
========================================= */
public fw_StartFrame() // csbtedhan
{
	new iEnt = -1
	while((iEnt = find_ent_by_class(iEnt, "beam")) > 0)
	{
		if(!is_valid_ent(iEnt) || pev(iEnt, pev_iuser1) != 2018)
			continue;
		
		new Float:dmgtime, Float:color[3], Float:stay
		pev(iEnt,pev_dmgtime, dmgtime)
		pev(iEnt,pev_fuser1, stay)
		pev(iEnt,pev_rendercolor, color)
		
		if(dmgtime - get_gametime() < stay)
		{
			color[0] = floatmax(0.0, color[0] - 16.0)
			color[1] = floatmax(0.0, color[1] - 16.0)
			color[2] = floatmax(0.0, color[2] - 16.0)
			set_pev(iEnt,pev_rendercolor, color)
		}
		
		if(dmgtime <= get_gametime())
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
	}
}

public Shoot_Net(id, IsTiger)
{
	new Float:vOrigin[3], Float:vAngles[3], Float:vVec[3],Float:vAngle[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vAngle)
	xs_vec_mul_scalar(vAngle, IsTiger?750.0:2000.0, vVec)
	
	static iNet
	iNet = Stock_CreateEntityBase(id, "info_target", MOVETYPE_NOCLIP, SpecialModels[IsTiger?2:0], "m95tiger_ent", SOLID_TRIGGER, 0.05)
	if(IsTiger) engfunc(EngFunc_SetSize, iNet, Float:{-50.0, -50.0, 0.0}, Float:{50.0, 50.0, 50.0})
	else engfunc(EngFunc_SetSize, iNet, Float:{-31.0, -31.0, 0.0}, Float:{31.0, 31.0, 31.0})
	
	set_pev(iNet, pev_origin, vOrigin)
	set_pev(iNet, pev_rendermode, kRenderTransAdd)
	set_pev(iNet, pev_renderamt, 255.0)
	set_pev(iNet, pev_light_level, 180.0)
	set_pev(iNet, pev_gravity, 0.01)
	set_pev(iNet, pev_animtime, get_gametime())
	set_pev(iNet, pev_frame, 0.0)
	set_pev(iNet, pev_framerate, 1.0)
	set_pev(iNet, pev_sequence, 0)
	set_pev(iNet, pev_iuser1, IsTiger?2:0)
	set_pev(iNet, pev_velocity, vVec)
	
	static Float:vVelocity[3]
	pev(iNet, pev_velocity, vVelocity)
	vector_to_angle(vVelocity, vAngles)
	if(vAngles[0] > 90.0) vAngles[0] = -(360.0 - vAngles[0])
	set_pev(iNet, pev_angles, vAngles)
	
	if(IsTiger) set_pev(iNet, pev_ltime, get_gametime() + 120.0)
	else set_pev(iNet, pev_ltime, get_gametime() + 2.0)
	
	if(IsTiger) client_cmd(id, "spk %s", SOUND_FIRE[2])
}

public Shoot_Tiger(id)
{
	new Float:vOrigin[3], Float:vAngles[3], Float:vVec[3],Float:vAngle[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vAngle)
	xs_vec_mul_scalar(vAngle, 750.0, vVec)
	
	static iNet
	iNet = Stock_CreateEntityBase(id, "info_target", MOVETYPE_NOCLIP, SpecialModels[2], "m95tiger_ent", SOLID_TRIGGER, 0.05)
	engfunc(EngFunc_SetSize, iNet, Float:{-50.0, -50.0, 0.0}, Float:{50.0, 50.0, 50.0})
	set_pev(iNet, pev_origin, vOrigin)
	set_pev(iNet, pev_rendermode, kRenderTransAdd)
	set_pev(iNet, pev_renderamt, 255.0)
	set_pev(iNet, pev_light_level, 180.0)
	set_pev(iNet, pev_gravity, 0.01)
	set_pev(iNet, pev_animtime, get_gametime())
	set_pev(iNet, pev_frame, 0.0)
	set_pev(iNet, pev_framerate, 1.0)
	set_pev(iNet, pev_sequence, 0)
	set_pev(iNet, pev_iuser1, 2)
	set_pev(iNet, pev_velocity, vVec)
	
	static Float:vVelocity[3]
	pev(iNet, pev_velocity, vVelocity)
	vector_to_angle(vVelocity, vAngles)
	if(vAngles[0] > 90.0) vAngles[0] = -(360.0 - vAngles[0])
	set_pev(iNet, pev_angles, vAngles)
	
	set_pev(iNet, pev_ltime, get_gametime() + 120.0)
	client_cmd(id, "spk %s", SOUND_FIRE[2])
}

public HamF_InfoTarget_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "m95tiger_ent"))
		return
		
	new iEntID,iVic,iOwner
	iEntID = pev(iEnt, pev_iuser1)
	iVic = pev(iEnt, pev_enemy)
	iOwner = pev(iEnt, pev_owner)
	
	if(!iEntID)
	{
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		
		static Float:fTimeRemove, Float:fFrame
		pev(iEnt, pev_ltime, fTimeRemove)
		pev(iEnt, pev_frame, fFrame)
		
		fFrame += 3.5
		set_pev(iEnt, pev_frame, fFrame)
		
		if(get_gametime() >= fTimeRemove - 0.6)
		{
			static Float:fValue
			pev(iEnt, pev_renderamt, fValue)
			
			fValue = floatmax(fValue - 15.0, 0.0)
			set_pev(iEnt, pev_renderamt, fValue)
		}
		
		if(entity_range(iEnt, iOwner) > 750.0 || get_gametime() >= fTimeRemove)
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
	} else if(iEntID == 1 || iEntID == 2)
	{
		if(iEntID == 1 && (!pev_valid(iVic) || !is_user_alive(iVic) || !is_user_connected(iVic)))
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return
		}
		
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		
		static Float:fTimeRemove, Float:fFrame
		pev(iEnt, pev_ltime, fTimeRemove)
		pev(iEnt, pev_frame, fFrame)
		
		if(fFrame > 90.0) fFrame = 0.0
		fFrame += 2.5
		set_pev(iEnt, pev_frame, fFrame)
		
		if(iEntID == 1)
		{
			static Float:vOrig[3]
			pev(iVic, pev_origin, vOrig)
			set_pev(iEnt, pev_origin, vOrig)
			
			if (pev(iVic, pev_flags) & FL_ONGROUND)
				fm_set_user_gravity(iVic, 999999.9) // set really high
			else
				fm_set_user_gravity(iVic, 0.000001) // no gravity
		}
		
		if(get_gametime() >= fTimeRemove - 0.6)
		{
			static Float:fValue
			pev(iEnt, pev_renderamt, fValue)
			fValue = floatmax(fValue - 15.0, 0.0)
			set_pev(iEnt, pev_renderamt, fValue)
		}
		
		if(get_gametime() >= fTimeRemove) 
		{
			if(iEntID == 1)
			{
				static Float:fGrav
				pev(iEnt, pev_fuser1, fGrav)
				
				fm_set_user_gravity(iVic, fGrav)
				set_pev(iVic, pev_maxspeed, 320.0)
			}
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		}
	} else if(iEntID == 3) {
		static Float:fTimeRemove, Float:fRenderMount
		pev(iEnt, pev_ltime, fTimeRemove)
		pev(iEnt, pev_renderamt, fRenderMount)
		
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		
		if(get_gametime() >= fTimeRemove) 
		{
			fRenderMount -= 5.0
			set_pev(iEnt,pev_renderamt,fRenderMount)
			
			if(fRenderMount<=0.0)
			{
				set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
				return
			}
		}
	}
}

public HamF_InfoTarget_Touch(iEnt, iPtd)
{
	if(!pev_valid(iEnt))
		return HAM_IGNORED
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "m95tiger_ent"))
		return HAM_IGNORED
		
	new iEntID, iOwner
	iOwner = pev(iEnt, pev_owner)
	iEntID = pev(iEnt, pev_iuser1)
	
	new Float:vecOri[3]
	pev(iEnt, pev_origin, vecOri)
	
	if(!iEntID)
	{
		if(!pev_valid(iPtd) || iPtd == iOwner)
			return HAM_IGNORED
		
		new pEntity = -1;
		while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOri, 256.0)) != 0)
		{
			if (!pev_valid(pEntity))
				continue;
			if (iOwner == pEntity)
				continue;
			if (!is_user_connected(pEntity))
				continue;
			if (entity_range(iEnt, pEntity) > 80.0)
				continue
		
			new Float:vOrigin[3]
			pev(pEntity, pev_origin, vOrigin)
			
			new iTrap = Stock_CreateEntityBase(iOwner, "info_target", MOVETYPE_NONE, "", "m95tiger_ent", SOLID_NOT, 0.05)
			set_pev(iTrap, pev_origin, vOrigin)
			engfunc(EngFunc_SetModel, iTrap, SpecialModels[1]) // dont know why
			set_pev(iTrap, pev_sequence, 0)
			set_pev(iTrap, pev_iuser1, 1)
			set_pev(iTrap, pev_animtime, get_gametime())
			set_pev(iTrap, pev_framerate, 1.0)
			set_pev(iTrap, pev_rendermode, kRenderTransAdd)
			set_pev(iTrap, pev_renderamt, 255.0)
			set_pev(iTrap, pev_light_level, 180.0)
			set_pev(iTrap, pev_ltime, get_gametime() + 1.7)
			set_pev(iTrap, pev_enemy, pEntity)
			set_pev(iTrap, pev_fuser1, fm_get_user_gravity(pEntity))
			
			set_pev(pEntity, pev_maxspeed, 0.0)
		}
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
	} else if(iEntID == 2) {
		if(iPtd == iOwner)
			return HAM_IGNORED
		
		new pEntity = -1;
		while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOri, RANGE_TIGER)) != 0)
		{
			if (!pev_valid(pEntity))
				continue;
			if (iOwner == pEntity)
				continue;
			if (!is_user_connected(pEntity))
				continue;
			if (!CheckAngle(iOwner, pEntity, RANGE_TIGER))
				continue
			
			new Float:vOrigin[3],Float:Origin[3]
			pev(iEnt, pev_origin, vOrigin)
			pev(pEntity, pev_origin, Origin)
			
			Stock_RadiusDamage(vOrigin, iEnt, iOwner, DAMAGE_TIGER, RANGE_TIGER, 1.0, DMG_PARALYZE)
			
			new iTrap = Stock_CreateEntityBase(iOwner, "info_target", MOVETYPE_FOLLOW, "sprites/ef_m95tiger_scratch.spr", "m95tiger_ent", SOLID_NOT, 0.05)
			set_pev(iTrap, pev_origin, Origin)
			set_pev(iTrap, pev_iuser1, 3)
			set_pev(iTrap, pev_scale, 0.5)
			set_pev(iTrap, pev_aiment, pEntity)
			set_pev(iTrap, pev_rendermode, kRenderTransAdd)
			set_pev(iTrap, pev_renderamt, 100.0)
			set_pev(iTrap, pev_ltime, get_gametime() + 3.25)
		}
	}
	return HAM_IGNORED
}

public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "despe_mf"))
	{
		static Float:fFrame, Float:fFrameMax,iWpn,iBody
		pev(ent, pev_frame, fFrame)
		iWpn = pev(ent, pev_iuser4)
		iBody = pev(ent, pev_iuser1)
		
		if(!pev_valid(iWpn))
			return
		
		if(!iBody)
		{
			fFrameMax = g_cache_frame_mf
			
			fFrame += 1.0
			set_pev(ent, pev_frame, fFrame)
			
			if(fFrame >= fFrameMax || !iWpn)
			{
				set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
				return
			}
			set_pev(ent, pev_nextthink, get_gametime() + 0.045)
		} else {
			fFrameMax = float(engfunc(EngFunc_ModelFrames, pev(ent, pev_modelindex)))
			
			fFrame += 1.0
			set_pev(ent, pev_frame, fFrame)
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.01)
			
			if(fFrame >= fFrameMax)
			{
				set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
				return
			}
		}
		return
	}
}

public MakeMuzzleFlash(id, iEnt, body, typ, mdl[], Float:fNext)
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, mdl, "despe_mf", SOLID_NOT,fNext)
	set_pev(iMuz, pev_body, body)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.07)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
	
	if(typ)
	{
		set_pev(iMuz, pev_framerate, 1.0)
		set_pev(iMuz, pev_modelindex, engfunc(EngFunc_ModelIndex, mdl))
	}
	
	set_pev(iMuz, pev_iuser1, typ)
	set_pev(iMuz, pev_iuser4, iEnt)
	set_pev(iMuz, pev_owner, id)
	dllfunc(DLLFunc_Spawn, iMuz)
}

////////////// Entities /////////////////////////////////////
stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}

stock Beam_RelinkBeam(const iBeamEntity)
{
	new Float:flOrigin[3],Float:flStartPos[3],Float:flEndPos[3];
	new Float:flMins[3],Float:flMaxs[3];
	
	pev(iBeamEntity, pev_origin, flOrigin);
	pev(iBeamEntity, pev_origin, flStartPos);
	pev(iBeamEntity, pev_angles, flEndPos);
	
	flMins[0] = floatmin(flStartPos[0], flEndPos[0]);
	flMins[1] = floatmin(flStartPos[1], flEndPos[1]);
	flMins[2] = floatmin(flStartPos[2], flEndPos[2]);
	
	flMaxs[0] = floatmax(flStartPos[0], flEndPos[0]);
	flMaxs[1] = floatmax(flStartPos[1], flEndPos[1]);
	flMaxs[2] = floatmax(flStartPos[2], flEndPos[2]);
	
	xs_vec_sub(flMins, flOrigin, flMins);
	xs_vec_sub(flMaxs, flOrigin, flMaxs);
	
	set_pev(iBeamEntity, pev_mins, flMins);
	set_pev(iBeamEntity, pev_maxs, flMaxs);
	
	engfunc(EngFunc_SetSize, iBeamEntity, flMins, flMaxs);
	engfunc(EngFunc_SetOrigin, iBeamEntity, flOrigin);
}

stock Stock_Get_Aiming(id, Float:end[3])
{
	new Float:start[3], Float:view_ofs[3]
	pev(id, pev_origin, start)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)

	pev(id, pev_v_angle, end)
	engfunc(EngFunc_MakeVectors, end)
	global_get(glb_v_forward, end)
	xs_vec_mul_scalar(end, 8192.0, end)
	xs_vec_add(start, end, end)
	new ptr = create_tr2();
	engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, id, ptr)
	get_tr2(ptr, TR_vecEndPos, end)
	free_tr2(ptr)
}
stock Stock_Get_Postion(id,Float:forw,Float:right, Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
} 
stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

stock CheckAngle(iAttacker, iVictim, Float:fAngle)  return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))
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

stock Stock_RadiusDamage(Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage, Float:flRadius, Float:fKnockBack, bitsDamageType, bool:bSkipAttacker=true, bool:bCheckTeam=false)
{
	new pEntity = -1, tr = create_tr2(), Float:flAdjustedDamage, Float:falloff

	falloff = flDamage / flRadius
	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER)
	vecSrc[2] += 1.0
	if(!pevAttacker) pevAttacker = pevInflictor
	
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if(pev(pEntity, pev_takedamage) == DAMAGE_NO)
			continue
		if(bInWater && !pev(pEntity, pev_waterlevel))
			continue
		if(!bInWater && pev(pEntity, pev_waterlevel) == 3)
			continue
		if(bCheckTeam && is_user_connected(pEntity) && pEntity != pevAttacker)
			if(!can_damage(pEntity, pevAttacker))
				continue
		if(bSkipAttacker && pEntity == pevAttacker)
			continue
		
		new Float:vecEnd[3]
		pev(pEntity, pev_origin, vecEnd)

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, 0, tr)

		new Float:flFraction
		get_tr2(tr, TR_flFraction, flFraction)

		if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, 0, tr)
		
		if(pev_valid(pEntity))
		{
			pev(pEntity, pev_origin, vecEnd)
			xs_vec_sub(vecEnd, vecSrc, vecEnd)

			new Float:fDistance = xs_vec_len(vecEnd)
			if(fDistance < 1.0) fDistance = 0.0

			flAdjustedDamage = fDistance * falloff
			
			if(get_tr2(tr, TR_pHit) != pEntity) flAdjustedDamage *= 0.3

			if(flAdjustedDamage <= 0)
				continue

			ExecuteHamB(Ham_TraceAttack, pEntity, pevAttacker, flAdjustedDamage, vecEnd, tr, bitsDamageType)
			ExecuteHamB(Ham_TakeDamage, pEntity, pevAttacker, pevAttacker, flAdjustedDamage, bitsDamageType);
			Stock_Fake_KnockBack(pevAttacker, pEntity, fKnockBack)
		}
	}
	free_tr2(tr)
}
stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
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

////////////////////////////
public Set_WpnList(id, iSet)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	if(iSet) write_string(Get_BitVar(g_Had_Base, id) ? "weapon_m95tiger" : weapon_m95tiger)
	else write_string(Get_BitVar(g_Had_Base, id) ? "weapon_m95tiger_2" : weapon_m95tiger)
	write_byte(2)
	write_byte(90)
	write_byte(15)
	write_byte(7)
	write_byte(0)
	write_byte(1)
	write_byte(CSW_M95TIGER)
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
stock ShowStatusIcon(id, idspr, On)
{	
	#pragma unused On
	//for (new i = 1; i <= 9; i++) StatusIcon(id, i, 0)
	//if(idspr) StatusIcon(id, idspr, On)
	
	set_pdata_int(id, 376 + 15, idspr, 5)
}
stock StatusIcon(id, idspr, On)
{	
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", idspr)
  	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red
	write_byte(212) // green
	write_byte(255) // blue
	message_end()

}
stock Stock_Drop_Slot(id,iSlot)
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++)
	{
		new slot = Stock_Get_Wpn_Slot(weapons[i]);
		if (iSlot == slot)
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
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
	else if(iWpn==CSW_KNIFE) return 3
	else if(iWpn == CSW_HEGRENADE) return 4
	else if(iWpn == CSW_C4) return 5
	return 6 //FLASHBANG SMOKEBANG
}

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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "AMXX Desperado"
#define VERSION "1.0"
#define AUTHOR "Asdian + EDo"

// Data Config
#define P_DESPERADO_M "models/p_desperado_m.mdl"
#define P_DESPERADO_W "models/p_desperado_w.mdl"
#define V_DESPERADO "models/v_desperado.mdl"
#define W_DESPERADO "models/w_desperado.mdl"

#define MF_W "sprites/muzzleflash59.spr"
#define MF_M "sprites/muzzleflash60.spr"

#define MODEL_W_OLD "models/w_deagle.mdl"
#define SOUND_FIRE "weapons/dprd-1.wav"

#define CSW_DESPERADO CSW_DEAGLE
#define weapon_desperado "weapon_deagle"

#define WEAPON_CODE 1182015
#define WEAPON_EVENT "events/deagle.sc"

enum _:NewAnim
{
	DESPERADO_IDLE_M = 0,
	DESPERADO_RUN_START_M,
	DESPERADO_RUN_IDLE_M,
	DESPERADO_RUN_END_M,
	DESPERADO_DRAW_M,
	DESPERADO_SHOOT_M,
	DESPERADO_RELOAD_M,
	DESPERADO_SWAB_M,
	DESPERADO_IDLE_W,
	DESPERADO_RUN_START_W,
	DESPERADO_RUN_IDLE_W,
	DESPERADO_RUN_END_W,
	DESPERADO_DRAW_W,
	DESPERADO_SHOOT_W,
	DESPERADO_RELOAD_W,
	DESPERADO_SWAB_W
}

// Weapon Config
#define DAMAGE 70
#define ACCURACY 23 // 0 - 100 ; -1 Default
#define CLIP 7
#define BPAMMO 999
#define SPEED 0.1
#define RECOIL 0.5
#define RELOAD_TIME 0.7

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_Base, g_Clip[33], g_OldWeapon[33], Float:g_Recoil[33][3]
new g_Event_Base, g_SmokePuff_SprId, g_Dprd
new g_cachde_mf[2], Float:g_cache_frame_mf[2]
	
// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

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
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_desperado, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_desperado, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_desperado, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_desperado, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_desperado, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_desperado, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_desperado, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_desperado, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_Think, "env_sprite", "fw_MF_Think")
	
	// Cache
	register_clcmd("weapon_desperado", "hook_weapon")
	g_Dprd = zp_register_extra_item("Python Desperado", 10, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR)
}

public hook_weapon(id) engclient_cmd(id, weapon_desperado)

public plugin_precache()
{
	precache_model(P_DESPERADO_M)
	precache_model(P_DESPERADO_W)
	precache_model(V_DESPERADO)
	precache_model(W_DESPERADO)
	precache_sound(SOUND_FIRE)
	
	precache_generic("sprites/weapon_desperado.txt")
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_cachde_mf[0] = precache_model(MF_M)
	g_cachde_mf[1] = precache_model(MF_W)
	
	g_cache_frame_mf[0] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[0]))
	g_cache_frame_mf[1] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[1]))
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "deagle"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_DESPERADO || !Get_BitVar(g_Had_Base, id))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "desperado")
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
	
	Stock_Drop_Slot(id,2)
	fm_give_item(id, weapon_desperado)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DESPERADO)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_DESPERADO, BPAMMO)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_DESPERADO)
	write_byte(CLIP)
	message_end()
}

public Remove_Base(id)
{
	UnSet_BitVar(g_Had_Base, id)
}

stock Stock_Drop_Slot(id,iSlot)
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++)
	{
		const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
		
		if (iSlot == 2 && SECONDARY_WEAPONS_BIT_SUM & (1<<weapons[i]))
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_DESPERADO && g_OldWeapon[id] != CSW_DESPERADO) && Get_BitVar(g_Had_Base, id))
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_DESPERADO && g_OldWeapon[id] == CSW_DESPERADO) && Get_BitVar(g_Had_Base, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DESPERADO)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
		//set_pdata_float(Ent, 46, SPEED, 4)
		//set_pdata_float(Ent, 47, SPEED, 4)
	} else if(CSWID != CSW_DESPERADO && g_OldWeapon[id] == CSW_DESPERADO) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_DESPERADO)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_DESPERADO)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
		{
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
			
			
			new iState = pev(ent, pev_iuser3)
			engfunc(EngFunc_SetModel, ent, iState ? P_DESPERADO_W : P_DESPERADO_M)
		}
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_DESPERADO)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_DESPERADO && Get_BitVar(g_Had_Base, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_DESPERADO || !Get_BitVar(g_Had_Base, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event_Base)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	emit_sound(invoker, CHAN_WEAPON, SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
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
		static weapon; weapon = find_ent_by_owner(-1, weapon_desperado, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, W_DESPERADO)

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
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_Base, Id))
		return
	
	new iState = pev(Ent, pev_iuser3)
	
	set_pev(Id, pev_viewmodel2, V_DESPERADO)
	set_pev(Id, pev_weaponmodel2, iState ? P_DESPERADO_W: P_DESPERADO_M)
	set_pev(Ent, pev_iuser2, 0);
	Set_WeaponAnim(Id, iState ? DESPERADO_DRAW_W : DESPERADO_DRAW_M)
	
	Set_WpnList(Id)
	
	static iClip; iClip = get_pdata_int(Ent, 51, 4)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, Id)
	write_byte(1)
	write_byte(CSW_DESPERADO)
	write_byte(iClip)
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
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_DESPERADO)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_DESPERADO, bpammo - temp1)		
		
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
	}		
	
	WE_Desperado(id, ent, iClip,bpammo,pev(id, pev_button))
	return HAM_IGNORED
}

public WE_Desperado(id,iEnt,iClip, bpammo,iButton)
{
	new iState = pev(iEnt, pev_iuser3)
	new iChange = pev(iEnt, pev_iuser1)
	
	if(iChange && get_pdata_float(id, 83) <= 0.0)
	{
		iState = 1 - iState
		set_pev(iEnt, pev_iuser3, iState)
			
		set_pev(id, pev_weaponmodel2, iState ? P_DESPERADO_W : P_DESPERADO_M)
		Set_WeaponAnim(id, iState ? DESPERADO_IDLE_W:0)
		
		//set_pdata_int(iEnt, 54, 1, 4)
		//set_pdata_float(id, 83, 0.01, 5)
		
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(iEnt, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_DESPERADO, bpammo - temp1)
		
		set_pev(iEnt, pev_iuser1, 0)
		set_pev(iEnt, pev_iuser2, 0)
	}

	new Float:fNext = (iClip ? SPEED : 0.6)
	
	if ((iButton & IN_ATTACK) && !iChange)
	{
		if (iState)
		{
			set_pev(iEnt, pev_iuser2, 0)
			Set_WeaponAnim(id, 15)
			
			set_pdata_float(id, 83, 0.1, 5)
			set_pdata_float(iEnt, 46, 0.1, 4)
			set_pdata_float(iEnt, 48, 0.2, 4)

			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_fuser1, get_gametime() + get_pdata_float(id, 83))
		} else {
			set_pdata_float(iEnt, 46, 0.0, 4)
			set_pev(iEnt, pev_iuser2, 0)

			if(get_pdata_float(iEnt, 46, 4) > 0.0)
				return

			if(iClip) 
			{
				ExecuteHamB(Ham_Weapon_PrimaryAttack, iEnt)
				MakeMuzzleFlash(id, iEnt)
				Set_WeaponAnim(id, DESPERADO_SHOOT_M)
	
			} else {
				set_pdata_float(iEnt, 46, fNext, 4);
				return;
			}
			set_pdata_float(id, 83, fNext, 5)
			set_pdata_float(iEnt, 46, fNext, 4)
			set_pdata_float(iEnt, 48, fNext, 4)
		}
	}
	
	if ((iButton & IN_ATTACK2) && !iChange)
	{
		if (!iState)
		{
			set_pev(iEnt, pev_iuser2, 0)
			Set_WeaponAnim(id, 7)
			
			set_pdata_float(id, 83, 0.1, 5)
			set_pdata_float(iEnt, 46, 0.1, 4)
			set_pdata_float(iEnt, 48, 0.2, 4)
			
			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_fuser1, get_gametime() + get_pdata_float(id, 83))
		} else {
			set_pdata_float(iEnt, 46, 0.0, 4)
			set_pev(iEnt, pev_iuser2, 0)
			
			if(get_pdata_float(iEnt, 46, 4) > 0.0)
				return

			if(iClip) 
			{
				ExecuteHamB(Ham_Weapon_PrimaryAttack, iEnt)
				MakeMuzzleFlash(id, iEnt)
				Set_WeaponAnim(id, DESPERADO_SHOOT_W)
			} else {
				set_pdata_float(iEnt, 46, fNext, 4)
				return;
			}

			set_pdata_float(id, 83, fNext, 5)
			set_pdata_float(iEnt, 46, fNext, 4)
			set_pdata_float(iEnt, 48, fNext, 4)
		}
	}
	
	if (iButton & IN_ATTACK || iButton & IN_ATTACK2 || !iClip)
		return
			
	new iFastRun, Float:fDelayBlock, Float:fDelayAnim
	pev(iEnt, pev_fuser1, fDelayBlock)
	pev(iEnt, pev_fuser2, fDelayAnim)
	iFastRun = pev(iEnt, pev_iuser2)

	if (fDelayBlock >= get_gametime() && fDelayBlock)
		return
	
	if(iButton & IN_FORWARD)
	{
		if (!iFastRun)
		{
			set_pev(iEnt, pev_iuser2, 1)
			set_pev(iEnt, pev_fuser2, get_gametime() + 0.1)
		}
	} else {
		if (iFastRun == 2)
		{
			Set_WeaponAnim(id, iState ? 11 : 3)

			set_pev(iEnt, pev_iuser2, 0)
			set_pev(iEnt, pev_fuser2, get_gametime() + 0.5)
			set_pdata_float(iEnt, 48, 0.5, 4)
		}
	}
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_DESPERADO)
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
	
	new iState = pev(ent, pev_iuser3)
	Set_WeaponAnim(id, iState ? DESPERADO_RELOAD_W : DESPERADO_RELOAD_M)
	Set_PlayerNextAttack(id, RELOAD_TIME)
	return HAM_IGNORED
}

public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return
	static Id; Id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(Id, 373) != iEnt)
		return
	if(!Get_BitVar(g_Had_Base, Id))
		return
	
	new iState, iFastRun, Float:fDelayAnim;
	pev(iEnt, pev_fuser2, fDelayAnim);
	iFastRun = pev(iEnt, pev_iuser2)
	iState = pev(iEnt, pev_iuser3)

	if(fDelayAnim < get_gametime() && fDelayAnim)
	{
		switch (iFastRun)
		{
			case 0:
			{
				if (get_pdata_float(iEnt, 48, 4) <= 0.01)
				{
					Set_WeaponAnim(Id, iState ? 8 : 0)
					set_pev(iEnt, pev_fuser2, get_gametime() + 3.03);
				}
			}
			case 1:
			{
				set_pev(iEnt, pev_iuser2, 2)

				Set_WeaponAnim(Id, iState ? 9 : 1)
				set_pev(iEnt, pev_fuser2, get_gametime() + 0.36);
			}
			case 2:
			{
				Set_WeaponAnim(Id, iState ? 10 : 2)
				set_pev(iEnt, pev_fuser2, get_gametime() + 0.6);
			}
			case 3:
			{
				set_pev(iEnt, pev_iuser2, 0)
				
				Set_WeaponAnim(Id, iState ? 11 : 3)
				set_pev(iEnt, pev_fuser2, get_gametime() + 0.5);
			}
		}
	}
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_DESPERADO || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
			
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)

	SetHamParamFloat(3, float(DAMAGE))
	
	return HAM_HANDLED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_DESPERADO || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED

	SetHamParamFloat(3, float(DAMAGE))
	return HAM_HANDLED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED

	pev(id, pev_punchangle, g_Recoil[id])
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return
	if(!Get_BitVar(g_Had_Base, id))
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
	set_pdata_int(Ent, 64, 0, 4)
}
/* ===============================
------------- MUZZLEFLASH --------
=================================*/

public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "despe_mf"))
	{
		static Float:fFrame, Float:fFrameMax,iWpn
		pev(ent, pev_frame, fFrame)
		iWpn = pev(ent, pev_iuser4)
		
		if(!pev_valid(iWpn))
			return
	
		fFrameMax = g_cache_frame_mf[pev(iWpn, pev_iuser3)]
		
		fFrame += 1.0
		set_pev(ent, pev_frame, fFrame)
		
		if(fFrame >= fFrameMax || pev(iWpn, pev_iuser1)) 
		{
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
			return
		}
		set_pev(ent, pev_nextthink, get_gametime() + 0.045)
		return
	}
}

public MakeMuzzleFlash(id, iEnt)
{
	new iState = pev(iEnt, pev_iuser3)
	
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, iState?MF_W:MF_M, "despe_mf", SOLID_NOT,0.045)
	set_pev(iMuz, pev_body, iState?3:1)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.04)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
	//set_pev(iMuz, pev_framerate, 1.0)
	set_pev(iMuz, pev_iuser4, iEnt)
	dllfunc(DLLFunc_Spawn, iMuz)
}

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

////////////////////////////
public Set_WpnList(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(Get_BitVar(g_Had_Base, id) ? "weapon_desperado" : weapon_desperado)
	write_byte(8)
	write_byte(35)
	write_byte(-1)
	write_byte(-1)
	write_byte(1)
	write_byte(1)
	write_byte(CSW_DESPERADO)
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

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
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

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
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


stock Get_Position(id,Float:forw, Float:right, Float:up, Float:vStart[])
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

#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <orpheu>
#include <zombieplague>

#define PLUGIN "AMXX M3 Dragon Minor"
#define VERSION "1.0"
#define AUTHOR "Asdian"

// Data Config
#define P_M3DM "models/p_m3dragonm.mdl"
#define V_M3DM "models/v_m3dragonm.mdl"
#define W_M3DM "models/w_m3dragonm.mdl"

#define MF_L "sprites/m3dragonm_smoke.spr"
#define MF_M "sprites/m3dragonm_smoke2.spr"
#define MF_1 "sprites/muzzleflash106.spr"

#define MODEL_W_OLD "models/w_m3.mdl"

new const SOUND_FIRE[][] = 
{
	"weapons/m3dragonm-1_1.wav",
	"weapons/m3dragonm-1_2.wav",
	"weapons/m3dragonm-2.wav",
	"weapons/m3dragon_exp.wav",
	"weapons/m3dragonm_shark_fx.wav",
	"weapons/m3dragonm_gas_loop.wav", // 5
	"weapons/m3dragon_reload_insert.wav",
	"weapons/m3dragon_after_reload.wav"
}

new const ENT_MODELS[][] = 
{
	"sprites/ef_m3water.spr",
	"models/m3dragonm_effect.mdl",
	
	"sprites/ef_m3waterbomb.spr",
	"sprites/ef_m3dragonm_water.spr",
	"models/ef_m3dragonm_sign.mdl"
}

#define CSW_M3DM CSW_M3
#define weapon_M3DM "weapon_m3"

#define WEAPON_CODE 07132019
#define WEAPON_EVENT "events/m3.sc"

enum _:NewAnim
{
	M3DM_ANIM_IDLE = 0,
	M3DM_ANIM_SHOOT1,
	M3DM_ANIM_SHOOT_CHARGED,
	M3DM_ANIM_INSERT,
	M3DM_ANIM_AFTER,
	M3DM_ANIM_BEFORE,
	M3DM_ANIM_DRAW,
	M3DM_ANIM_IDLE2,
	M3DM_ANIM_SHOOT_CHARGE,
	M3DM_ANIM_INSERT2,
	M3DM_ANIM_AFTER2,
	M3DM_ANIM_BEFORE2,
	M3DM_ANIM_DRAW2,
	M3DM_ANIM_SHOOT2
}

// Weapon Config
#define DAMAGE 70
#define ACCURACY -1 // 0 - 100 ; -1 Default
#define CLIP 8
#define BPAMMO 999

#define SPEED 0.83
#define RECOIL 0.5
#define HIT_COUNT 8

#define BOMB_DAMAGE 50.0
#define BOMB_RADIUS 150.0
#define DRAGON_DAMAGE 20.0
#define DRAGON_RADIUS 125.0
#define DRAGON_KNOCK 316.0

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2

new g_Had_Base, g_OldWeapon[33], Float:g_Recoil[33][3], g_iHit[33], g_iMode[33], g_iShot[33], g_Check[33]
new g_Event_Base, g_SmokePuff_SprId, g_Dprd
new g_cachde_mf[3], Float:g_cache_frame_mf[3], g_cache_exp[2]
	
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
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Item_Deploy, weapon_M3DM, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_M3DM, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_M3DM, "Shotgun_Idle")
	RegisterHam(Ham_Item_PostFrame, weapon_M3DM, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_M3DM, "Shotgun_Reload")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_M3DM, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_M3DM, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_Think, "env_sprite", "fw_MF_Think")
	RegisterHam(Ham_Think, "info_target", "HamF_InfoTarget_Think")
	RegisterHam(Ham_Touch, "info_target", "HamF_InfoTarget_Touch")
	
	// Cache
	register_clcmd("weapon_m3dragonm", "hook_weapon")
	g_Dprd = zp_register_extra_item("M3 Black Dragon M", 10, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR)
}

public hook_weapon(id) engclient_cmd(id, weapon_M3DM)

public plugin_precache()
{
	precache_model(P_M3DM)
	precache_model(V_M3DM)
	precache_model(W_M3DM)
	
	new i
	for(i = 0; i < sizeof SOUND_FIRE; i++) precache_sound(SOUND_FIRE[i])
	for(i = 0; i < sizeof ENT_MODELS; i++)
	{
		if(i == 2) g_cache_exp[0] = precache_model(ENT_MODELS[i])
		else if(i == 3) g_cache_exp[1] = precache_model(ENT_MODELS[i])
		else precache_model(ENT_MODELS[i])
	}
	
	precache_generic("sprites/weapon_m3dragonm.txt")
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_cachde_mf[0] = precache_model(MF_M)
	g_cachde_mf[1] = precache_model(MF_L)
	g_cachde_mf[2] = precache_model(MF_1)
	
	g_cache_frame_mf[0] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[0]))
	g_cache_frame_mf[1] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[1]))
	g_cache_frame_mf[2] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[2]))
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "m3"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_M3DM || !Get_BitVar(g_Had_Base, id))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "m3dragonm")
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
	//RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
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
	Stock_Drop_Slot(id,1)
	fm_give_item(id, weapon_M3DM)
	
	Set_BitVar(g_Had_Base, id)
	g_iMode[id] = 0
	g_iHit[id] = 0
	g_Check[id] = 0
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_M3DM)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_M3DM, BPAMMO)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_M3DM)
	write_byte(CLIP)
	message_end()
	
	ExecuteHamB(Ham_Item_Deploy, Ent)
}

public Remove_Base(id)
{
	UnSet_BitVar(g_Had_Base, id)
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_M3DM && g_OldWeapon[id] != CSW_M3DM) && Get_BitVar(g_Had_Base, id))
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_M3DM && g_OldWeapon[id] == CSW_M3DM) && Get_BitVar(g_Had_Base, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_M3DM)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
		if(!get_pdata_int(Ent, 55, 4))
		{
			set_pdata_float(Ent, 46, SPEED, 4)
			set_pdata_float(Ent, 47, SPEED, 4)
		}
	} else if(CSWID != CSW_M3DM && g_OldWeapon[id] == CSW_M3DM) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_M3DM)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_M3DM)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
	} else {
		static ent, iFlame[2]
		ent = fm_get_user_weapon_entity(id, CSW_M3DM)
		iFlame[0] = find_ent_by_class(id, "M3DM_kobongan")
		iFlame[1] = find_ent_by_class(id, "M3DM_kobongan2")
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 
		if(pev_valid(iFlame[0])) set_pev(iFlame[0], pev_effects, pev(iFlame[0], pev_effects) | EF_NODRAW)
		if(pev_valid(iFlame[1])) set_pev(iFlame[1], pev_effects, pev(iFlame[1], pev_effects) | EF_NODRAW)
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_M3DM && Get_BitVar(g_Had_Base, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_M3DM || !Get_BitVar(g_Had_Base, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event_Base)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	emit_sound(invoker, CHAN_WEAPON, SOUND_FIRE[random(1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	Set_WeaponAnim(invoker, Shot_Anim(invoker))
	MakeMuzzleFlash2(invoker)
	return FMRES_SUPERCEDE
}

public Shot_Anim(id)
{
	new iAnim
	if(g_Check[id]) iAnim = M3DM_ANIM_SHOOT_CHARGED
	else iAnim = (g_iMode[id]?M3DM_ANIM_SHOOT2:M3DM_ANIM_SHOOT1)
	return iAnim
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
		static weapon; weapon = find_ent_by_owner(-1, weapon_M3DM, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, W_M3DM)

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
	
	set_pev(Id, pev_viewmodel2, V_M3DM)
	set_pev(Id, pev_weaponmodel2, P_M3DM)
	Set_WeaponAnim(Id, g_iMode[Id]?M3DM_ANIM_DRAW2:M3DM_ANIM_DRAW)
	
	Additional_Deploy(Ent, Id)
	Set_WpnList(Id)
	set_pdata_float(Ent, 48, 1.5, 4)
		
	static iClip
	iClip = get_pdata_int(Ent, 51, 4)
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, Id)
	write_byte(1)
	write_byte(CSW_M3DM)
	write_byte(iClip)
	message_end()
}

public Additional_Deploy(ent, id)
{
	set_pdata_int(ent, 55, 0, 4)
	
	static iFlame[2]
	iFlame[0] = find_ent_by_class(id, "M3DM_kobongan")
	iFlame[1] = find_ent_by_class(id, "M3DM_kobongan2")
	
	if(pev_valid(iFlame[0])) set_pev(iFlame[0], pev_effects, pev(iFlame[0], pev_effects) &~ EF_NODRAW)
	if(pev_valid(iFlame[1])) set_pev(iFlame[1], pev_effects, pev(iFlame[1], pev_effects) &~ EF_NODRAW)
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
	
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_M3DM)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	new iButton = pev(id, pev_button)
	
	WE_M3Dragon(id, ent, iClip,bpammo,iButton)
	return HAM_IGNORED
}

public WE_M3Dragon(id,iEnt,iClip, bpammo,iButton)
{
	if((iButton & IN_ATTACK2) && g_iMode[id] && get_pdata_float(iEnt, 46, 4) <= 0.0)
	{
		g_iShot[id] = 0
		
		Set_WeaponAnim(id, M3DM_ANIM_SHOOT_CHARGE, 1)
		emit_sound(id, CHAN_WEAPON, SOUND_FIRE[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		new Float:vOrigin[3], Float:vAngles[3], Float:vVec[3],Float:vAngle[3]
		pev(id, pev_origin, vOrigin)
		pev(id, pev_v_angle, vAngle)
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, vAngle)
		xs_vec_mul_scalar(vAngle, 2000.0, vVec)
		
		static iBall
		iBall = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FLY, ENT_MODELS[0], "M3DM_kobonganbunder", SOLID_BBOX, 0.05)
		engfunc(EngFunc_SetSize, iBall, Float:{-1.0, -1.0, 1.0}, Float:{1.0, 1.0, 1.0})
		set_pev(iBall, pev_origin, vOrigin)
		set_pev(iBall, pev_rendermode, kRenderTransAdd)
		set_pev(iBall, pev_renderamt, 255.0)
		set_pev(iBall, pev_light_level, 180.0)
		set_pev(iBall, pev_gravity, 0.01)
		set_pev(iBall, pev_animtime, get_gametime())
		set_pev(iBall, pev_scale, 0.1)
		set_pev(iBall, pev_frame, 0.0)
		set_pev(iBall, pev_framerate, 1.0)
		set_pev(iBall, pev_sequence, 0)
		set_pev(iBall, pev_velocity, vVec)
		
		static Float:vVelocity[3]
		pev(iBall, pev_velocity, vVelocity)
		vector_to_angle(vVelocity, vAngles)
		if(vAngles[0] > 90.0) vAngles[0] = -(360.0 - vAngles[0])
		set_pev(iBall, pev_angles, vAngles)
		
		static iFlame[2]
		iFlame[0] = find_ent_by_class(id, "M3DM_kobongan")
		iFlame[1] = find_ent_by_class(id, "M3DM_kobongan2")
		
		if(pev_valid(iFlame[0])) set_pev(iFlame[0], pev_flags, pev(iFlame[0], pev_flags) | FL_KILLME)
		if(pev_valid(iFlame[1])) set_pev(iFlame[1], pev_flags, pev(iFlame[1], pev_flags) | FL_KILLME)
		
		set_pdata_float(iEnt, 46, SPEED, 4)
		set_pdata_float(iEnt, 48, SPEED + 0.5, 4)
		
		if(get_pdata_int(iEnt, 55, 4)) set_pdata_int(iEnt, 55, 0, 4)
		set_pdata_int(id, 376 + 16, 0, 5)
		
		g_iHit[id] = 0
		g_iMode[id] = 0
	}
	iButton &= ~IN_ATTACK2
	set_pev(id, pev_button, iButton &~ IN_ATTACK2)
}

public Shotgun_Reload(iEnt)
{
	static id, iClip, iMaxClip, fInSpReload, iBpAmmo
	id = get_pdata_cbase(iEnt, 41, 4)
	iClip = get_pdata_int(iEnt, 51, 4)
	iBpAmmo = get_pdata_int(id, 381, 4)
	fInSpReload = get_pdata_int(iEnt, 55, 4)
	iMaxClip = CLIP
	
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	if(!iClip && pev(id, pev_button) & IN_ATTACK)
		return HAM_IGNORED
	
	ShotgunReload(iEnt, iMaxClip, iClip, iBpAmmo, id, fInSpReload)
	return HAM_SUPERCEDE
}

public Shotgun_Idle(iEnt)
{
	static id, iClip, iMaxClip, fInSpReload, iBpAmmo, Float:flTimeWeaponIdle
	id = get_pdata_cbase(iEnt, 41, 4)
	flTimeWeaponIdle = get_pdata_float(iEnt, 48, 4)
	iClip = get_pdata_int(iEnt, 51, 4)
	fInSpReload = get_pdata_int(iEnt, 55, 4)
	iBpAmmo = get_pdata_int(id, 381, 4)
	iMaxClip = CLIP

	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED
	if(!iClip && pev(id, pev_button) & IN_ATTACK)
		return HAM_IGNORED
	
	if(flTimeWeaponIdle <= 0.0)
	{
		if(!iClip && !fInSpReload && iBpAmmo) ShotgunReload(iEnt, iMaxClip, iClip, iBpAmmo, id, fInSpReload)
		else if(fInSpReload != 0)
		{
			if(iClip != iMaxClip && iBpAmmo) ShotgunReload(iEnt, iMaxClip, iClip, iBpAmmo, id, fInSpReload)
			else
			{
				Set_WeaponAnim(id, g_iMode[id]?M3DM_ANIM_AFTER2:M3DM_ANIM_AFTER)
				SendSound(id, CHAN_WEAPON, SOUND_FIRE[7])
				
				set_pdata_int(iEnt, 55, 0, 4)
				set_pdata_float(iEnt, 48, 1.3, 4)
			}
		} else {
			Set_WeaponAnim(id, g_iMode[id]?M3DM_ANIM_IDLE2:M3DM_ANIM_IDLE)
			set_pdata_float(iEnt, 48, 3.7, 4)
		}
	}
	if(!g_iMode[id])
		return HAM_IGNORED
	
	new Float:fTimer; pev(iEnt, pev_fuser4, fTimer)
	if(fTimer < get_gametime())
	{
		emit_sound(id, CHAN_VOICE, SOUND_FIRE[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_pev(iEnt, pev_fuser4, get_gametime() + 0.85)
	}
	return HAM_SUPERCEDE
}

public ShotgunReload(iEnt, iMaxClip, iClip, iBpAmmo, id, fInSpReload)
{
	if(iBpAmmo <= 0 || iClip == iMaxClip)
		return
	if(get_pdata_int(iEnt, 47, 4) > 0.0)
		return
	
	if(!fInSpReload)
	{
		Set_WeaponAnim(id, g_iMode[id]?M3DM_ANIM_BEFORE2:M3DM_ANIM_BEFORE)
		set_pdata_int(iEnt, 55, 1, 4)
		
		set_pdata_float(id, 83, 0.53, 5)
		set_pdata_float(iEnt, 47, 0.53, 4)
		set_pdata_float(iEnt, 48, 0.55, 4)
	} else if(fInSpReload == 1) {
		set_pdata_int(iEnt, 55, 2, 4)
		Set_WeaponAnim(id, g_iMode[id]?M3DM_ANIM_INSERT2:M3DM_ANIM_INSERT)
		
		// FAAKKK
		if(get_pdata_int(iEnt, 75, 4) <= 0.0)
			SendSound(id, CHAN_WEAPON, SOUND_FIRE[6])
		
		set_pdata_float(iEnt, 75, 0.43, 4)
		set_pdata_float(iEnt, 47, 0.43, 4)
		set_pdata_float(iEnt, 48, 0.43, 4)
	} else {
		set_pdata_int(iEnt, 51, iClip + 1, 4)
		set_pdata_int(id, iBpAmmo - 1, 4)
		set_pdata_int(iEnt, 55, 1)
	}
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_M3DM || !Get_BitVar(g_Had_Base, Attacker))
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
	if(get_player_weapon(Attacker) != CSW_M3DM || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED

	SetHamParamFloat(3, float(DAMAGE))
	return HAM_HANDLED
}

public fw_TakeDamage(Victim, Inflictor, Attacker, Float:fDamage, iDamageType)
{	
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_M3DM || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED
	if(g_iMode[Attacker])
		return HAM_IGNORED
			
	if(is_user_alive(Victim) && can_damage(Victim, Attacker) && g_iShot[Attacker] && g_iHit[Attacker] < HIT_COUNT)
	{
		g_iHit[Attacker]++
		
		static Wpn; Wpn = get_pdata_cbase(Attacker, 373)
		if(pev_valid(Wpn) && g_iHit[Attacker] >= HIT_COUNT) 
		{
			g_Check[Attacker] = 1
			MakeMuzzleFlash(Attacker, Wpn, 0)
			MakeMuzzleFlash(Attacker, Wpn, 1)
			
			set_pdata_int(Attacker, 376 + 16, 1, 5)
			g_iMode[Attacker] = 1
			
			set_pev(Wpn, pev_fuser1, get_gametime() + 0.5)
		}
	}
	return HAM_IGNORED
}

// SCREW YOU
public client_PostThink(id)
{
	if(!is_connected(id))
		return 	
	if(get_player_weapon(id) != CSW_M3DM || !Get_BitVar(g_Had_Base, id))
		return 
	
	static Wpn; Wpn = get_pdata_cbase(id, 373)
	if(!pev_valid(Wpn)) return
	
	new Float:fTimer; pev(Wpn, pev_fuser1, fTimer)
	if(fTimer < get_gametime()) g_Check[id] = 0
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED

	g_iShot[id] = 1
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
	
	g_iShot[id] = 0
	set_pdata_int(Ent, 64, 0, 4)
	set_pdata_int(Ent, 55, 0, 4)
}
/* ===============================
------------- ENTITIES -----------
=================================*/
public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "M3DM_kobongan") || equal(Classname, "M3DM_kobongan2"))
	{
		static Float:fFrame, Float:fFrameMax
		pev(ent, pev_frame, fFrame)
		fFrameMax = g_cache_frame_mf[pev(ent, pev_iuser3)]
		
		fFrame += 1.5
		
		if(fFrame >= fFrameMax) 
			fFrame = 0.0
		
		set_pev(ent, pev_frame, fFrame)
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
		return
	}
	
	if(equal(Classname, "M3DM_dor"))
	{
		static Float:fFrame, Float:fFrameMax
		pev(ent, pev_frame, fFrame)
		fFrameMax = g_cache_frame_mf[2]
		
		fFrame += 1.0
		set_pev(ent, pev_frame, fFrame)
		set_pev(ent, pev_nextthink, get_gametime() + 0.035)
		
		if(fFrame >= fFrameMax) 
		{
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
			return
		}
		return
	}
}

public HamF_InfoTarget_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	new iOwner, iState
	iOwner = pev(iEnt, pev_owner)
	iState = pev(iEnt, pev_iuser1)
	
	if(equal(Classname, "M3DM_kobonganbunder"))
	{
		if(!iState) 
		{
			static Float:fFrame
			pev(iEnt, pev_frame, fFrame)
			
			fFrame += 1.0
			
			if(fFrame >= 16.0) // from spr
				fFrame = 0.0
				
			set_pev(iEnt, pev_frame, fFrame)
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
			return
		} else {
			new Float:vecOri[3]
			pev(iEnt, pev_vuser1, vecOri)
			
			if(get_gametime() >= pev(iEnt, pev_ltime)) 
			{
				set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
				return
			}
			
			static Float:fTimer
			pev(iEnt, pev_fuser1, fTimer)
			
			if(fTimer < get_gametime() && pev(iEnt, pev_iuser2))
			{
				new iEfx = Stock_CreateEntityBase(iOwner, "info_target", MOVETYPE_NONE, ENT_MODELS[1], "M3DM_nogosari", SOLID_NOT, 0.0)
				set_pev(iEfx, pev_origin, vecOri)
				set_pev(iEfx, pev_iuser1, 0)
				set_pev(iEfx, pev_animtime, get_gametime())
				set_pev(iEfx, pev_sequence, 0)
				set_pev(iEfx, pev_framerate, 1.0)
				set_pev(iEfx, pev_ltime, get_gametime() + 1.75)
				set_pev(iEfx, pev_nextthink, get_gametime())
				engfunc(EngFunc_SetSize, iEfx, Float:{-0.1, -0.1, -0.1}, Float:{0.1, 0.1, 0.1})
				emit_sound(iEfx, CHAN_WEAPON, SOUND_FIRE[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_pev(iEfx, pev_iuser2, 1)
				drop_to_floor(iEfx)
	
				set_pev(iEnt, pev_iuser2, 0)
				
				new Float:Test[3]; pev(iEfx, pev_origin, Test)
				Watersplash(Test, Test[0], Test[1], Test[2])
				Watersplash(Test, Test[0] + 50.0, Test[1], Test[2])
				Watersplash(Test, Test[0] - 50.0, Test[1], Test[2])
				Watersplash(Test, Test[0], Test[1] + 50.0, Test[2])
				Watersplash(Test, Test[0], Test[1] - 50.0, Test[2])
				
				set_pev(iEfx, pev_vuser1, Test)
			}
			
			new pEntity = -1;
			while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOri, DRAGON_RADIUS)) != 0)
			{
				if (!pev_valid(pEntity))
					continue;
				if (iOwner == pEntity)
					continue;
				if (!is_user_alive(pEntity))
					continue;
				
				new vEntOrigin[3]
				pev(pEntity, pev_origin, vEntOrigin)
				
				new iBuff = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
				set_pev(iBuff, pev_classname, "M3DM_nogosari")
				set_pev(iBuff, pev_origin, vEntOrigin)
				engfunc(EngFunc_SetModel, iBuff, "models/w_usp.mdl")
				set_pev(iBuff, pev_nextthink, get_gametime())
				set_pev(iBuff, pev_iuser1, 1)
				set_pev(iBuff, pev_enemy, pEntity)
				set_pev(iBuff, pev_aiment, pEntity)
				set_pev(iBuff, pev_owner, iOwner)
				set_pev(iBuff, pev_vuser1, vecOri)
				fm_set_rendering(iBuff, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
				set_pev(iBuff, pev_ltime, get_gametime() + 1.33)
			}
			
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		} 
	}
	
	if(!equal(Classname, "M3DM_nogosari"))
		return
		
	if(!iState)
	{
		static Float:fTimeRemove, Float:fRenderMount; 
		pev(iEnt, pev_ltime, fTimeRemove)
		pev(iEnt, pev_renderamt, fRenderMount)
		
		static Float:fFrame
		pev(iEnt, pev_frame, fFrame)
		
		fFrame += 1.0
		set_pev(iEnt, pev_frame, fFrame)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		
		if(get_gametime() >= fTimeRemove) 
		{
			if(pev(iEnt, pev_iuser2))
			{
				new Float:vecOri[3]
				pev(iEnt, pev_vuser1, vecOri)
				
				Watersplash(vecOri, vecOri[0], vecOri[1], vecOri[2])
				Watersplash(vecOri, vecOri[0] + 50.0, vecOri[1], vecOri[2])
				Watersplash(vecOri, vecOri[0] - 50.0, vecOri[1], vecOri[2])
				Watersplash(vecOri, vecOri[0], vecOri[1] + 50.0, vecOri[2])
				Watersplash(vecOri, vecOri[0], vecOri[1] - 50.0, vecOri[2])
				
				set_pev(iEnt, pev_iuser2, 0)
			}
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return
		}
	} else {
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.02)
		
		new iVic, Float:vecOri[3]
		iVic = pev(iEnt, pev_enemy)
		pev(iEnt, pev_vuser1, vecOri)
			
		new Float:vOrigin[3], Float:v2DOrigin[2][3], Float:vecVelocity[3]
		v2DOrigin[0] = vecOri
		v2DOrigin[0][2] = 0.0
		
		pev(iVic, pev_origin, vOrigin);
		v2DOrigin[1] = vOrigin
		v2DOrigin[1][2] = 0.0
		
		if(floatabs(vOrigin[2] - vecOri[2]) < 350.0 && vector_distance(v2DOrigin[0], v2DOrigin[1]) < 270.0)
		{
			 pev(iVic, pev_velocity, vecVelocity)
			 xs_vec_mul_scalar(vecVelocity, 0.35, vecVelocity)
			 vecVelocity[2] = 550.0;
			 set_pev(iVic, pev_velocity, vecVelocity)
		
			 ExecuteHamB(Ham_TakeDamage, iVic, fm_get_user_weapon_entity(iOwner, CSW_M3DM), iOwner, DRAGON_DAMAGE, DMG_BULLET)
		}
		
		static Float:fTimeRemove; 
		pev(iEnt, pev_ltime, fTimeRemove)
		
		if(get_gametime() >= fTimeRemove) 
		{
			set_pev(iEnt, pev_enemy, 0)
			set_pev(iEnt, pev_aiment, 0)
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return
		}
	}
}

public HamF_InfoTarget_Touch(iEnt, iPtd)
{
	if(!pev_valid(iEnt))
		return HAM_IGNORED
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "M3DM_kobonganbunder"))
		return HAM_IGNORED
		
	new iOwner, Float:vecOri[3]
	iOwner = pev(iEnt, pev_owner)
	pev(iEnt, pev_origin, vecOri)
	
	if(iPtd == iOwner)
		return HAM_IGNORED
	
	Stock_RadiusDamage(vecOri, iEnt, iOwner, BOMB_DAMAGE, BOMB_RADIUS, 0.0, DMG_BULLET)
	emit_sound(iEnt, CHAN_VOICE, SOUND_FIRE[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOri, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecOri[0])
	engfunc(EngFunc_WriteCoord, vecOri[1])
	engfunc(EngFunc_WriteCoord, vecOri[2])
	write_short(g_cache_exp[0])
	write_byte(10)
	write_byte(20)
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	message_end()
	
	fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
	set_pev(iEnt, pev_solid, SOLID_NOT)
	set_pev(iEnt, pev_fuser1, get_gametime() + 1.15)
	set_pev(iEnt, pev_iuser1, 1)
	set_pev(iEnt, pev_iuser2, 1) // temp check
	set_pev(iEnt, pev_vuser1, vecOri)
	set_pev(iEnt, pev_ltime, get_gametime() + 3.1)
	set_pev(iEnt, pev_nextthink, get_gametime() + 1.15)
	
	// water
	new iEfx = Stock_CreateEntityBase(iOwner, "info_target", MOVETYPE_NONE, ENT_MODELS[4], "M3DM_nogosari", SOLID_NOT, 0.0)
	set_pev(iEfx, pev_light_level, 255.0)
	set_pev(iEfx, pev_origin, vecOri)
	set_pev(iEfx, pev_iuser1, 0)
	set_pev(iEfx, pev_animtime, get_gametime())
	set_pev(iEfx, pev_sequence, 0)
	set_pev(iEfx, pev_framerate, 1.0)
	set_pev(iEfx, pev_ltime, get_gametime() + 3.1)
	set_pev(iEfx, pev_nextthink, get_gametime())
	engfunc(EngFunc_SetSize, iEfx, Float:{-0.1, -0.1, -0.1}, Float:{0.1, 0.1, 0.1})
	drop_to_floor(iEfx)
	return HAM_IGNORED
}

public Watersplash(Float:vecOri[3], Float:vecOriX, Float:vecOriY, Float:vecOriZ)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOri, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecOriX)
	engfunc(EngFunc_WriteCoord, vecOriY)
	engfunc(EngFunc_WriteCoord, vecOriZ + 70.0)
	write_short(g_cache_exp[1])
	write_byte(10)
	write_byte(25)
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	message_end()
}

public MakeMuzzleFlash(id, iEnt, iNum) // damn, thats hard...
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, !iNum?MF_L:MF_M, iNum?"M3DM_kobongan":"M3DM_kobongan2", SOLID_NOT,0.01)
	set_pev(iMuz, pev_body, 2)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.08)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
	set_pev(iMuz, pev_framerate, 1.0)
	set_pev(iMuz, pev_iuser3, iNum)
	dllfunc(DLLFunc_Spawn, iMuz)
}

public MakeMuzzleFlash2(id)
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, MF_1, "M3DM_dor", SOLID_NOT,0.01)
	set_pev(iMuz, pev_body, 1)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.08)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
	set_pev(iMuz, pev_iuser3, 2)
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
	write_string(Get_BitVar(g_Had_Base, id) ? "weapon_m3dragonm" : weapon_M3DM)
	write_byte(5)
	write_byte(32)
	write_byte(16)
	write_byte(1)
	write_byte(0)
	write_byte(5)
	write_byte(CSW_M3DM)
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
stock SendSound(id, chan, sample[]) emit_sound(id, chan, sample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

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

stock Stock_RadiusDamage(Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage, Float:flRadius, Float:flKnockBack, bitsDamageType, bSkipAttacker=true, bCheckTeam=false, bDistanceCheck = true)
{
	new pEntity = -1;
	new tr = create_tr2();
	new Float:flAdjustedDamage, Float:falloff;
	new iHitResult = RESULT_HIT_NONE;

	if (bDistanceCheck) falloff = flDamage / flRadius;
	else falloff = 0.0;

	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER);

	vecSrc[2] += 1.0;

	if (!pevAttacker)
		pevAttacker = pevInflictor;

	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if (pev(pEntity, pev_takedamage) == DAMAGE_NO)
			continue;
		if (bInWater && !pev(pEntity, pev_waterlevel))
			continue;
		if (!bInWater && pev(pEntity, pev_waterlevel) == 3)
			continue;
		if (bSkipAttacker && pEntity == pevAttacker)
			continue;
		if (bCheckTeam && IsPlayer(pEntity) && pEntity != pevAttacker)
			if(!can_damage(pEntity,pevAttacker) && !get_cvar_num("mp_friendlyfire"))
				continue;

		new Float:vecEnd[3];
		pev(pEntity, pev_origin, vecEnd);

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, 0, tr);

		new Float:flFraction;
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction >= 1.0)
			engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, 0, tr);
		
		if (pev_valid(pEntity))
		{
			pev(pEntity, pev_origin, vecEnd);
			xs_vec_sub(vecEnd, vecSrc, vecEnd);

			new Float:fDistance = xs_vec_len(vecEnd);
			if (fDistance < 1.0)
				fDistance = 0.0;

			flAdjustedDamage = fDistance * falloff;
			flAdjustedDamage = flDamage - flAdjustedDamage;

			if (get_tr2(tr, TR_pHit) != pEntity) flAdjustedDamage *= 0.3;

			if (flAdjustedDamage <= 0)
				continue;
			
			xs_vec_normalize(vecEnd, vecEnd);

			new Float:vecVelocity[3], Float:vecOldVelocity[3];
			xs_vec_mul_scalar(vecEnd, flKnockBack * ((flRadius - fDistance) / flRadius), vecVelocity);
			pev(pEntity, pev_velocity, vecOldVelocity);
			vecVelocity[2] += 55.0
			xs_vec_add(vecVelocity, vecOldVelocity, vecVelocity);
			if (IsPlayer(pEntity)) set_pev(pEntity, pev_velocity, vecVelocity);

			new iBody
			iBody = get_tr2(tr,TR_iHitgroup)

			OrpheuCall(OrpheuGetFunction("ClearMultiDamage"))
			ExecuteHamB(Ham_TraceAttack, pEntity, pevAttacker,flAdjustedDamage *= Stock_Get_Body_Dmg(iBody), vecEnd, tr, bitsDamageType);
			OrpheuCall(OrpheuGetFunction("ApplyMultiDamage"), pevInflictor, pevAttacker)

			iHitResult = RESULT_HIT_PLAYER;
		}
	}
	free_tr2(tr);
	return iHitResult;
}
stock Float:Stock_Get_Body_Dmg(iBody)
{
	switch (iBody)
	{
		case HIT_GENERIC: return 0.75
		case 1: return 4.0 // ?
		case 2 : return 1.0 // ?
		case 3 : return 1.25 // ?
		case 4,5,6,7 : return 0.75 // ? ?
		default :return 0.75
	}
	return 1.0
}
stock IsPlayer(pEntity) return is_user_connected(pEntity)

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

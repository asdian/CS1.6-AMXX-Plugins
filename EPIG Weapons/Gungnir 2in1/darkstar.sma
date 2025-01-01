#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>
#include <md_csohud>

#define PLUGIN "Gungnir + Dark Star"
#define VERSION "3.0"
#define AUTHOR "Asdian"

// Data Config
#define P_GUNGNIR "models/p_gungnira.mdl"
#define P_GUNGNIR2 "models/p_gungnirb.mdl"
#define V_GUNGNIR "models/v_gungnir.mdl"
#define W_GUNGNIR "models/w_gungnir.mdl"

#define P_GUNGNIREX "models/p_gungnirexa.mdl"
#define P_GUNGNIREX2 "models/p_gungnirexb.mdl"
#define V_GUNGNIREX "models/v_gungnirex.mdl"
#define W_GUNGNIREX "models/w_gungnirex.mdl"

#define MF_W "sprites/muzzleflash81.spr"
#define MF_W_EX "sprites/muzzleflash158.spr"
#define MODEL_W_OLD "models/w_mac10.mdl"
#define WEAPON_CODE 08242021

#define CSW_GUNGNIREX CSW_MAC10
#define weapon_gungnirex "weapon_mac10"

enum _:NewAnim
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_START,
	ANIM_SHOOT_LOOP,
	ANIM_SHOOT_END,
	ANIM_SHOOT2,
	ANIM_SHOOT2_CHARGE,
	ANIM_SHOOT2_SHOTCHARGE,
	ANIM_CHARGE_LOOP
}

new const SOUND_FIRE[][] = 
{
	"weapons/gungnir_shoot_loop.wav",	// 0
	"weapons/gungnir_shoot_end.wav",
	"weapons/gungnir_shoot_b.wav",
	"weapons/gungnir_charge_shoot1.wav",
	
	// exps
	"weapons/gungnir_shoot_b_exp.wav",	// 4
	"weapons/gungnir_charge_shoot_exp.wav",
	"weapons/gungnir_charge_shoot_exp2.wav",
	
	"weapons/gungnir_idle.wav"		// 7
}

new const EXP_MODELS[][] = 
{
	"sprites/ef_gungnir_aexplo.spr",
	"sprites/ef_gungnir_bexplo.spr",
	"sprites/ef_gungnir_chargeexplo.spr",
	"sprites/ef_gungnir_lightline1.spr",
	"sprites/ef_gungnir_lightline2.spr",
	"sprites/ef_gungnir_missile.spr",
	"sprites/ef_gungnir_xbeam.spr",
	
	"models/gungnir_missile.mdl"
}

new const EXP_MODELS_EX[][] = 
{
	"sprites/ef_gungnir_aexploex.spr",
	"sprites/ef_gungnir_bexploex.spr",
	"sprites/ef_gungnir_chargeexploex.spr",
	"sprites/ef_gungnir_lightline1ex.spr",
	"sprites/ef_gungnir_lightline2ex.spr",
	"sprites/ef_gungnir_missileex.spr",
	"sprites/ef_gungnir_xbeamex.spr",
	
	"models/gungnirex_missile.mdl"
}

// Weapon Config
#define ACCURACY 23 // 0 - 100 ; -1 Default
#define CLIP 50
#define BPAMMO 999
#define SPEED 0.113
#define RECOIL 0.5
#define RELOAD_TIME 2.03

#define ELECTRO_DAMAGE 50.0
#define ELECTRO_RANGE 256.0
#define ELECTRO_KNOCKBACK 150.0 // the velocity of victim when got damage

// base damage
#define WDAMG_PLASMA 500.0
#define WDAMG_CHARGE 700.0
#define WDAMG_BEAM 175.0
	
// range
#define WRANGE_PLASMA 210.0
#define WRANGE_CHARGE 250.0
#define WRANGE_BEAM 75.0
	
// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_cachde_mf[2], Float:g_cache_frame_mf[2], g_cache_light[2], g_cache_hit[2], g_cache_exp[2][2], g_cache_beam[2][2], g_SpraySpr, g_DropSpr
new g_Had_Base, g_Clip[33], g_OldWeapon[33], g_Dprd[2], g_iVic[3], Float:g_fIdleSound[33], g_iType[33]
	
// Safety
new g_HamBot, g_freezetime
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	
	// Event
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("HLTV","Event_HLTV","a","1=0","2=0")
	register_logevent("LogEvent_Round_Start",2, "1=Round_Start")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_gungnirex, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_gungnirex, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_gungnirex, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_gungnirex, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_gungnirex, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Think, "env_sprite", "fw_MF_Think")
	RegisterHam(Ham_Think, "info_target", "HamF_InfoTarget_Think")
	RegisterHam(Ham_Touch, "info_target", "HamF_InfoTarget_Touch")
	
	// Cache
	register_clcmd("weapon_gungnir", "hook_weapon")
	register_clcmd("weapon_gungnirex", "hook_weapon")
	
	g_Dprd[0] = zp_register_extra_item("Gungnir", 10, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR)
	g_Dprd[1] = zp_register_extra_item("\rDark Star", 10, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR)
}

public Event_HLTV() g_freezetime = 1
public LogEvent_Round_Start() g_freezetime = 0

public hook_weapon(id) engclient_cmd(id, weapon_gungnirex)

public plugin_precache()
{
	precache_model(P_GUNGNIR)
	precache_model(P_GUNGNIR2)
	precache_model(V_GUNGNIR)
	precache_model(W_GUNGNIR)
	
	precache_model(P_GUNGNIREX)
	precache_model(P_GUNGNIREX2)
	precache_model(V_GUNGNIREX)
	precache_model(W_GUNGNIREX)
	
	new i
	for(i = 0; i < sizeof SOUND_FIRE; i++) precache_sound(SOUND_FIRE[i])
	for(i = 0; i < sizeof EXP_MODELS; i++)
	{
		if(!i) g_cache_hit[0] = precache_model(EXP_MODELS[i])
		else if(i == 1) g_cache_exp[0][0] = precache_model(EXP_MODELS[i])
		else if(i == 2) g_cache_exp[0][1] = precache_model(EXP_MODELS[i])
		else if(i == 3) g_cache_beam[0][0] = precache_model(EXP_MODELS[i])
		else if(i == 4) g_cache_beam[0][1] = precache_model(EXP_MODELS[i])
		else if(i == 6) g_cache_light[0] = precache_model(EXP_MODELS[i])
		else precache_model(EXP_MODELS[i])
	}
	
	for(i = 0; i < sizeof EXP_MODELS_EX; i++)
	{
		if(!i) g_cache_hit[1] = precache_model(EXP_MODELS_EX[i])
		else if(i == 1) g_cache_exp[1][0] = precache_model(EXP_MODELS_EX[i])
		else if(i == 2) g_cache_exp[1][1] = precache_model(EXP_MODELS_EX[i])
		else if(i == 3) g_cache_beam[1][0] = precache_model(EXP_MODELS_EX[i])
		else if(i == 4) g_cache_beam[1][1] = precache_model(EXP_MODELS_EX[i])
		else if(i == 6) g_cache_light[1] = precache_model(EXP_MODELS_EX[i])
		else precache_model(EXP_MODELS_EX[i])
	}
	
	precache_generic("sprites/weapon_gungnir.txt")
	precache_generic("sprites/weapon_gungnirex.txt")
	
	g_SpraySpr = precache_model("sprites/bloodspray.spr")
	g_DropSpr = precache_model("sprites/blood.spr")
	
	g_cachde_mf[0] = precache_model(MF_W)
	g_cachde_mf[1] = precache_model(MF_W_EX)
	
	g_cache_frame_mf[0] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[0]))
	g_cache_frame_mf[1] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[1]))
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "mac10"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_GUNGNIREX || !Get_BitVar(g_Had_Base, id))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, g_iType[id] ? "gungnirex" : "gungnir")
	return PLUGIN_CONTINUE
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
 
public Register_HamBot(id) Register_SafetyFuncBot(id)
public client_disconnected(id) Safety_Disconnected(id)

public zp_extra_item_selected(i, d) 
{
	if(d == g_Dprd[0]) Get_Base(i, 0)
	if(d == g_Dprd[1]) Get_Base(i, 1)
}
public zp_user_infected_post(i) if(zp_get_user_zombie(i)) Remove_Base(i)
public zp_user_humanized_post(i) if(zp_get_user_survivor(i)) Remove_Base(i)

public Get_Base(id, mode)
{
	Stock_Drop_Slot(id, 1)
	
	if(Get_BitVar(g_Had_Base, id)) Remove_Base(id)
	Set_BitVar(g_Had_Base, id)
	g_iType[id] = mode
	
	fm_give_item(id, weapon_gungnirex)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_GUNGNIREX)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_GUNGNIREX, BPAMMO)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_GUNGNIREX)
	write_byte(CLIP)
	message_end()
	
	mdcsohud_regwpnhud(id, CSW_GUNGNIREX, g_iType[id] ? "weapon_gungnirex" : "weapon_gungnir")
	ExecuteHamB(Ham_Item_Deploy, Ent)
}

public Remove_Base(id)
{
	mdcsohud_resetwpnhud(id, CSW_GUNGNIREX)
	UnSet_BitVar(g_Had_Base, id)
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_GUNGNIREX && g_OldWeapon[id] != CSW_GUNGNIREX) && Get_BitVar(g_Had_Base, id))
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_GUNGNIREX && g_OldWeapon[id] == CSW_GUNGNIREX) && Get_BitVar(g_Had_Base, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_GUNGNIREX)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
	} else if(CSWID != CSW_GUNGNIREX && g_OldWeapon[id] == CSW_GUNGNIREX) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_GUNGNIREX)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_GUNGNIREX)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_GUNGNIREX)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_GUNGNIREX && Get_BitVar(g_Had_Base, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
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
		static weapon; weapon = find_ent_by_owner(-1, weapon_gungnirex, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			set_pev(weapon, pev_iuser2, cs_get_user_bpammo(iOwner, CSW_GUNGNIREX))
			set_pev(weapon, pev_iuser3, get_pdata_int(weapon, 51, 4))
			set_pev(weapon, pev_iuser4, g_iType[iOwner])
			
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, g_iType[iOwner] ? W_GUNGNIREX : W_GUNGNIR)

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
	
	set_pev(Id, pev_viewmodel2, g_iType[Id] ? V_GUNGNIREX : V_GUNGNIR)
	set_pev(Id, pev_weaponmodel2, g_iType[Id] ? P_GUNGNIREX : P_GUNGNIR)
	
	Set_WeaponAnim(Id, ANIM_DRAW)
	set_pdata_string(Id, (492 * 4), "m249", -1, 20)
	Set_WpnList(Id)
	
	set_pdata_float(Ent, 46, 1.03, 4)
	set_pdata_float(Ent, 47, 1.03, 4)
	set_pdata_float(Ent, 48, 1.03, 4)
	
	set_pev(Ent, pev_iuser1, 0);
	set_pev(Ent, pev_iuser2, 0);
	
	static iClip
	iClip = get_pdata_int(Ent, 51, 4)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, Id)
	write_byte(1)
	write_byte(CSW_GUNGNIREX)
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
		
		g_iType[id] = pev(Ent, pev_iuser4)
		
		static iMaxClip; iMaxClip = pev(Ent, pev_iuser3)
		static iBpAmmo; iBpAmmo = pev(Ent, pev_iuser2)
		set_pdata_int(Ent, 51, iMaxClip, 4)
		cs_set_user_bpammo(id, CSW_GUNGNIREX, iBpAmmo)
		
		mdcsohud_regwpnhud(id, CSW_GUNGNIREX, g_iType[id] ? "weapon_gungnirex" : "weapon_gungnir")
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
	if(!Stock_Can_Attack())
		return HAM_IGNORED
		
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_GUNGNIREX)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_GUNGNIREX, bpammo - temp1)		
		
		fInReload = 0
		set_pdata_int(ent, 54, fInReload, 4)
		set_pdata_float(ent, 46, 0.01, 4)
	}	
	
	new iCharge = pev(ent, pev_iuser1)
	new iState = pev(ent, pev_iuser2)
	
	if(!iCharge && !iState) 
	{
		if(g_fIdleSound[id] < get_gametime())
		{
			emit_sound(id, CHAN_WEAPON, SOUND_FIRE[7], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			g_fIdleSound[id] = get_gametime() + 1.0
		}
		
		if(get_pdata_float(ent, 48, 4) <= 0.0)
		{
			Set_WeaponAnim(id, 0)
			set_pdata_float(ent, 48, 3.03, 4)
		}
	}	
	
	WE_GUNGNIR(id, ent, iClip,bpammo,pev(id, pev_button))
	return HAM_IGNORED
}

public WE_GUNGNIR(id,iEnt,iClip, bpammo,iButton)
{
	new Float:flNextPrimaryAttack, Float:fCurTime, iState, Float:fSound, iCharge
	global_get(glb_time, fCurTime)
	pev(iEnt, pev_fuser1, fSound)
	pev(iEnt, pev_fuser2, flNextPrimaryAttack)
	iCharge = pev(iEnt, pev_iuser1)
	iState = pev(iEnt, pev_iuser2)
	new pEntity = -1
		
	if((!(iButton & IN_ATTACK) || !iClip) && iState == 1)
	{
		Set_WeaponAnim(id, ANIM_SHOOT_END)
		
		set_pdata_float(iEnt, 46, 0.33, 4)
		set_pdata_float(iEnt, 48, 0.33, 4)
		set_pev(iEnt, pev_iuser2, 0)
		
		emit_sound(id, CHAN_WEAPON, SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	
	if(!(iButton & IN_ATTACK2) && 0 < iCharge < 3)
	{
		new bool:iMax = (iCharge == 2) ? true : false
		
		if(iMax && get_pdata_float(iEnt, 46, 4) > 0.0)
			return
		
		static Float:vOrigin[3], Float:vVAngles[3], Float:vVec[3],Float:vAngle[3],Float:vecEnd2[3]
		engfunc(EngFunc_GetAttachment, id, 1, vOrigin, vAngle)
		pev(id, pev_v_angle, vVAngles);
	
		Stock_Get_Aiming(id, vecEnd2)
		Stock_GetSpeedVector(vOrigin, vecEnd2, iMax ? 500.0 : 1500.0, vVec)
		
		vector_to_angle(vVec, vVAngles)
		if(vVAngles[0] > 90.0) vVAngles[0] = -(360.0 - vVAngles[0])
		
		new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		engfunc(EngFunc_SetModel, pEntity, g_iType[id] ? EXP_MODELS_EX[iMax?7:5] : EXP_MODELS[iMax?7:5]);
		engfunc(EngFunc_SetSize, pEntity, Float:{-0.5, -0.5, 0.5}, Float:{0.5, 0.5, 0.5})
		
		set_pev(pEntity, pev_classname, "gungnir_plasma");
		set_pev(pEntity, pev_movetype, MOVETYPE_FLY);
		set_pev(pEntity, pev_angles, vVAngles);
		set_pev(pEntity, pev_origin, vOrigin);
		set_pev(pEntity, pev_gravity, 0.01);
		set_pev(pEntity, pev_owner, id);
		set_pev(pEntity, pev_solid, SOLID_BBOX);
		set_pev(pEntity, pev_velocity, vVec);
		set_pev(pEntity, pev_vuser3, vVec);
		
		set_pev(pEntity, pev_frame, 0.0)
		set_pev(pEntity, pev_framerate, 1.0)
		set_pev(pEntity, pev_iuser1, iMax?1:0)
		
		if(!iMax) 
		{
			set_pev(pEntity, pev_renderamt, 255.0)
			set_pev(pEntity, pev_rendermode, kRenderTransAdd)
			set_pev(pEntity, pev_scale, 0.1)
		}
		
		if(iMax) 
		{
			set_pev(pEntity, pev_vuser1, vOrigin)
			set_pev(pEntity, pev_vuser2, vecEnd2)
			set_pev(pEntity, pev_fuser3, 500.0)
		}
		
		set_pev(pEntity, pev_nextthink, get_gametime()+0.01)
		
		Set_WeaponAnim(id, iMax?ANIM_SHOOT2_SHOTCHARGE:ANIM_SHOOT2)
		emit_sound(id, CHAN_WEAPON, SOUND_FIRE[iMax?3:2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		if(g_iType[id] && iClip >= 6) iClip -= 6
		else if(!g_iType[id] && iClip >= 5) iClip -= 5
		else iClip = 0
		set_pdata_int(iEnt, 51, iClip, 4)
		
		set_pdata_float(iEnt, 46, iMax?3.13:0.5, 4)
		set_pdata_float(iEnt, 48, iMax?3.5:0.75, 4)
		
		Stock_SetPlayerAnim(id, iMax?"shoot_grenade":"shoot_m249")
		set_pev(id, pev_weaponmodel2, "")
		set_pev(iEnt, pev_iuser1, iMax?3:0)
		
		if(iMax) set_pev(iEnt, pev_fuser3, fCurTime + 0.33)
		g_fIdleSound[id] = get_gametime() + (iMax?3.5:0.75)
	}
	
	if(iCharge == 3 && fSound < fCurTime)
	{
		Stock_SetPlayerAnim(id, "aim_m249")
		set_pev(id, pev_weaponmodel2, g_iType[id] ? P_GUNGNIREX : P_GUNGNIR)
		set_pev(iEnt, pev_iuser1, 0)
	}
			
	if(get_pdata_float(iEnt, 46, 4) > 0.0)
		return
	
	if(iButton & IN_ATTACK && iClip)
	{
		if(fSound < fCurTime)
		{
			emit_sound(id, CHAN_WEAPON, SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			set_pev(iEnt, pev_fuser1, fCurTime + 1.0)
		}
		
		if(!iState)
		{
			Set_WeaponAnim(id, ANIM_SHOOT_START)
			
			set_pdata_float(iEnt, 46, 0.23, 4)
			set_pdata_float(iEnt, 48, 0.23, 4)
			set_pev(iEnt, pev_iuser2, 1)
		}
		
		if(iState == 1)
		{
			iClip--
			set_pdata_int(iEnt, 51, iClip, 4)
			
			set_pdata_float(iEnt, 46, SPEED, 4)
			set_pdata_float(iEnt, 48, SPEED + 0.5, 4)
			
			MakeMuzzleFlash(id, iEnt)
			Set_WeaponAnim(id, ANIM_SHOOT_LOOP)
			Stock_SetPlayerAnim(id, "shoot_m249")
			
			if(flNextPrimaryAttack > fCurTime)
				return
	
			set_pev(iEnt, pev_fuser2, fCurTime + 0.01)
			
			new Float:fOrigin[3], Float:fEnd[3], Float:LOL[3][3]
			pev(id, pev_origin, fOrigin)
			Stock_Get_Postion(id, 128.0, 0.0, 0.0, fEnd)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMENTPOINT)
			write_short(id | 0x1000)
			engfunc(EngFunc_WriteCoord, fEnd[0])
			engfunc(EngFunc_WriteCoord, fEnd[1])
			engfunc(EngFunc_WriteCoord, fEnd[2])
			write_short(g_cache_light[g_iType[id]])
			write_byte(0) // framerate
			write_byte(0) // framerate
			write_byte(1) // life
			write_byte(40)  // width
			write_byte(10)// noise
			write_byte(g_iType[id] ? 255 : 26)// r
			write_byte(g_iType[id] ? 55 : 164)// g
			write_byte(g_iType[id] ? 16 : 255)// b
			write_byte(255)	// brightness
			write_byte(255)	// speed
			message_end()
			
			while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, fOrigin, ELECTRO_RANGE)) != 0)
			{
				if(pev(pEntity, pev_takedamage) == DAMAGE_NO) continue
				if(is_user_connected(pEntity) && pEntity != id)
					if(!can_damage(pEntity, id)) continue
				if(pEntity == id) continue
				
				for(new k = 0; k < 3; k++)
				{
					if(k == 1 && pEntity == g_iVic[0])  continue
					if(k == 2 && (pEntity == g_iVic[0] || pEntity == g_iVic[1]))  continue
				
					if(pev_valid(pEntity))
					{
						new Float:tempOrigin[3]
						pev(pEntity, pev_origin, tempOrigin)
						
						if(get_distance_f(fOrigin, tempOrigin) < ELECTRO_RANGE)
							g_iVic[k] = pEntity
					}
				
					pev(g_iVic[k], pev_origin, LOL[k])
					
					if(is_user_alive(g_iVic[k]) && can_damage(id, g_iVic[k]) && entity_range(id, g_iVic[k]) < ELECTRO_RANGE && !Stock_Blah(fOrigin, LOL[k], id))
					{
						engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
						write_byte(TE_EXPLOSION)
						engfunc(EngFunc_WriteCoord, LOL[k][0])
						engfunc(EngFunc_WriteCoord, LOL[k][1])
						engfunc(EngFunc_WriteCoord, LOL[k][2] - 15.0)
						write_short(g_cache_hit[g_iType[id]])
						write_byte(1)
						write_byte(60)
						write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
						message_end()
						
						engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
						write_byte(TE_BEAMPOINTS)
						engfunc(EngFunc_WriteCoord, LOL[k][0])
						engfunc(EngFunc_WriteCoord, LOL[k][1])
						engfunc(EngFunc_WriteCoord, LOL[k][2])
						engfunc(EngFunc_WriteCoord, fEnd[0])
						engfunc(EngFunc_WriteCoord, fEnd[1])
						engfunc(EngFunc_WriteCoord, fEnd[2])
						write_short(g_cache_light[g_iType[id]])
						write_byte(0)		// byte (starting frame) 
						write_byte(10)		// byte (frame rate in 0.1's) 
						write_byte(1)		// byte (life in 0.1's) 
						write_byte(55)		// byte (line width in 0.1's) 
						write_byte(17)		// byte (noise amplitude in 0.01's) 
						write_byte(g_iType[id] ? 255 : 26)// r
						write_byte(g_iType[id] ? 55 : 164)// g
						write_byte(g_iType[id] ? 16 : 255)// b
						write_byte(255)		// byte (brightness)
						write_byte(10)		// byte (scroll speed in 0.1's)
						message_end()
						
						ExecuteHamB(Ham_TakeDamage, g_iVic[k], id, id, ELECTRO_DAMAGE, DMG_SHOCK)
						
						if(1 <= g_iVic[k] <= 32)
						{
							new Float:vAttacker[3], Float:vVictim[3]
							pev(id, pev_origin, vAttacker)
							pev(g_iVic[k], pev_origin, vVictim)
							xs_vec_sub(vVictim, vAttacker, vVictim)
							
							new Float:fDistance
							fDistance = xs_vec_len(vVictim)
							xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
							xs_vec_mul_scalar(vVictim, ELECTRO_KNOCKBACK, vVictim)
							set_pev(g_iVic[k], pev_velocity, vVictim)
							
							SpawnBlood(LOL[k], get_pdata_int(g_iVic[k],89), floatround(ELECTRO_DAMAGE))
						}
					}
				}
			}
		}
	}
	
	if(iButton & IN_ATTACK2 && iClip)
	{
		if(flNextPrimaryAttack > fCurTime)
			return
		
		switch(iCharge)
		{
			case 0:
			{
				set_pdata_float(iEnt, 46, 0.5, 4)
				
				set_pev(iEnt, pev_fuser2, fCurTime + 0.5)
				set_pev(iEnt, pev_iuser1, 1)
			}
			case 1:
			{
				Set_WeaponAnim(id, ANIM_SHOOT2_CHARGE)
				set_pdata_float(iEnt, 46, 2.03, 4)
				set_pdata_float(iEnt, 48, 2.1, 4)
				
				set_pev(iEnt, pev_fuser2, fCurTime + 2.03)
				set_pev(iEnt, pev_iuser1, 2)
			}
			case 2:
			{
				Set_WeaponAnim(id, ANIM_CHARGE_LOOP)
				set_pdata_float(iEnt, 48, 2.03, 4)
				set_pev(iEnt, pev_fuser2, fCurTime + 2.03)
				set_pev(iEnt, pev_iuser1, 2)
				
				set_pev(id, pev_weaponmodel2, g_iType[id] ? P_GUNGNIREX2 : P_GUNGNIR2)
				Stock_SetPlayerAnim(id, "aim_grenade")
			}
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
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_GUNGNIREX)
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
	
	Set_WeaponAnim(id, ANIM_RELOAD)
	Set_PlayerNextAttack(id, RELOAD_TIME)
	Set_WeaponIdleTime(id, CSW_GUNGNIREX,RELOAD_TIME)
	Stock_SetPlayerAnim(id, "reload_m249")
	return HAM_IGNORED
}

/* ===============================
------------- ENTITIES --------
=================================*/
public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "gungnir_mf"))
	{
		static Float:fFrame, Float:fFrameMax, id
		pev(ent, pev_frame, fFrame)
		id = pev(ent, pev_owner)
		
		fFrameMax = g_cache_frame_mf[g_iType[id]]
		
		fFrame += 1.0
		set_pev(ent, pev_frame, fFrame)
		
		if(fFrame >= fFrameMax) 
		{
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
			return
		}
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
		return
	}
}

public HamF_InfoTarget_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "gungnir_plasma"))
		return
		
	new iOwner, iState
	iOwner = pev(iEnt, pev_owner)
	iState = pev(iEnt, pev_iuser1)
	
	if(!iState)
	{
		static Float:fFrame
		pev(iEnt, pev_frame, fFrame)
		
		fFrame += 1.0
		if(fFrame >= 10.0) fFrame = 0.0
		
		set_pev(iEnt, pev_frame, fFrame)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	}
	
	if(iState)
	{
		new Float:vecOri[3], Float:vEnd[3], Float:vVec[3], Float:vecEnd2[3], Float:fSpeed;
		pev(iEnt, pev_vuser1, vecOri)
		pev(iEnt, pev_vuser2, vecEnd2)
		pev(iEnt, pev_vuser3, vVec)
		pev(iEnt, (iState == 2) ? pev_vuser2 : pev_origin, vEnd)
		pev(iEnt, pev_fuser3, fSpeed)
		
		// no more misdirection, but may will give an awkward result due to goldsrc limit,
		// at least will absolutely goes to aim origin (or perhaps my code is wrong? idk)
		static Float:vAngle[3]
		Stock_GetSpeedVector(vEnd, vecEnd2, fSpeed, vVec)
		Stock_Get_Velocity_Angle(iEnt, vAngle)
		set_pev(iEnt, pev_angles, vAngle)
		
		fSpeed = (fSpeed >= 2200.0) ? 2200.0 : (fSpeed + 100.0)
		set_pev(iEnt, pev_fuser3, fSpeed)
		
		//client_print(0, print_chat, "%f", fSpeed)
		
		if(iState == 2) set_pev(iEnt, pev_origin, vEnd)
		if(iState == 1) 
		{
			set_pev(iEnt, pev_velocity, vVec)
			
			new pEntity =  pev(iEnt, pev_enemy)
			
			if(is_valid_ent(pEntity) && is_user_alive(pEntity)) 
				set_pev(pEntity, pev_velocity, vVec)
		}
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOri, 0)
		write_byte(TE_BEAMPOINTS)
		engfunc(EngFunc_WriteCoord, vecOri[0]) // start
		engfunc(EngFunc_WriteCoord, vecOri[1])
		engfunc(EngFunc_WriteCoord, vecOri[2])
		engfunc(EngFunc_WriteCoord, vEnd[0]) // end
		engfunc(EngFunc_WriteCoord, vEnd[1])
		engfunc(EngFunc_WriteCoord, vEnd[2])
		write_short(g_cache_beam[g_iType[iOwner]][iState-1])
		write_byte(0)		// byte (starting frame) 
		write_byte(500)		// byte (frame rate in 0.1's) 
		write_byte(1)		// byte (life in 0.1's) 
		write_byte((iState==2)?150:50)		// byte (line width in 0.1's) 
		write_byte(0)		// byte (noise amplitude in 0.01's) 
		write_byte(200)		// byte,byte,byte (color) (R)
		write_byte(g_iType[iOwner] ? 55 : 200)		// (G)
		write_byte(g_iType[iOwner] ? 20 : 200)		// (B)
		write_byte(g_iType[iOwner] ? 200 : 75)		// byte (brightness)
		write_byte((iState==2)?30:10)		// byte (scroll speed in 0.1's)
		message_end()
		
		static Float:fTimeRemove, Float:fDelay; 
		pev(iEnt, pev_ltime, fTimeRemove)
		pev(iEnt, pev_fuser4, fDelay)
		
		if(get_gametime() >= fDelay && pev(iEnt, pev_iuser4) == 1) 
		{
			static Float:vVec[3]
			Stock_GetSpeedVector(vecOri, vecEnd2, 5000.0, vVec)
			
			static iBall
			iBall = Stock_CreateEntityBase(iOwner, "info_target", MOVETYPE_FLY, "models/w_usp.mdl", "gungnir_plasma", SOLID_TRIGGER, 0.01)
			engfunc(EngFunc_SetSize, iBall, Float:{-50.0, -50.0, 0.0}, Float:{50.0, 50.0, 50.0})
			fm_set_rendering(iBall, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
			
			static Float:vAngle[3]
			Stock_Get_Velocity_Angle(iBall,vAngle)
			set_pev(iBall, pev_angles,vAngle)
			set_pev(iBall, pev_origin, vecOri)
			set_pev(iBall, pev_gravity, 0.01)
			set_pev(iBall, pev_velocity, vVec)
			set_pev(iBall, pev_iuser1, 2)
			set_pev(iBall, pev_vuser1, vecOri)
			set_pev(iBall, pev_vuser2, vecEnd2)
			
			// sometimes not triggers HamF_InfoTarget_Touch function, dont know why :/
			// give a lil bit of extra time, to prevent crash with default timer
			set_task(2.55, "FuckingRemoveYouBITCH", iBall)
			
			emit_sound(iOwner, CHAN_VOICE, SOUND_FIRE[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			set_pev(iEnt, pev_iuser4, 0)
		}
		
		if(get_gametime() >= fTimeRemove && pev(iEnt, pev_iuser3)) 
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return
		}
		
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	}
}

public HamF_InfoTarget_Touch(iEnt, iPtd)
{
	if(!pev_valid(iEnt))
		return HAM_IGNORED
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "gungnir_plasma"))
		return HAM_IGNORED
		
	new iOwner, Float:vecOri[3], iState
	iOwner = pev(iEnt, pev_owner)
	iState = pev(iEnt, pev_iuser1)
	pev(iEnt, pev_origin, vecOri)
	
	if(iPtd == iOwner)
		return HAM_IGNORED
		
	static Float:fDmg, Float:fRng, Float:fKnc
	if(!iState)
	{
		fDmg = WDAMG_PLASMA
		fRng = WRANGE_PLASMA
		fKnc = 1.0
	} else if(iState == 1) {
		fDmg = WDAMG_CHARGE
		fRng = WRANGE_CHARGE
		fKnc = 1.0 
	} else if(iState == 2) {
		fDmg = WDAMG_BEAM
		fRng = WRANGE_BEAM
		fKnc = 1.0
	}
	
	new pEntity = -1
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOri, fRng)) != 0)
	{
		if(pev(pEntity, pev_takedamage) == DAMAGE_NO) continue
		if(is_user_connected(pEntity) && pEntity != iOwner)
			if(!can_damage(pEntity, iOwner)) continue
		if(pEntity == iOwner) continue
		
		if(pev_valid(pEntity))
		{
			ExecuteHamB(Ham_TakeDamage, pEntity, iOwner, iOwner, fDmg, DMG_BULLET)
			
			Stock_Fake_KnockBack(iOwner, pEntity, fKnc)
			if(is_user_alive(pEntity)) SpawnBlood(vecOri, get_pdata_int(pEntity,89), floatround(fDmg/5.0))
		}
	}
	
	if(iState < 2) 
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOri, 0)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, vecOri[0])
		engfunc(EngFunc_WriteCoord, vecOri[1])
		engfunc(EngFunc_WriteCoord, vecOri[2])
		write_short(g_cache_exp[g_iType[iOwner]][iState])
		write_byte(10)
		write_byte(30)
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
		message_end()
		
		emit_sound(iOwner, CHAN_VOICE, SOUND_FIRE[4+iState], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		if(!iState) engfunc(EngFunc_RemoveEntity, iEnt)
		else if(iState == 1)
		{
			if(is_valid_ent(iPtd) && is_user_alive(iPtd)) set_pev(iEnt, pev_enemy, iPtd)
	
			Func_iEntAttrib(iEnt)
			
			fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
			set_pev(iEnt, pev_fuser3, 0.0)
			set_pev(iEnt, pev_fuser4, get_gametime() + 1.0)
			set_pev(iEnt, pev_iuser4, 1)
		}
	}
	
	if(iState == 2) Func_iEntAttrib(iEnt)
	return HAM_IGNORED
}

public FuckingRemoveYouBITCH(iEnt) if(pev_valid(iEnt)) engfunc(EngFunc_RemoveEntity, iEnt)

public Func_iEntAttrib(iEnt)
{
	set_pev(iEnt, pev_ltime, get_gametime() + 2.5)
	set_pev(iEnt, pev_iuser3, 1)
	set_pev(iEnt, pev_movetype, MOVETYPE_NONE);
	set_pev(iEnt, pev_solid, SOLID_NOT);
}

public MakeMuzzleFlash(id, iEnt)
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, g_iType[id] ? MF_W_EX : MF_W, "gungnir_mf", SOLID_NOT,0.01)
	set_pev(iMuz, pev_body, 1)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.04)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
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

stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
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

stock Float:Stock_Blah(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()
	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return get_distance_f(end, EndPos)
} 
stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
stock Stock_Get_Velocity_Angle(entity, Float:output[3])
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	vector_to_angle(velocity, output)
	if( output[0] > 90.0 ) output[0] = -(360.0 - output[0])
}
////////////////////////////
public Set_WpnList(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(Get_BitVar(g_Had_Base, id) ? "weapon_gungnirex" : weapon_gungnirex)
	write_byte(6)
	write_byte(100)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(13)
	write_byte(CSW_GUNGNIREX)
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

stock Stock_SetPlayerAnim(id, const AnimName[], Float:rate=1.0)
{
	static AnimNum, Float:FrameRate, Float:GroundSpeed, bool:Loops, Anim2[64]
	if(!(pev(id, pev_flags) & FL_DUCKING)) format(Anim2, 63, "ref_%s", AnimName)
	else format(Anim2, 63, "crouch_%s", AnimName)

	if ((AnimNum=lookup_sequence(id,Anim2,FrameRate,Loops,GroundSpeed))==-1) AnimNum=0
	
	if (!Loops || (Loops && pev(id,pev_sequence)!=AnimNum))
	{
		set_pev(id, pev_gaitsequence, AnimNum)
		set_pev(id, pev_sequence, AnimNum)
		set_pev(id, pev_frame, 0.0)
		set_pev(id, pev_animtime, get_gametime())
	}
	set_pev(id, pev_framerate, rate)

	set_pdata_int(id, 40, Loops, 4)
	set_pdata_int(id, 39, 0, 4)

	set_pdata_float(id, 36, FrameRate, 4)
	set_pdata_float(id, 37, GroundSpeed, 4)
	set_pdata_float(id, 38, get_gametime(), 4)

	set_pdata_int(id, 73, 28, 5)
	set_pdata_int(id, 74, 28, 5)
	set_pdata_float(id, 220, get_gametime(), 5)
}

stock SpawnBlood(const Float:vecOrigin[3], iColor, iAmount)
{
	if(!iAmount)
		return
	
	iAmount *= 2
	if(iAmount > 255) iAmount = 255
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(g_SpraySpr)
	write_short(g_DropSpr)
	write_byte(iColor)
	write_byte(min(max(3, iAmount / 10), 16))
	message_end()
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

stock Stock_Get_Postion(id,Float:forw, Float:right, Float:up, Float:vStart[])
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

stock Stock_Can_Attack()
{
	if(g_freezetime) return 0
	return 1
}

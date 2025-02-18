#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <orpheu>

// just comment code below (by adding double slash at very front of each line) or delete any 'mdcsohud_' and 'metadrawer' code
#define LIBRARY_MD "metadrawer"
#include <md_csohud>

// No need to separate plugin for normal and ZP anymore! One for all!
#define LIBRARY_ZP "zp50_core"
#include <zombieplague>

#define PLUGIN "AMXX Dual Beretta"
#define VERSION "5.1"
#define AUTHOR "Asdian"

// Data Config
#define P_GUNKATA_M "models/p_gunkata.mdl"
#define P_GUNKATA_W "models/p_gunkata2.mdl"
#define V_GUNKATA "models/v_gunkata.mdl"
#define W_GUNKATA "models/w_gunkata.mdl"

#define P_GUNKATAGS_M "models/p_gunkatapaintgs18.mdl"
#define P_GUNKATAGS_W "models/p_gunkatapaintgs18_2.mdl"
#define V_GUNKATAGS "models/v_gunkatapaintgs18.mdl"
#define W_GUNKATAGS "models/w_gunkatapaintgs18.mdl"

#define MODEL_BLAST "models/ef_scorpion_hole.mdl"
#define MODEL_SHADOW "models/ef_gunkata_man.mdl"
#define MODEL_MF "sprites/muzzleflash77.spr"

#define MODEL_W_OLD "models/w_deagle.mdl"
#define SOUND_FIRE "weapons/gunkata-1.wav"

#define CSW_GUNKATA CSW_DEAGLE
#define weapon_gunkata "weapon_deagle"

#define WEAPON_CODE 1182018
#define WEAPON_EVENT "events/deagle.sc"
#define WEAPON_SPR "weapon_gunkata"

enum _:NewAnim
{
	anim_idle = 0,
	anim_idle2,
	anim_shoot,
	anim_shoot_last,
	anim_shoot2,
	anim_shoot2_last,
	anim_reload,
	anim_reload2,
	anim_draw,
	anim_draw2,
	anim_skill01, //10
	anim_skill02,
	anim_skill03,
	anim_skill04,
	anim_skill05,
	anim_skill_last
}

new const SkillSounds[][] = 
{
	"weapons/gunkata_skill_01.wav",  //0
	"weapons/gunkata_skill_02.wav",  //1
	"weapons/gunkata_skill_03.wav",  //2
	"weapons/gunkata_skill_04.wav",  //3
	"weapons/gunkata_skill_05.wav",  //4
	"weapons/gunkata_skill_last_exp.wav",  //5
	"weapons/turbulent9_hit1.wav",
	"weapons/turbulent9_hit2.wav"
}

// Weapon Config
#define DAMAGE 70
#define ACCURACY 23 // 0 - 100 ; -1 Default
#define CLIP 36
#define BPAMMO 180
#define SPEED 0.0692
#define RECOIL 0.5
#define RELOAD_TIME 2.03

#define SKILL_ROF 0.095
#define SKILL_DAMAGE 80.0
#define SKILL_RANGE 150.0
#define SKILL_ANGLE 179.9
#define SKILL_KNOCKBACK 250.0

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_special[33], g_switch[33], g_Had_Base, g_Clip[33], g_OldWeapon[33], Float:g_Recoil[33][3]
new g_Event_Base, g_SmokePuff_SprId, g_Dprd, cvar_shadow, cvar_mode

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
	register_forward(FM_Think, "fw_MF_Think")
	register_forward(FM_AddToFullPack, "Fw_AddToFullPack_Post", 1);

	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_gunkata, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_gunkata, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_gunkata, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_gunkata, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_gunkata, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_gunkata, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_gunkata, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_gunkata, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_Think, "info_target", "Fw_DBGEnt_Think")
	
	// Cache
	if (LibraryExists(LIBRARY_ZP, LibType_Library))
		g_Dprd = zp_register_extra_item("Dual Berreta Gunslinger", 10, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR)
	else
		register_clcmd("gipdbg", "Get_Base");
	
	cvar_shadow = register_cvar("dbg_show_shadow", "0")
	cvar_mode = register_cvar("dbg_usegs_paint", "1")
	
	register_clcmd(WEAPON_SPR, "hook_weapon")
}

public hook_weapon(id) engclient_cmd(id, weapon_gunkata)

public plugin_precache()
{
	precache_model(P_GUNKATA_M)
	precache_model(P_GUNKATA_W)
	precache_model(V_GUNKATA)
	precache_model(W_GUNKATA)
	
	precache_model(P_GUNKATAGS_M)
	precache_model(P_GUNKATAGS_W)
	precache_model(V_GUNKATAGS)
	precache_model(W_GUNKATAGS)
	
	precache_model(MODEL_SHADOW)
	precache_sound(SOUND_FIRE)
	
	for(new i=0; i<sizeof(SkillSounds); i++)
		precache_sound(SkillSounds[i])
	
	precache_model(MODEL_BLAST)
	precache_model(MODEL_MF)
	
	new Txt[32]
	format(Txt, 31, "sprites/%s.txt", WEAPON_SPR)
	engfunc(EngFunc_PrecacheGeneric, Txt)
	
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "deagle"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_GUNKATA || !Get_BitVar(g_Had_Base, id))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "gunkata")
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
public client_disconnected(id) Safety_Disconnected(id)

public zp_extra_item_selected(i, d) if(d == g_Dprd) Get_Base(i)
public zp_user_infected_post(i) Remove_Base(i)
public zp_user_humanized_post(i) Remove_Base(i)

public Get_Base(id)
{
	Set_BitVar(g_Had_Base, id)
	g_special[id] = 0
	g_switch[id] = 0
	
	Stock_Drop_Slot(id,2)
	fm_give_item(id, weapon_gunkata)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_GUNKATA)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_GUNKATA, BPAMMO)
	
	ExecuteHamB(Ham_Item_Deploy, Ent)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_GUNKATA)
	write_byte(cs_get_weapon_ammo(Ent))
	message_end()
}

public Remove_Base(id)
{
	UnSet_BitVar(g_Had_Base, id)
	g_special[id] = 0
	g_switch[id] = 0
	
	if(LibraryExists(LIBRARY_MD, LibType_Library)) 
		mdcsohud_resetwpnhud(id, CSW_GUNKATA)
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_GUNKATA && g_OldWeapon[id] != CSW_GUNKATA) && Get_BitVar(g_Had_Base, id))
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_GUNKATA && g_OldWeapon[id] == CSW_GUNKATA) && Get_BitVar(g_Had_Base, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_GUNKATA)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
		if(g_special[id])
			return
		
		set_pdata_float(Ent, 46, SPEED, 4)
		set_pdata_float(Ent, 47, SPEED, 4)
	} else if(CSWID != CSW_GUNKATA && g_OldWeapon[id] == CSW_GUNKATA) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_GUNKATA)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_GUNKATA)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_GUNKATA)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_GUNKATA && Get_BitVar(g_Had_Base, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_GUNKATA || !Get_BitVar(g_Had_Base, invoker))
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
		static weapon; weapon = find_ent_by_owner(-1, weapon_gunkata, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, get_pcvar_num(cvar_mode) ? W_GUNKATAGS : W_GUNKATA)

			Remove_Base(iOwner)
			set_pev(weapon, pev_iuser2, 0)
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
	
	new iMode = Stock_Gunkata_Mode(Ent)
	set_pev(Id, pev_viewmodel2, get_pcvar_num(cvar_mode) ? V_GUNKATAGS:V_GUNKATA)
	set_pev(Id, pev_weaponmodel2, get_pcvar_num(cvar_mode) ? (iMode?P_GUNKATAGS_W:P_GUNKATAGS_M) : (!iMode?P_GUNKATA_W:P_GUNKATA_M))
	Set_WeaponAnim(Id, iMode?anim_draw2 : anim_draw)
		
	if(LibraryExists(LIBRARY_MD, LibType_Library)) 
		mdcsohud_regwpnhud(Id, CSW_GUNKATA, WEAPON_SPR)
	
	set_pev(Ent, pev_iuser1, 0)
	set_pev(Ent, pev_iuser2, 0)
	set_pev(Ent, pev_iuser3, 0)
	
	g_special[Id] = 0
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
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(Get_BitVar(g_Had_Base, id) ? WEAPON_SPR : weapon_gunkata)
	write_byte(8)
	write_byte(35)
	write_byte(-1)
	write_byte(-1)
	write_byte(1)
	write_byte(1)
	write_byte(CSW_GUNKATA)
	write_byte(0)
	message_end()
	
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
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_GUNKATA)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_GUNKATA, bpammo - temp1)		
		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
		g_switch[id] = 0
	}
	WE_GUNKATA(id, ent, pev(id, pev_button))
	return HAM_IGNORED
}

public WE_GUNKATA(id, Ent, iButton)
{
	new iClip = get_pdata_int(Ent, 51, 4)
	new iCurAnim = pev(Ent, pev_iuser1)
	new iAnimMod = pev(Ent, pev_iuser2)
	new iSetAnim = pev(Ent, pev_iuser3)
	new Float:fSound; pev(Ent, pev_fuser1, fSound)
	new Float:fRofClip; pev(Ent, pev_fuser2, fRofClip)
	new iMode = Stock_Gunkata_Mode(Ent)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_GUNKATA)
	
	if(fSound && fSound < get_gametime() && g_special[id] == 2)
	{
		Gunkata_Blast(id)
		
		new pEntity = -1;
		new Float:vecOrigin[3]; pev(id, pev_origin, vecOrigin)
		
		while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, SKILL_RANGE)) != 0)
		{
			if (!pev_valid(pEntity))
				continue;
			if (id == pEntity)
				continue;
			if (!IsAlive(pEntity) || !can_damage(id, pEntity))
				continue;
			
			Stock_Fake_KnockBack(id, pEntity, SKILL_KNOCKBACK)
		}
		
		emit_sound(id, CHAN_VOICE, SkillSounds[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		set_pdata_float(id, 83, 0.97, 5)
		set_pdata_int(Ent, 54, 1, 4)
		
		set_pev(Ent, pev_fuser1, 0.0)
		g_special[id] = 3
	}
	
	if((iButton & IN_ATTACK2) && g_special[id] != 3)
	{
		if(iClip <= 0 && g_special[id] == 1)
		{
			set_pev(Ent, pev_fuser1, get_gametime() + 0.66)
			
			if(get_pdata_float(Ent, 46, 4) > 0.0)
				return
			
			Set_WeaponAnim(id, anim_skill_last)
			set_pdata_float(Ent, 46, 1.57, 4)
			set_pdata_float(Ent, 47, 1.57, 4)
			set_pdata_float(Ent, 48, 1.57, 4)
			
			set_pev(Ent, pev_iuser2, 0)
			set_pev(Ent, pev_iuser3, 0)
			
			g_special[id] = 2
			return
		}
		
		if(get_pdata_float(Ent, 47, 4) <= 0.0 && iClip)
		{
			set_pdata_float(Ent, 47, SKILL_ROF, 4)
			
			new iHit = KnifeAttack2(id, 0, SKILL_RANGE, SKILL_ANGLE, SKILL_DAMAGE, 0.01)
			if(iHit == RESULT_HIT_PLAYER) emit_sound(id, CHAN_WEAPON, SkillSounds[random_num(6,7)], 0.56, ATTN_NORM, 0, PITCH_NORM)
		}
		
		if(fRofClip < get_gametime() && iClip > 0)
		{
			set_pdata_int(Ent, 51, iClip - 1, 4)
			set_pev(Ent, pev_fuser2, get_gametime() + 0.1)
		}
		
		if(get_pdata_float(Ent, 46, 4) > 0.0 || (!iBpAmmo && !iClip))
			return
		
		new Float:fDelay
		switch(iAnimMod) // prevent duplicating anim too often
		{
			case 0..1:  
			{
				new iAnim = random_num(anim_skill01,anim_skill05)
				if(iAnim == iSetAnim)
				{
					if(iAnim == anim_skill05) iAnim = iAnim - 1
					else iAnim = iAnim + 1
				}
				
				if(iAnim == 10 || iAnim == 11) fDelay = 0.7
				else if(iAnim == 12) MakeMuzzleFlash(id, 1)
				else fDelay = 1.03
				
				Set_WeaponAnim(id, iAnim)
				set_pev(Ent, pev_iuser3, iAnim)
			}
			case 2..9:
			{
				iCurAnim++
				if(iCurAnim > 4) iCurAnim = 0
				set_pev(Ent, pev_iuser1, iCurAnim)
				
				if(iCurAnim == 1 || iCurAnim == 2) fDelay = 0.7
				else if(iCurAnim == 3) MakeMuzzleFlash(id, 1)
				else fDelay = 1.03
				
				new iAnim = 10 + iCurAnim
				if(iAnim == iSetAnim)
				{
					if(iAnim == anim_skill05) iAnim = iAnim - 1
					else iAnim = iAnim + 1
				}
				DBG_Specials(Ent, id, iAnim, get_gametime() + 2.5)
				set_pev(Ent, pev_iuser3, iAnim)
			}
		}
		
		if(get_pcvar_num(cvar_shadow))
		{
			new bool:duck = (pev(id, pev_flags) & FL_DUCKING)?true:false
			DBG_Shadow(id, duck ? iCurAnim + 6 : iCurAnim)
		}
		client_cmd(id, "spk %s", SkillSounds[iCurAnim])
		
		set_pdata_float(Ent, 46, random_float(0.21,0.24), 4)
		set_pdata_float(Ent, 48, fDelay, 4)
		
		g_special[id] = 1
		set_pev(Ent, pev_iuser2, random(9))
	}
	
	if((!(iButton & IN_ATTACK2) && g_special[id] == 1) || g_special[id] == 3)
	{
		if(get_pdata_float(Ent, 46, 4) > 0.0)
			return
		
		Set_WeaponAnim(id, iMode ? anim_draw2 : anim_draw)
		
		new Float:fDelay = (g_special[id] == 3?0.5:1.0)
		set_pdata_float(id, 83, fDelay, 5)
		set_pdata_float(Ent, 46, fDelay, 4)
		set_pdata_float(Ent, 47, fDelay, 4)
		set_pdata_float(Ent, 48, fDelay, 4)
		
		set_pev(Ent, pev_iuser2, 0)
		set_pev(Ent, pev_iuser3, 0)
		g_special[id] = 0
	}
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	if(g_special[id])
		return HAM_SUPERCEDE
		
	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_GUNKATA)
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
	if(g_special[id])
		return HAM_SUPERCEDE
	
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	new iMode = Stock_Gunkata_Mode(ent)
	Set_WeaponAnim(id, iMode?anim_reload2:anim_reload)
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
	
	if(get_pdata_float(iEnt, 48, 4) <= 0.0)
	{
		new iMode = Stock_Gunkata_Mode(iEnt)
		Set_WeaponAnim(Id, iMode?anim_idle2:anim_idle)
		set_pdata_float(iEnt, 48, 20.0, 4)
	}
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_GUNKATA || !Get_BitVar(g_Had_Base, Attacker))
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
	if(get_player_weapon(Attacker) != CSW_GUNKATA || !Get_BitVar(g_Had_Base, Attacker))
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
	if(g_special[id])
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
	
	new iClip = get_pdata_int(Ent, 51, 4)
	new iMode = Stock_Gunkata_Mode(Ent)
	
	if(iClip) MakeMuzzleFlash(id, iMode?3:1)
	Gunkata_Shoot(Ent, id, iClip)
}

public Gunkata_Shoot(ent, id, iClip)
{
	new iMode = Stock_Gunkata_Mode(ent)
	
	if(!(iClip % 3))
	{
		if(!iClip && g_switch[id] == 2)
			return
		
		g_switch[id] = 1
		Set_WeaponAnim(id, iMode?anim_shoot_last:anim_shoot2_last)
		g_switch[id] = (!iClip)?2:0
		
		Set_PlayerNextAttack(id, 0.3)
		set_pdata_float(ent, 48, 0.5, 4)
	} else if(iClip) Set_WeaponAnim(id, iMode?anim_shoot2:anim_shoot)
}

public Stock_Gunkata_Mode(ent)
{
	new iClip = get_pdata_int(ent, 51, 4)
	
	// (CLIP - iClip) -> get amount current clip
	// (/3) -> current amout divided by 3 (because will change mode every 3 shot of interval)
	// (%2) -> divided result do modulation by 2
	// -> remainder result is the mode
	//
	// QUICK MAFS
	return (((CLIP - iClip) / 3) % 2);
}

/* ===============================
------------ ENITITES ------------
=================================*/
public Fw_AddToFullPack_Post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if (!pev_valid(iEnt))
		return;
	if (pev(iEnt, pev_flags) & FL_KILLME) 
		return;

	new classname[32], iOwner;
	pev(iEnt, pev_classname, classname, 31);
	iOwner = pev(iEnt, pev_owner)
	
	if (equal(classname,"dbg_entytyd") && g_special[iOwner])
		if (iHost != iOwner) set_es(esState, ES_Effects, (get_es(esState, ES_Effects) | EF_NODRAW));
}

public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "dbg_mf"))
	{
		set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
		return
	}
}

public Fw_DBGEnt_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
		
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "dbg_entytyd"))
		return
	
	new iOwner
	iOwner = pev(iEnt, pev_owner)
	
	if(!is_user_alive(iOwner) || !is_user_connected(iOwner) || (LibraryExists(LIBRARY_ZP, LibType_Library) && zp_get_user_zombie(iOwner)))
	{
		remove_entity(iEnt)
		return
	}
	
	new iMode
	iMode = pev(iEnt, pev_iuser1)
	
	if(!iMode)
	{
		new iWpn, Float:vecOrigin[3], Float:vecAngle[3];
		Stock_Get_Postion(iOwner, 0.0, 0.0, 0.0, vecOrigin);
		iWpn = pev(iEnt, pev_iuser2)
		
		pev(iOwner, pev_v_angle, vecAngle);
		vecAngle[0] = -vecAngle[0];
		
		set_pev(iEnt, pev_origin, vecOrigin);
		set_pev(iEnt, pev_angles, vecAngle);
		
		if(!pev_valid(iWpn))
			return
		
		if(get_user_weapon(iOwner) != CSW_GUNKATA)
		{
			set_pev(iWpn, pev_iuser2, 0)
			remove_entity(iEnt);
			return;
		}
		
		if(pev(iEnt, pev_fuser1) < get_gametime() || !IsAlive(iOwner))
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return
		}
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	} else if(iMode == 1) set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
	else if(iMode == 2)
	{
		new Float:fRenderAmount;
		pev(iEnt, pev_renderamt, fRenderAmount);
		fRenderAmount -= 3.5;
		
		if (fRenderAmount <= 0.0)
		{
			remove_entity(iEnt);
			return;
		}
		set_pev(iEnt, pev_renderamt, fRenderAmount);
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	}
}

public MakeMuzzleFlash(id, iAttach)
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, MODEL_MF, "dbg_mf", SOLID_NOT,0.15,Float:{0.0,0.0,0.0},Float:{0.0,0.0,0.0})
	set_pev(iMuz, pev_body, iAttach)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.05)
	set_pev(iMuz, pev_frame, 0.0)
	dllfunc(DLLFunc_Spawn, iMuz)
}

public Gunkata_Blast(id)
{
	new Float:origin[3]
	pev(id, pev_origin, origin)

	origin[2] -= 5.0
	
	new iEnt = Stock_CreateEntityBase(id, "info_target", 0, MODEL_BLAST, "dbg_entytyd", SOLID_NOT,0.3,origin,Float:{0.0,0.0,0.0})
	set_pev(iEnt, pev_frame, 0.0)
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, 1.0)
	set_pev(iEnt, pev_sequence, 1)
	engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_iuser1, 1);
	set_pev(iEnt, pev_scale, 1.0);
}

public DBG_Specials(ent, id, seq, Float:TimeRemove)
{
	new Float:vecOrigin[3], Float:vecAngle[3];
	Stock_Get_Postion(id, 0.0, 0.0, 0.0 , vecOrigin);
	pev(id, pev_v_angle, vecAngle);
	vecAngle[0] = -vecAngle[0];
	
	new pEntity = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FLY, get_pcvar_num(cvar_mode) ? V_GUNKATAGS : V_GUNKATA, "dbg_entytyd", SOLID_NOT,0.01,vecOrigin,vecAngle)
		
	// Set info for ent
	engfunc(EngFunc_SetSize, pEntity, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	
	set_pev(pEntity, pev_renderamt, 255.0);
	set_pev(pEntity, pev_sequence, seq)
	set_pev(pEntity, pev_animtime, get_gametime());
	set_pev(pEntity, pev_framerate, 1.0)
	
	set_pev(pEntity, pev_iuser1, 0);
	set_pev(pEntity, pev_iuser2, ent);
	set_pev(pEntity, pev_scale, 0.1);
	set_pev(pEntity, pev_velocity, Float:{0.01,0.01,0.01});
	set_pev(pEntity, pev_fuser1, TimeRemove);
}

public DBG_Shadow(id, anim)
{
	static Float:Origin[3], Float:Angles[3]
	pev(id, pev_origin, Origin)
	pev(id, pev_angles, Angles);
	
	new pEntity = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FLY, MODEL_SHADOW, "dbg_entytyd", 0, 0.01, Origin, Angles)
	set_pev(pEntity, pev_iuser1, 2);
	
	set_pev(pEntity, pev_rendermode, kRenderTransAlpha);
	set_pev(pEntity, pev_renderamt, 200.0);
	set_pev(pEntity, pev_sequence, anim)
	set_pev(pEntity, pev_animtime, get_gametime())
	set_pev(pEntity, pev_framerate, 1.0)
}

stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext,Float:vOrg[3], Float:vAng[3])
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	if(vOrg[0]) set_pev(pEntity, pev_origin, vOrg)
	if(vAng[0]) set_pev(pEntity, pev_angles, vAng)
	if(fNext) set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}

stock Stock_Get_Postion(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

/* ===============================
------------- DAMAGES ------------
=================================*/
stock KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
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
		if (!IsAlive(pEntity) || !can_damage(id, pEntity))
			continue;
		if (!CheckAngle(id, pEntity, fAngle))
			continue;
		
		GetGunPosition(id, vecSrc);
		Stock_Get_Origin(pEntity, vecEnd);

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

				if(flDamage > 0.0)
				{
					OrpheuCall(OrpheuGetFunction("ClearMultiDamage"))
					ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
					OrpheuCall(OrpheuGetFunction("ApplyMultiDamage"), id, id)
				}
				
				if(flKnockBack > 0.0) Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			}
		}
		free_tr2(tr);
	}
	free_tr2(tr);
	return iHitResult;
}

stock Stock_Get_Origin(id, Float:origin[3])
{
	new Float:maxs[3],Float:mins[3]
	if (pev(id, pev_solid) == SOLID_BSP)
	{
		pev(id,pev_maxs,maxs)
		pev(id,pev_mins,mins)
		origin[0] = (maxs[0] - mins[0]) / 2 + mins[0]
		origin[1] = (maxs[1] - mins[1]) / 2 + mins[1]
		origin[2] = (maxs[2] - mins[2]) / 2 + mins[2]
	} else pev(id, pev_origin, origin)
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
----------- SOME STOCKS ----------
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

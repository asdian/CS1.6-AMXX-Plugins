#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "Thanatos-5"
#define VERSION "1.0"
#define AUTHOR "Asdian"

#define V_MODEL "models/v_thanatos5.mdl"
#define P_MODEL "models/p_thanatos5.mdl"
#define W_MODEL "models/w_thanatos5.mdl"
#define S_MODEL "models/s_thanatos5.mdl"

#define CSW_THANATOS5 CSW_AK47
#define weapon_thanatos5 "weapon_ak47"
#define OLD_W_MODEL "models/w_ak47.mdl"
#define WEAPON_EVENT "events/ak47.sc"
#define WEAPON_SECRETCODE 1992213
#define CLASSNAME "thanos5_nade"

#define BPAMMO 190

enum _:ENTCLASS(+=999)
{
	ENTCLASS_PRIMARY = 7777,
	ENTCLASS_SPLIT1,
	ENTCLASS_SPLIT2
}

new const WeaponSounds[][] = 
{
	"weapons/thanatos5-1.wav",
	"weapons/thanatos5_shootb2_1.wav",
	"weapons/oicw_foley1.wav",
	"weapons/oicw_foley2.wav",
	"weapons/oicw_foley3.wav",
	"weapons/oicw_move_carbine.wav",
	"weapons/oicw_move_grenade.wav"
}

new const ExpSounds[][] = 
{
	"weapons/thanatos5_explode1.wav",
	"weapons/thanatos5_explode2.wav",
	"weapons/thanatos5_explode3.wav"
}

new const WeaponResources[4][] =
{
	"sprites/weapon_thanatos5.txt",
	"sprites/640hud7.spr",
	"sprites/640hud18.spr",
	"sprites/640hud125.spr"
}

new g_Had_Thanatos5[33], g_mode[33], g_GrenadeAmmo[33]
new g_old_weapon[33], g_smokepuff_id, g_ham_bot, shells_model, g_thanatos_event, spr_trail, g_expspr_id, g_SmokeSprId, g_expspr_id2
new g_cvar_grenade, g_cvar_damage, g_cvar_radius, g_attack, g_clip[33], g_tanos

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_think(CLASSNAME, "fw_Think")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_thanatos5, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_thanatos5, "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_thanatos5, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_thanatos5, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_thanatos5, "fw_Weapon_WeaponIdle_Post")
	RegisterHam(Ham_Item_AddToPlayer, weapon_thanatos5, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_thanatos5, "fw_Item_PostFrame")
	
	g_cvar_grenade = register_cvar("tn5_damage_nade", "150.0")
	g_cvar_damage = register_cvar("tn5_damage", "81.0")
	g_cvar_radius = register_cvar("tn5_radius_nade","150.0")
	
	g_tanos = zp_register_extra_item("Thanatos-5", 0, ZP_TEAM_HUMAN)
	//register_clcmd("lol", "Get_thanatos")
	register_clcmd("weapon_thanatos", "hook_weapon")
	
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, S_MODEL)

	new i 
	for(i = 0; i < sizeof(WeaponSounds); i++) engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	for(i = 0; i < sizeof(ExpSounds); i++) engfunc(EngFunc_PrecacheSound, ExpSounds[i])
	for(i = 0; i < sizeof(WeaponResources); i++)
	{
		if(i == 0) engfunc(EngFunc_PrecacheGeneric, WeaponResources[i])
		else engfunc(EngFunc_PrecacheModel, WeaponResources[i])
	}

	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	shells_model = engfunc(EngFunc_PrecacheModel, "models/rshell.mdl")
	spr_trail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	g_expspr_id = engfunc(EngFunc_PrecacheModel, "sprites/thanatos5_explode.spr")
	g_expspr_id2 = engfunc(EngFunc_PrecacheModel, "sprites/thanatos5_explode2.spr")
	g_SmokeSprId = engfunc(EngFunc_PrecacheModel, "sprites/steam1.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[]) if(equal(WEAPON_EVENT, name)) g_thanatos_event = get_orig_retval()		

public message_DeathMsg()
{
	static wpn[33], iAttacker, iVictim
	get_msg_arg_string(4, wpn, charsmax(wpn))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
        
	if(equal(wpn, "ak47") && get_user_weapon(iAttacker) == CSW_THANATOS5)
		if(g_Had_Thanatos5[iAttacker]) set_msg_arg_string(4, "thanatos5")
	  
	return PLUGIN_CONTINUE
}

public zp_extra_item_selected(id, item) if(item == g_tanos) Get_thanatos(id)
public zp_user_infected_post(id) Remove_thanatos(id)
public zp_user_humanized_post(id) Remove_thanatos(id)

public Get_thanatos(id)
{
	if(!is_user_alive(id))
		return

	g_Had_Thanatos5[id] = 1
	g_mode[id] = 0
	g_GrenadeAmmo[id] = 0
	
	drop_weapons(id, 1)
	fm_give_item(id, weapon_thanatos5)

	cs_set_user_bpammo(id, CSW_THANATOS5, BPAMMO)
	
	static ent
	ent = fm_find_ent_by_owner(-1, weapon_thanatos5, id)
	
	if(pev_valid(ent))
	{
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
		write_byte(1)
		write_byte(CSW_THANATOS5)
		write_byte(cs_get_weapon_ammo(ent))
		message_end()		
	}
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(cs_get_user_bpammo(id, CSW_THANATOS5))
	message_end()
}

public Remove_thanatos(id)
{
	if(!is_user_connected(id))
		return
	
	g_Had_Thanatos5[id] = 0
	Update_SpAmmo(id, g_GrenadeAmmo[id], 0)
}

public hook_weapon(id)
{
	engclient_cmd(id, weapon_thanatos5)
	return PLUGIN_HANDLED
}

public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}

public Do_Register_HamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public client_PostThink(id) if(get_user_weapon(id) != CSW_THANATOS5 || !g_Had_Thanatos5[id]) Update_SpAmmo(id, g_GrenadeAmmo[id], 0)

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	if((get_user_weapon(id) == CSW_THANATOS5 && g_old_weapon[id] != CSW_THANATOS5) && g_Had_Thanatos5[id])
	{ // Draw
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
		
		Update_SpAmmo(id, g_GrenadeAmmo[id], g_GrenadeAmmo[id] > 0 ? 1 : 0)
		set_weapon_anim(id, g_mode[id] ? 13 : 12)
	} else if(get_user_weapon(id) != CSW_THANATOS5 && g_old_weapon[id] == CSW_THANATOS5) {
		Update_SpAmmo(id, g_GrenadeAmmo[id], 0)
	}
	g_old_weapon[id] = get_user_weapon(id)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_THANATOS5 && g_Had_Thanatos5[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!is_user_connected(invoker) || !g_attack)
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_THANATOS5 || !g_Had_Thanatos5[invoker])
		return FMRES_IGNORED
	
	if(eventid == g_thanatos_event)
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
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
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_thanatos5, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_Had_Thanatos5[iOwner])
		{
			g_Had_Thanatos5[iOwner] = 0
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_THANATOS5 || !g_Had_Thanatos5[attacker])
		return HAM_IGNORED
	
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
	
	if(!is_user_alive(ent))
	{
		make_bullet(attacker, flEnd)
		fake_smoke(attacker, ptr)
	}
	SetHamParamFloat(3, get_pcvar_float(g_cvar_damage))
	return HAM_HANDLED
}

public fw_PrimaryAttack(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	
	g_attack = 1
	g_clip[id] = cs_get_weapon_ammo(ent)
}

public fw_PrimaryAttack_Post(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	
	if(!is_user_alive(id) || !g_clip[id])
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_THANATOS5 || !g_Had_Thanatos5[id])
		return HAM_IGNORED
	
	if(g_attack)
	{
		static iAnim
		if(g_mode[id]) iAnim = random_num(5, 7)
		else iAnim = random_num(2, 4)
		set_weapon_anim(id, iAnim)
		
		PlaySound(id, WeaponSounds[0])
		make_shell(id)
	}
	g_attack = 0
	return HAM_IGNORED
}

public fw_Weapon_Reload(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Thanatos5[id])
		return HAM_IGNORED
	
	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Thanatos5[id])
		return HAM_IGNORED
	
	if(get_pdata_int(ent, 54, 4) == 1)
	{ // Reload
		set_weapon_anim(id, g_mode[id] ? 10 : 9)
		
		set_pdata_float(ent, 46, 3.5, 4)
		set_pdata_float(ent, 48, 3.5, 4)
		set_pdata_float(id, 83, 3.5, 5)
	}
	return HAM_HANDLED
}

public fw_Weapon_WeaponIdle_Post(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Thanatos5[id])
		return HAM_IGNORED
	
	if(get_pdata_float(ent, 48, 4) <= 0.0) 
	{
		set_weapon_anim(id, g_mode[id])
		set_pdata_float(ent, 48, 20.0, 4)
	}
	return HAM_IGNORED
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_Had_Thanatos5[id] = 1
		set_pev(ent, pev_impulse, 0)
	}		
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), .player = id)
	write_string(g_Had_Thanatos5[id] == 1 ? "weapon_thanatos5" : weapon_thanatos5)
	write_byte(2) // PrimaryAmmoID
	write_byte(90) // PrimaryAmmoMaxAmount
	write_byte(-1) // SecondaryAmmoID
	write_byte(-1) // SecondaryAmmoMaxAmount
	write_byte(0) // SlotID (0...N)
	write_byte(1) // NumberInSlot (1...N)
	write_byte(CSW_THANATOS5) // WeaponID
	write_byte(0) // Flags
	message_end()
	return HAM_IGNORED//HANDLED
}

public fw_Item_PostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !is_user_alive(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_THANATOS5 || !g_Had_Thanatos5[id])
		return HAM_IGNORED
	
	static iButton
	iButton = pev(id, pev_button)
	
	Special_Thanatso5(id, ent, iButton)
	return HAM_IGNORED
}

public Special_Thanatso5(id, iEnt, iButton)
{
	if(iButton & IN_ATTACK2 && get_pdata_float(iEnt, 46) <= 0.0)
	{
		iButton &= ~IN_ATTACK2
		set_pev(id, pev_button, iButton)
		
		switch(g_mode[id])
		{
			case 0:
			{
				set_pdata_float(iEnt, 46, 5.0)
				set_pdata_float(iEnt, 48, 5.1)
				
				set_pdata_float(id, 83, 4.5)
				set_pev(iEnt, pev_iuser1, 1)
				
				set_weapon_anim(id, 11)
			}
			case 1:
			{
				set_pdata_float(iEnt, 46, 2.0)
				set_pdata_float(iEnt, 48, 2.4)
				
				set_weapon_anim(id, 8)
				PlaySound(id, WeaponSounds[1])
				g_mode[id] = 0
				
				static Float:PunchAngles[3], Float:Origin[3]
				get_weapon_attachment(id, Origin, 24.0)
				
				PunchAngles[0] = random_float(-2.0, -4.0)
				PunchAngles[2] = random_float(5.0, -5.0)
				set_pev(id, pev_punchangle, PunchAngles)
				
				Update_SpAmmo(id, g_GrenadeAmmo[id], 0)
				g_GrenadeAmmo[id]--
				Update_SpAmmo(id, g_GrenadeAmmo[id], 0)
				
				Create_Grenade(id, Origin)
			}
		}
	}
	
	if(get_pdata_float(id, 83) <= 0.0 && pev(iEnt, pev_iuser1))
	{
		set_pev(iEnt, pev_iuser1, 0)
		
		g_mode[id] = 1
		
		Update_SpAmmo(id, g_GrenadeAmmo[id], 0)
		g_GrenadeAmmo[id] = 1
		Update_SpAmmo(id, g_GrenadeAmmo[id], 1)
	}
}

public Create_Grenade(id, Float:Origin[3])
{
	static Ent
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	static Float:Angles[3]
	pev(id, pev_angles, Angles)
	
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
	set_pev(Ent, pev_classname, CLASSNAME)
	Set_Class(Ent, ENTCLASS_PRIMARY)
	engfunc(EngFunc_SetModel, Ent, S_MODEL)
	set_pev(Ent, pev_gravity, 0.435)
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_owner, id)
	
	static Float:Velocity[3], Float:TargetOrigin[3]
	fm_get_aim_origin(id, TargetOrigin)
	get_speed_vector(Origin, TargetOrigin, 700.0, Velocity)
	set_pev(Ent, pev_velocity, Velocity)
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Ent) // entity
	write_short(spr_trail) // sprite
	write_byte(20)  // life
	write_byte(2)  // width
	write_byte(255) // r
	write_byte(255)  // g
	write_byte(255)  // b
	write_byte(200) // brightness
	message_end()
}

public Create_Grenade2(id, Float:Start[3], Float:vecOrigin[3], iClass)
{
	static Ent
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	static Float:Angles[3]
	pev(id, pev_angles, Angles)
	
	set_pev(Ent, pev_classname, CLASSNAME)
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
	Set_Class(Ent, iClass)
	engfunc(EngFunc_SetModel, Ent, S_MODEL)
	set_pev(Ent, pev_origin, Start)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_owner, id)
	
	static Float:Velocity[3]
	get_speed_vector(Start, vecOrigin, 300.0, Velocity)
	set_pev(Ent, pev_velocity, Velocity)
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Ent) // entity
	write_short(spr_trail) // sprite
	write_byte(2)  // life
	write_byte(2)  // width
	write_byte(255) // r
	write_byte(255)  // g
	write_byte(255)  // b
	write_byte(200) // brightness
	message_end()
}

public fw_Think(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, CLASSNAME))
		return HAM_IGNORED
	
	static Class, Float:Start[3], Owner
	pev(ent, pev_origin, Start)
	Owner = pev(ent, pev_owner)
	Class = Get_Class(ent)
	
	Make_Explosion(ent)
	
	if(Class == ENTCLASS_PRIMARY)
	{
		static Float:Origin1[4][3]
		Stock_Get_Postion(ent, 15.0, 0.0, 1.0, Origin1[0])
		Stock_Get_Postion(ent, -15.0, 0.0, 1.0, Origin1[1])
		Stock_Get_Postion(ent, 0.0, 15.0, 1.0, Origin1[2])
		Stock_Get_Postion(ent, 0.0, -15.0, 1.0, Origin1[3])
		for(new i = 0; i < 4; i++) Create_Grenade2(Owner, Start, Origin1[i], ENTCLASS_SPLIT1)
		
		Make_Explosion(ent)
		engfunc(EngFunc_RemoveEntity, ent)
	} else if(Class == ENTCLASS_SPLIT1) {
		
		static Float:Origin2[4][3]
		Stock_Get_Postion(ent, 17.0, 0.0, 1.0, Origin2[0])
		Stock_Get_Postion(ent, -17.0, 0.0, 1.0, Origin2[1])
		Stock_Get_Postion(ent, 0.0, 17.0, 1.0, Origin2[2])
		Stock_Get_Postion(ent, 0.0, -17.0, 1.0, Origin2[3])
		for(new i = 0; i < 4; i++) Create_Grenade2(Owner, Start, Origin2[i], ENTCLASS_SPLIT2)
		
		Make_Explosion(ent)
		engfunc(EngFunc_RemoveEntity, ent)
	} else if(Class == ENTCLASS_SPLIT2) {
		Make_Explosion(ent)
		engfunc(EngFunc_RemoveEntity, ent)
	}
	return HAM_IGNORED
}

public Make_Explosion(ent)
{
	static Float:Origin[3], Owner
	Owner = pev(ent, pev_owner)
	pev(ent, pev_origin, Origin)
	PlaySound(Owner, ExpSounds[random_num(0, 2)])
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_expspr_id)	// sprite index
	write_byte(5)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND)	// flags
	message_end()
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_expspr_id2)	// sprite index
	write_byte(1)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND)	// flags
	message_end()
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_SmokeSprId)	// sprite index 
	write_byte(1)	// scale in 0.1's 
	write_byte(10)	// framerate 
	message_end()
	
	static Float:Origin2[3]
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(i == Owner)
			continue
		if(!can_damage(i, Owner))
			continue
		
		pev(i, pev_origin, Origin2)
		
		if(get_distance_f(Origin, Origin2) > get_pcvar_float(g_cvar_radius))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, Owner, Owner, get_pcvar_float(g_cvar_grenade), DMG_BULLET)
		
	}
}

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1

	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}

public PlaySound(id, sound[]) emit_sound(id, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, random_num(95, 120))

public Set_Class(ent, num) set_pdata_int(ent, 19, num, 4)
public Get_Class(ent) return(get_pdata_int(ent, 19, 4))

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new decal = random_num(41, 45)
	const loop_time = 2
	
	static Body, Target
	get_user_aiming(id, Target, Body, 999999)
	
	if(is_user_connected(Target))
		return
	
	for(new i = 0; i < loop_time; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

public fake_smoke(id, trace_result)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
	
	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
	
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
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	xs_vec_add(fOrigin, fAttack, output)
}

stock Stock_Get_Postion(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp)
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

public make_shell(id)
{
	static Float:player_origin[3], Float:origin[3], Float:origin2[3], Float:gunorigin[3], Float:oldangles[3], Float:v_forward[3], Float:v_forward2[3], Float:v_up[3], Float:v_up2[3], Float:v_right[3], Float:v_right2[3], Float:viewoffsets[3];
	pev(id,pev_v_angle, oldangles)
	pev(id,pev_origin,player_origin)
	pev(id, pev_view_ofs, viewoffsets);
	
	engfunc(EngFunc_MakeVectors, oldangles)
	
	global_get(glb_v_forward, v_forward)
	global_get(glb_v_up, v_up)
	global_get(glb_v_right, v_right)
	
	global_get(glb_v_forward, v_forward2)
	global_get(glb_v_up, v_up2)
	global_get(glb_v_right, v_right2)
	
	xs_vec_add(player_origin, viewoffsets, gunorigin);
	
	xs_vec_mul_scalar(v_forward, 10.3, v_forward)
	xs_vec_mul_scalar(v_right, 2.9, v_right)
	xs_vec_mul_scalar(v_up, -3.7, v_up)
	
	xs_vec_mul_scalar(v_forward2, 10.0, v_forward2)
	xs_vec_mul_scalar(v_right2, 3.0, v_right2)
	xs_vec_mul_scalar(v_up2, -4.0, v_up2)
	
	xs_vec_add(gunorigin, v_forward, origin)
	xs_vec_add(gunorigin, v_forward2, origin2)
	xs_vec_add(origin, v_right, origin)
	xs_vec_add(origin2, v_right2, origin2)
	xs_vec_add(origin, v_up, origin)
	xs_vec_add(origin2, v_up2, origin2)
	
	static Float:velocity[3]
	get_speed_vector(origin2, origin, random_float(140.0, 160.0), velocity)
	
	static angle
	angle = random_num(0, 360)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord,origin[1])
	engfunc(EngFunc_WriteCoord,origin[2])
	engfunc(EngFunc_WriteCoord,velocity[0])
	engfunc(EngFunc_WriteCoord,velocity[1])
	engfunc(EngFunc_WriteCoord,velocity[2])
	write_angle(angle)
	write_short(shells_model)
	write_byte(1)
	write_byte(20)
	message_end()
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed * speed / (new_velocity[0] * new_velocity[0] + new_velocity[1] * new_velocity[1] + new_velocity[2] * new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	return 1
}

stock set_weapons_timeidle(id, Float:TimeIdle, Float:Idle)
{
	new entwpn = fm_get_user_weapon_entity(id, CSW_THANATOS5)
	if(!pev_valid(entwpn)) 
		return
	
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, Idle, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
	
	set_pdata_float(id, 83, nexttime, 5)
}

public Update_SpAmmo(id, Ammo, On)
{
	if(!is_user_alive(id))
		return
	
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)
  	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red
	write_byte(212) // green
	write_byte(255) // blue
	message_end()
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	// Weapon bitsums
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_DEAGLE)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_FIVESEVEN)
	
	for(i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		if((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

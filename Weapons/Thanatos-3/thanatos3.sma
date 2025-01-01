#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

#define WEAPONKEY 30112015
#define RELOAD_TIME 3.5
#define CLIP 45

#define TASK_SPECIAL 6969
#define TASK_RESET 696969

#define CLASS_ENT "tn3_blade"
#define CLASS_ENT2 "tn3_blade_wind"

enum _:iAnim
{
	ANIM_IDLE_NORMAL = 0,
	ANIM_IDLE_WINGS_1,
	ANIM_IDLE_WINGS_2,
	ANIM_IDLE_WINGS_3,
	ANIM_SHOOT_NORMAL,
	ANIM_SHOOT_WINGS_1,
	ANIM_SHOOT_WINGS_2,
	ANIM_SHOOT_WINGS_3,
	ANIM_FLYING_WINGS_1,
	ANIM_FLYING_WINGS_2,
	ANIM_FLYING_WINGS_3,
	ANIM_RELOAD_NORMAL,
	ANIM_RELOAD_WINGS_1,
	ANIM_RELOAD_WINGS_2,
	ANIM_RELOAD_WINGS_3,
	ANIM_SPREAD_WINGS_1,
	ANIM_SPREAD_WINGS_2,
	ANIM_SPREAD_WINGS_3,
	ANIM_DRAW_NORMAL,
	ANIM_DRAW_WINGS_1,
	ANIM_DRAW_WINGS_2,
	ANIM_DRAW_WINGS_3
}

#define weapon_thanatos3 "weapon_mp5navy"
#define CSW_THANATOS3 CSW_MP5NAVY

new const WeaponSounds[][] = 
{
	"weapons/thanatos3-1.wav",
	"weapons/thanatos3_boltpull.wav",
	"weapons/thanatos3_clipout.wav",
	"weapons/thanatos3_clipin.wav",
	"weapons/thanatos3_draw.wav",
	"weapons/thanatos3_draw_w1.wav",
	"weapons/thanatos3_fly_shoot.wav",
	"weapons/thanatos3_fly_w2.wav",
	"weapons/thanatos3_fly_w3.wav",
	"weapons/thanatos3_ilde_w1.wav",
	"weapons/thanatos3_ilde_w2.wav",
	"weapons/thanatos3_ilde_w3.wav",
	"weapons/thanatos3_knife_hit.wav",
	"weapons/thanatos3_knife_swish.wav",
	"weapons/thanatos3_reload_w1.wav",
	"weapons/thanatos3_reload_w2.wav",
	"weapons/thanatos3_reload_w3.wav",
	"weapons/thanatos3_spread_w1.wav"
}

new const V_MODEL[] = "models/v_thanatos3.mdl"

new const P_MODEL[][] =
{
	"models/p_thanatos3a.mdl",
	"models/p_thanatos3b.mdl",
	"models/p_thanatos3c.mdl",
	"models/p_thanatos3d.mdl"
}

new const W_MODEL[][] =
{
	"models/w_thanatos3.mdl",
	"models/w_thanatos3b.mdl"
}

new const S_MODEL[] = "models/thanatos3_knife.mdl"
new const S_WIND_MODEL[] = "models/thanatos3_wind.mdl"

new Float:cl_pushangle[33][3], g_clip_ammo[33], g_TmpClip[33], oldweap[33], g_event, g_attack
new g_had_thanatos3[33], g_mode[33], g_shoot_count[33], g_SpAmmo[33], g_Total[33]
new sTrail, g_smokepuff_id, m_iBlood[2], s_puff

public plugin_init()
{
	register_plugin("Thanatos-3 Remake", "1.0", "Asdian")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	
	register_think(CLASS_ENT2, "fw_Scythe_Wind_Think")
	register_touch(CLASS_ENT, "*", "fw_Touch_Scythe")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_thanatos3, "fw_AddToPlayer")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_thanatos3, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_thanatos3, "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_thanatos3, "fw_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_thanatos3, "fw_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_thanatos3, "fw_Reload_Post", 1)
	
	register_clcmd("xx", "give_thanatos3")
}

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof P_MODEL; i++) engfunc(EngFunc_PrecacheModel, P_MODEL[i])
	for(i = 0; i < sizeof W_MODEL; i++) engfunc(EngFunc_PrecacheModel, W_MODEL[i])
	
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, S_MODEL)
	engfunc(EngFunc_PrecacheModel, S_WIND_MODEL)
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	sTrail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	s_puff = engfunc(EngFunc_PrecacheModel, "sprites/smokepuff.spr")
	engfunc(EngFunc_PrecacheGeneric, "sprites/weapon_thanatos3.txt")
	
	for(new i = 0; i < sizeof WeaponSounds; i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	
	m_iBlood[0] = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
	m_iBlood[1] = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")
	
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public fwPrecacheEvent_Post(type, const name[]) if(equal("events/mp5n.sc", name)) g_event = get_orig_retval()

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return
	if(get_user_weapon(iAttacker) != CSW_THANATOS3 || !g_had_thanatos3[iAttacker])
		return
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(!is_user_alive(iEnt))
	{
		Stock_BulletHole(iAttacker, flEnd, flDamage)
		Stock_BulletSmoke(iAttacker, ptr)
	}
}

public message_DeathMsg()
{
	static wpn[33], iAttacker, iVictim
	get_msg_arg_string(4, wpn, charsmax(wpn))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
        
	if(equal(wpn, "mp5navy") && get_user_weapon(iAttacker) == CSW_THANATOS3)
		if(g_had_thanatos3[iAttacker]) set_msg_arg_string(4, "thanatos3")
	  
	return PLUGIN_CONTINUE
}

public give_thanatos3(id)
{
	g_had_thanatos3[id] = 1
	g_SpAmmo[id] = 0
	g_mode[id] = 0
	g_shoot_count[id] = 0
	Update_SpecialAmmo(id, g_SpAmmo[id], 0)
	
	drop_weapons(id, 1)
	fm_give_item(id, weapon_thanatos3)
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_THANATOS3)
	if(pev_valid(ent)) cs_set_weapon_ammo(ent, CLIP)
	cs_set_user_bpammo (id, CSW_THANATOS3, 240)	
	set_weapon_anim(id, ANIM_DRAW_NORMAL)
	set_weapons_timeidle(id, CSW_THANATOS3, 1.0, 1.4)
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, "models/w_mp5.mdl"))
	{
		static weapon
		weapon = find_ent_by_owner(-1, weapon_thanatos3, entity)
	
		if(!pev_valid(weapon))
			return FMRES_IGNORED
	
		if(g_had_thanatos3[iOwner])
		{
			set_pev(weapon, pev_impulse, WEAPONKEY)
			g_had_thanatos3[iOwner] = 0
			engfunc(EngFunc_SetModel, entity, W_MODEL[g_mode[iOwner] > 0 ? 1 : 0])
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_THANATOS3 || !g_had_thanatos3[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if((eventid != g_event) || !g_attack)
		return FMRES_IGNORED
	if(!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED

	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public CurrentWeapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	
	if(g_had_thanatos3[id] && (get_user_weapon(id) == CSW_THANATOS3) && oldweap[id] != CSW_THANATOS3)
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL[g_mode[id]])
		
		switch(g_mode[id])
		{
			case 0: set_weapon_anim(id, ANIM_DRAW_NORMAL)
			case 1: set_weapon_anim(id, ANIM_DRAW_WINGS_1)
			case 2: set_weapon_anim(id, ANIM_DRAW_WINGS_2)
			case 3: set_weapon_anim(id, ANIM_DRAW_WINGS_3)
		}
		
		set_weapons_timeidle(id, CSW_THANATOS3, 1.0, 1.4)
		Update_SpecialAmmo(id, g_SpAmmo[id], 1)
	} else if(get_user_weapon(id) != CSW_THANATOS3 && oldweap[id] == CSW_THANATOS3) {
		emit_sound(id, CHAN_WEAPON, "common/null.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		Update_SpecialAmmo(id, g_SpAmmo[id], 0)
	}
	
	oldweap[id] = get_user_weapon(id)
}

public fw_AddToPlayer(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return
	
	if(pev(ent, pev_impulse) == WEAPONKEY)
	{
		g_had_thanatos3[id] = 1
		set_pev(ent, pev_impulse, 0)
	}
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_had_thanatos3[id] == 1 ? "weapon_thanatos3" : weapon_thanatos3)
	write_byte(10)
	write_byte(120)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(7)
	write_byte(CSW_THANATOS3)
	write_byte(0)
	message_end()
}

public fw_PrimaryAttack(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	
	if(!g_had_thanatos3[id])
		return
	
	g_attack = 1
	pev(id, pev_punchangle, cl_pushangle[id])
	g_clip_ammo[id] = cs_get_weapon_ammo(ent)
}

public fw_PrimaryAttack_Post(ent)
{
	if(!pev_valid(ent))
		return
	
	new id = get_pdata_cbase(ent, 41, 4)
	
	if(!is_user_alive(id) || !g_had_thanatos3[id])
		return
	if(!g_clip_ammo[id])
		return
	
	g_attack = 0
	
	new Float:push[3]
	pev(id, pev_punchangle, push)
	xs_vec_sub(push, cl_pushangle[id], push)
	xs_vec_mul_scalar(push, 0.15, push)
	xs_vec_add(push, cl_pushangle[id], push)
	set_pev(id, pev_punchangle, push)
		
	engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, random_num(PITCH_LOW, PITCH_HIGH))
	g_shoot_count[id]++
	
	if(g_shoot_count[id] == 12)
	{
		Update_SpecialAmmo(id, 0, 0)
		g_SpAmmo[id] = 1
		Update_SpecialAmmo(id, g_SpAmmo[id], 1)
		
		g_mode[id] = 1
		set_weapon_anim(id, ANIM_SPREAD_WINGS_1)
		set_pdata_float(ent, 48, 0.4)
	} else if(g_shoot_count[id] == 24) {
		Update_SpecialAmmo(id, g_SpAmmo[id], 0)
		g_SpAmmo[id] = 2
		Update_SpecialAmmo(id, g_SpAmmo[id], 1)
		
		g_mode[id] = 2
		set_weapon_anim(id, ANIM_SPREAD_WINGS_2)
		set_pdata_float(ent, 48, 0.4)
	} else if(g_shoot_count[id] == 36) {
		Update_SpecialAmmo(id, g_SpAmmo[id], 0)
		g_SpAmmo[id] = 3
		Update_SpecialAmmo(id, g_SpAmmo[id], 1)
		
		g_mode[id] = 3
		set_weapon_anim(id, ANIM_SPREAD_WINGS_3)
		set_pdata_float(ent, 48, 0.4)
	}
	
	switch(g_mode[id])
	{
		case 0: set_weapon_anim(id, ANIM_SHOOT_NORMAL)
		case 1: set_weapon_anim(id, ANIM_SHOOT_WINGS_1)
		case 2: set_weapon_anim(id, ANIM_SHOOT_WINGS_2)
		case 3: set_weapon_anim(id, ANIM_SHOOT_WINGS_3)
	}
	
	set_pdata_float(ent, 46, 0.1, 4)
	set_pdata_float(ent, 48, 0.4)
}

public fw_ItemPostFrame(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !g_had_thanatos3[id])
		return HAM_IGNORED
	
	new Float:flNextAttack = get_pdata_float(id, 83, 5), iBpAmmo = cs_get_user_bpammo(id, CSW_THANATOS3)
	new iClip = get_pdata_int(ent, 51, 4), fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new iTotal = min(CLIP - iClip, iBpAmmo)
		set_pdata_int(ent, 51, iClip + iTotal, 4)
		cs_set_user_bpammo(id, CSW_THANATOS3, iBpAmmo - iTotal)
		set_pdata_int(ent, 54, 0, 4)
	}
	
	if(get_pdata_float(ent, 48, 4) <= 0.0) 
	{
		switch(g_mode[id])
		{
			case 0: set_weapon_anim(id, ANIM_IDLE_NORMAL)
			case 1: set_weapon_anim(id, ANIM_IDLE_WINGS_1)
			case 2: set_weapon_anim(id, ANIM_IDLE_WINGS_2)
			case 3: set_weapon_anim(id, ANIM_IDLE_WINGS_3)
		}
		set_pdata_float(ent, 48, 20.0, 4)
		return HAM_SUPERCEDE
	}
	Thanatos3_Special(id, ent)
	return HAM_IGNORED
}

public fw_Reload(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !g_had_thanatos3[id])
		return HAM_IGNORED
	
	g_TmpClip[id] = -1

	new iBpAmmo = cs_get_user_bpammo(id, CSW_THANATOS3)
	new iClip = get_pdata_int(ent, 51, 4)

	if(iBpAmmo <= 0 || iClip >= CLIP)
		return HAM_SUPERCEDE

	g_TmpClip[id] = iClip
	return HAM_IGNORED
}

public fw_Reload_Post(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !g_had_thanatos3[id])
		return HAM_IGNORED
	if(g_TmpClip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(ent, 51, g_TmpClip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	set_pdata_float(ent, 46, RELOAD_TIME, 4)
	set_pdata_float(ent, 47, RELOAD_TIME, 4)
	set_pdata_float(ent, 48, RELOAD_TIME - 0.2, 4)
	set_pdata_float(id, 83, RELOAD_TIME, 5)
	
	switch(g_mode[id])
	{
		case 0: set_weapon_anim(id, ANIM_RELOAD_NORMAL)
		case 1: set_weapon_anim(id, ANIM_RELOAD_WINGS_1)
		case 2: set_weapon_anim(id, ANIM_RELOAD_WINGS_2)
		case 3: set_weapon_anim(id, ANIM_RELOAD_WINGS_3)
	}
	return HAM_IGNORED
}

public Thanatos3_Special(id, iEnt)
{
	static iButton, Float:vecPos[2]
	iButton = pev(id, pev_button)
	
	if(get_pdata_float(iEnt, 46) <= 0.0)
	{
		if(iButton & IN_ATTACK2)
		{
			if(!g_mode[id] || !g_SpAmmo[id])
				return
			
			set_pdata_float(iEnt, 46, 2.0, 4)
			set_pdata_float(iEnt, 47, 2.0, 4)
			set_pdata_float(iEnt, 48, 2.0, 4)
			
			g_SpAmmo[id] = 0
			Update_SpecialAmmo(id, g_SpAmmo[id], 0)
			engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, WeaponSounds[6], VOL_NORM, ATTN_NORM, 0, random_num(PITCH_LOW, PITCH_HIGH))
			
			switch(g_mode[id])
			{
				case 1:
				{
					set_weapon_anim(id, ANIM_FLYING_WINGS_1)
					g_Total[id] = 2
					
					vecPos[0] = -3.5 // Left
					vecPos[1] = 3.5 // Right
				}
				case 2:
				{
					set_weapon_anim(id, ANIM_FLYING_WINGS_2)
					g_Total[id] = 4
					
					vecPos[0] = -1.7 // Left
					vecPos[1] = 1.7 // Right
					
					set_pdata_float(id, 83, 0.15)
					set_pev(iEnt, pev_iuser1, 1)
					set_pev(iEnt, pev_iuser2, 0)
				}
				case 3:
				{
					set_weapon_anim(id, ANIM_FLYING_WINGS_3)
					g_Total[id] = 6
					
					set_pdata_float(id, 83, 0.3)
					set_pev(iEnt, pev_iuser1, 1)
					set_pev(iEnt, pev_iuser2, 1)
				}
			}
			
			if(g_mode[id] < 3)
			{
				static Float:Origin[2][3]
				Stock_GetPostion(id, 2.0, vecPos[0], -2.5, Origin[0]) // Left
				Stock_GetPostion(id, 2.0, vecPos[1], -2.5, Origin[1]) // Right
				for(new i = 0; i < 2; i++) Special_Shoot_Wings(id, Origin[i])
			}
			
			g_shoot_count[id] = 0
			g_mode[id] = 0
		}
	}
	
	if(get_pdata_float(id, 83) <= 0.0 && pev(iEnt, pev_iuser1) == 1)
	{
		new bool:iNext = pev(iEnt, pev_iuser2) ? true : false
		static Float:Origin2[2][3], Float:vPos[2]
		
		if(!iNext)
		{
			set_pev(iEnt, pev_iuser1, 0)
			
			vPos[0] = -4.7 // Left
			vPos[1] = 4.7  // Right
		} else {
			set_pdata_float(id, 83, 0.173)
			set_pev(iEnt, pev_iuser1, 2)
			
			vPos[0] = -1.3 // Left   -3.1
			vPos[1] = 1.3  // Right   3.1
		}
		Stock_GetPostion(id, 2.0, vPos[0], -1.5, Origin2[0]) // Left
		Stock_GetPostion(id, 2.0, vPos[1], -1.5, Origin2[1]) // Right
		for(new i = 0; i < 2; i++) Special_Shoot_Wings(id, Origin2[i])
	}
	
	if(get_pdata_float(id, 83) <= 0.0 && pev(iEnt, pev_iuser1) == 2)
	{
		static Float:Origin3[2][3]
		Stock_GetPostion(id, 2.0, -4.1, -1.5, Origin3[0]) // Left
		Stock_GetPostion(id, 2.0, 4.1, -1.5, Origin3[1]) // Right
		for(new i = 0; i < 2; i++) Special_Shoot_Wings(id, Origin3[i])
		
		set_pev(iEnt, pev_iuser1, 3)
		set_pdata_float(id, 83, 0.173)
	}
	
	if(get_pdata_float(id, 83) <= 0.0 && pev(iEnt, pev_iuser1) == 3)
	{
		set_pev(iEnt, pev_iuser1, 0)
		
		static Float:Origin4[2][3]
		Stock_GetPostion(id, 2.0, -7.5, -1.5, Origin4[0]) // Left
		Stock_GetPostion(id, 2.0, 7.5, -1.5, Origin4[1]) // Right
		for(new i = 0; i < 2; i++) Special_Shoot_Wings(id, Origin4[i])
	}
}

public Special_Shoot_Wings(id, Float:StartOrigin[3])
{
	static Ent
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	static Float:vAngles[3], Float:Velocity[3]
	pev(id, pev_v_angle, vAngles)
	Stock_Velocity_By_Aim(vAngles, 0.0, 2100.0, Velocity)
	
	set_pev(Ent, pev_origin, StartOrigin)
	engfunc(EngFunc_SetModel, Ent, S_MODEL)
	engfunc(EngFunc_SetSize, Ent, {-1.1, -1.1, -1.1}, {1.1, 1.1, 1.1})
	set_pev(Ent, pev_classname, CLASS_ENT)
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_angles, vAngles)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_velocity, Velocity)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_nextthink, halflife_time() + 0.01)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(Ent) // Entity
	write_short(sTrail) // Sprite index
	write_byte(8) // Life
	write_byte(2) // Line width
	write_byte(65)
	write_byte(69)
	write_byte(121)
	write_byte(100) // Alpha
	message_end()
}

public fw_Touch_Scythe(Ent, Id)
{
	if(!pev_valid(Ent))
		return
	
	new Float:originF[3]
	pev(Ent, pev_origin, originF)
	
	static Owner
	Owner = pev(Ent, pev_owner)
	
	if(is_user_alive(Id) && can_damage(Id, Owner))
	{
		create_blood(originF)
		
		Stock_Fake_KnockBack(Owner, Id, 5.0)
		ExecuteHamB(Ham_TakeDamage, Id, Owner, Owner, random_float(40.0, 60.0), DMG_BULLET)
		
		do
		{
			static Float:Origin[3], Float:Origin2[3]
			pev(Id, pev_origin, Origin)
			
			Origin2[0] = Origin[0] + random_float(-1.5, 1.5)
			Origin2[1] = Origin[1] + random_float(-1.5, 1.5)
			Origin2[2] = Origin[2] + random_float(-1.5, 1.5)
			
			Scythe_Wind_Attack(Id, Owner, Origin2)
			g_Total[Owner]--
		} while(g_Total[Owner] > 0)
		engfunc(EngFunc_EmitSound, Id, CHAN_WEAPON, WeaponSounds[12], VOL_NORM, ATTN_NORM, 0, random_num(PITCH_LOW, PITCH_HIGH))
	} else create_fake_smokes(originF)
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Scythe_Wind_Attack(id, attacker, Float:Origin[3])
{
	static Ent
	Ent = fm_find_ent_by_owner(-1, CLASS_ENT2, id)
	
	if(is_user_alive(id) && can_damage(id, attacker))
	{
		static Float:iAngle[3], Float:iAngle2[3]
		pev(id, pev_angles, iAngle)
		
		iAngle2[0] = iAngle[0] + random_float(-5.0, 5.0)
		iAngle2[1] = iAngle[1] + random_float(-5.0, 5.0)
		iAngle2[2] = iAngle[2] + random_float(-5.0, 5.0)
		
		new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
		set_pev(iEnt, pev_scale, 2.0)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
		set_pev(iEnt, pev_classname, CLASS_ENT2)
		engfunc(EngFunc_SetModel, iEnt, S_WIND_MODEL)
		set_pev(iEnt, pev_origin, Origin)
		set_pev(iEnt, pev_owner, attacker)
		set_pev(iEnt, pev_angles, iAngle2)
		set_pev(iEnt, pev_aiment, id)
		set_pev(iEnt, pev_fuser1, get_gametime() + 6.0)
		set_pev(iEnt, pev_animtime, get_gametime())
		set_pev(iEnt, pev_framerate, 4.0)
		set_pev(iEnt, pev_sequence, 0)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // Temporary entity ID
		write_short(iEnt) // Entity
		write_short(sTrail) // Sprite index
		write_byte(5) // Life
		write_byte(2) // Line width
		write_byte(65)
		write_byte(69)
		write_byte(121)
		write_byte(100) // Alpha
		message_end()
	} else engfunc(EngFunc_RemoveEntity, Ent)
}

public fw_Scythe_Wind_Think(iEnt)
{
	if(!pev_valid(iEnt))
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return
	}
	
	static attacker, victim
	attacker = pev(iEnt, pev_owner)
	victim = pev(iEnt, pev_aiment)
	
	static Float:OriginF[3]
	pev(iEnt, pev_origin, OriginF)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
	
	if(zp_get_user_zombie(attacker) || !is_user_alive(attacker) || !zp_get_user_zombie(victim) || !is_user_alive(victim))
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return
	}
	
	if(pev(iEnt, pev_fuser2) < get_gametime())
	{
		create_blood(OriginF)
		
		ExecuteHamB(Ham_TakeDamage, victim, attacker, attacker, random_float(6.0, 10.0), DMG_BULLET)
		set_pev(iEnt, pev_fuser2, get_gametime() + 0.1)
	}
	
	if(pev(iEnt, pev_fuser3) < get_gametime())
	{
		set_pev(iEnt, pev_fuser3, get_gametime() + random_float(0.5, 1.5))
		set_pev(iEnt, pev_animtime, get_gametime())
		set_pev(iEnt, pev_framerate, 2.0)
		set_pev(iEnt, pev_sequence, 1)
		
		engfunc(EngFunc_EmitSound, iEnt, CHAN_VOICE, WeaponSounds[13], VOL_NORM, ATTN_NORM, 0, random_num(PITCH_LOW, PITCH_HIGH))
	}
	
	if(get_gametime() >= pev(iEnt, pev_fuser1))
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return
	}
}

stock Stock_GetPostion(id,Float:forw, Float:right, Float:up, Float:vStart[])
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

stock Stock_Velocity_By_Aim(Float:vAngle[3],Float:fAngleOffset,Float:fMulti,Float:vVelocity[3])
{
	static Float:vForward[3],Float:vAngleTemp[3]
	xs_vec_copy(vAngle, vAngleTemp)
	vAngleTemp[0] += fAngleOffset
	angle_vector(vAngleTemp, ANGLEVECTOR_FORWARD, vForward)
	xs_vec_mul_scalar(vForward, fMulti, vVelocity)
}

stock create_blood(const Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(8)
	message_end()
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
	xs_vec_mul_scalar(vVictim, 400.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.5, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}

public Update_SpecialAmmo(id, Ammo, On)
{
	static AmmoSprites[33], Ammo_Asli
	
	if(Ammo == 1) Ammo_Asli = 2
	else if(Ammo == 2) Ammo_Asli = 4
	else if(Ammo == 3) Ammo_Asli = 6
	
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo_Asli)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red
	write_byte(42) // green
	write_byte(252) // blue
	message_end()
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId, Float:TimeIdle, Float:TimeIdle2)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle2, 4)
}

stock set_weapon_anim(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
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

stock create_fake_smokes(Float:Origin[3])
{
	static TE_FLAG
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] - 10.0)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(80)
	write_byte(TE_FLAG)
	message_end()
}

stock Stock_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
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

stock Stock_BulletSmoke(id, trace_result)
{
	static Body, Target
	get_user_aiming(id, Target, Body)
	
	if(is_user_connected(Target) || is_user_alive(Target))
		return
	
	static Float:vecSrc[3], Float:vecEnd[3]
	Stock_Get_Attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
	
	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(s_puff)
	write_byte(2)
	write_byte(50)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
}

stock Stock_Get_Attachment(id, Float:output[3], Float:fDis = 40.0)
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

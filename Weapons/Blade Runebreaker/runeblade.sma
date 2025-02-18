/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

#define PLUGIN "CSO Rune Blade"
#define VERSION "1.0"
#define AUTHOR "Natasha"

#define CSW_RUNEBLADE CSW_KNIFE
#define weapon_runeblade "weapon_knife"

#define v_model "models/v_runeblade.mdl"
#define p_model "models/p_runeblade.mdl"
#define spr_wpn	"knife_runeblade"

new const weapon_sound[8][] =
{
	"weapons/runeblade-slash1.wav",				// 0
	"weapons/runeblade-slash2.wav",				// 1
	"weapons/tomahawk_slash1_hit.wav",			// 2
	"weapons/tomahawk_slash2_hit.wav",			// 3
	"weapons/combatknife_wall.wav",				// 4
	"weapons/runeblade_v_charge_attack1.wav",	// 5
	"weapons/runeblade_v_charge_attack2.wav",	// 6
	"weapons/laserminigun_exp2.wav"	// 7
}

//SLASH
#define	SLASH_ANGLE			120.0
#define SLASH_DAMAGE			random_float(300.0,350.0)
#define SLASH_RANGE			130.0
#define SLASH_KNOCKBACK 		1.0		

//CHARGE
#define CHARGE_DAMAGE			random_float(600.0,650.0)	
#define	CHARGE_RANGE			160.0
#define	CHARGE_ANGLE			180.0
#define CHARGE_KNOCKBACK 		300.0				

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2

new g_had_runeblade[33], g_rb
new spr_blood_spray, spr_blood_drop, spr1, spr2

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	RegisterHam(Ham_Item_PostFrame, weapon_runeblade, "fw_Item_PostFrame")
	
	g_rb = zp_register_extra_item("Runeblade", 30, ZP_TEAM_HUMAN)
	register_clcmd(spr_wpn, "hook_rb")
}

public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	
	for(new i = 0; i < sizeof(weapon_sound); i++)
		precache_sound(weapon_sound[i])
	
	spr1 = precache_model("sprites/runeblade_ef.spr")
	spr2 = precache_model("sprites/runeblade_ef02.spr")
	
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	spr_blood_drop = precache_model("sprites/blood.spr")
	
	new Txt[32]
	format(Txt, 31, "sprites/%s.txt", spr_wpn)
	engfunc(EngFunc_PrecacheGeneric, Txt)
}

public hook_rb(id)
{
	engclient_cmd(id, weapon_runeblade)
	return PLUGIN_HANDLED
}

public zp_extra_item_selected(id, itemid) if(itemid == g_rb) get_runeblade(id)
public zp_user_infected_post(id) remove_crow9(id)

public get_runeblade(id)
{
	if (!is_user_alive(id))
		return

	g_had_runeblade[id] = 1
	
	if (get_user_weapon(id) == CSW_RUNEBLADE) Event_CurWeapon(id)
	else engclient_cmd(id,weapon_runeblade)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_had_runeblade[id] == 1 ? spr_wpn : weapon_runeblade)
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(2)
	write_byte(1)
	write_byte(CSW_RUNEBLADE)
	write_byte(0)
	message_end()
}

public remove_crow9(id)
{
	g_had_runeblade[id] = 0
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(get_user_weapon(id) != CSW_RUNEBLADE)
		return 1
	if(!g_had_runeblade[id])
		return 1
		
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, p_model)
	
	Set_WeaponAnim(id, 2)
	
	static iEnt; iEnt = fm_get_user_weapon_entity(id, CSW_RUNEBLADE)
	if(!pev_valid(iEnt)) return 1
	
	set_pdata_float(id, 83, 1.0)
	set_pdata_float(iEnt, 46, 1.03);
	set_pdata_float(iEnt, 47, 1.03);
	set_pdata_float(iEnt, 48, 1.03);
	
	set_pev(iEnt, pev_iuser1, 0)
	set_pev(iEnt, pev_iuser2, 0)
	set_pev(iEnt, pev_iuser3, 0)
			
	return 0
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "knife"))
		return PLUGIN_CONTINUE

	new iEntity = get_pdata_cbase(get_msg_arg_int(1), 373)
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_RUNEBLADE || !g_had_runeblade[get_msg_arg_int(1)])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "runeblade")
	return PLUGIN_CONTINUE
}

public fw_Item_PostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_RUNEBLADE || !g_had_runeblade[id])
		return HAM_IGNORED

	new iButton = pev(id,pev_button)
	return AurezLegendOfBotac(id, ent, iButton)
}

public AurezLegendOfBotac(id, iEnt, iButton)
{
	new bStab = pev(iEnt, pev_iuser2);
	new iState = pev(iEnt, pev_iuser3)
	new IsSpec = (bStab == 2)
	
	if(!(iButton & IN_ATTACK2))
	{
		if(iState == 2 || iState == 3)
		{
			set_pev(iEnt, pev_iuser3, 0)
			
			SendSound(id, CHAN_ITEM, weapon_sound[5])
			Set_WeaponAnim(id, 7)
				
			set_pdata_float(id, 83, 0.4)
			set_pdata_float(iEnt, 46, 1.6);
			set_pdata_float(iEnt, 47, 1.6);
			set_pdata_float(iEnt, 48, 2.3)	
			
			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_iuser2, 1)
			set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
		}
		
		if(iState == 4)
		{
			set_pev(iEnt, pev_iuser3, 0)
			Set_WeaponAnim(id, 8)
			
			set_pdata_float(id, 83, 0.56)
			set_pdata_float(iEnt, 46, 1.6);
			set_pdata_float(iEnt, 47, 1.6);
			set_pdata_float(iEnt, 48, 2.3)	
			
			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_iuser2, 2)
			set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
		}
	}
	
	if (get_pdata_float(id, 83) <= 0.0 && pev(iEnt, pev_iuser1))
	{
		new Float:Damage[4]
		Damage[0] = IsSpec ? CHARGE_RANGE : SLASH_RANGE
		Damage[1] = IsSpec ? CHARGE_ANGLE : SLASH_ANGLE
		Damage[2] = IsSpec ? CHARGE_DAMAGE : SLASH_DAMAGE
		Damage[3] = IsSpec ? CHARGE_KNOCKBACK : SLASH_KNOCKBACK
		
		new iHitResult = KnifeAttack_Global(id, IsSpec, Damage[0], Damage[1], Damage[2], Damage[3])
		if(!bStab) SendSound(id, CHAN_ITEM, weapon_sound[0])
		
		if(bStab != 2)
		{
			switch (iHitResult)
			{
				case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(2, 3)])
				case RESULT_HIT_WORLD : SendSound(id, CHAN_VOICE, weapon_sound[4])
			}
		} else SendSound(id, CHAN_ITEM, weapon_sound[7])
		
		new Float:vecSrc[3], Float:vecEnd[3], Float:vecForward[3];
		GetGunPosition(id, vecSrc);

		global_get(glb_v_forward, vecForward);
		xs_vec_mul_scalar(vecForward, IsSpec ? 50.0:Damage[0], vecForward);
		xs_vec_add(vecSrc, vecForward, vecEnd);

		new tr = create_tr2();
		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

		new Float:EndPos2[3]
		get_tr2(tr, TR_vecEndPos, EndPos2)
		
		if(!IsSpec && iHitResult != RESULT_HIT_NONE)
		{
			new Float:iVicOrig[3], pEntity = -1;
			new Float:realOrig[3]; pev(id, pev_origin, realOrig)
			
			if(iHitResult == RESULT_HIT_PLAYER)
			{
				while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, realOrig, Damage[0])) != 0)
				{
					if (!pev_valid(pEntity))
						continue;
					if (id == pEntity)
						continue;
					if (!IsAlive(pEntity))
						continue;
					if (!CheckAngle(id, pEntity, Damage[1]))
						continue;	

					Stock_Get_Origin(pEntity, iVicOrig);
					iVicOrig[2] -= 15.0

					Make_EffSprite(iVicOrig,0)
				}
			} else Make_EffSprite(EndPos2,0)
		} 
		
		EndPos2[2] -= 15.0
		if(IsSpec) Make_EffSprite(EndPos2,1)
		
		set_pev(iEnt, pev_iuser1, 0);
		set_pev(iEnt, pev_iuser2, 0)
	}
	
	if(get_pdata_float(iEnt, 46) > 0.0)
		return HAM_IGNORED
	
	if(iButton & IN_ATTACK)
	{
		set_pdata_float(id, 83, 0.15)
		set_pdata_float(iEnt, 46, 1.3,4);
		set_pdata_float(iEnt, 47, 1.31,4);
		set_pdata_float(iEnt, 48, 2.03,4);

		set_pev(iEnt, pev_iuser1, 1)
		set_pev(iEnt, pev_iuser2, 0)
		set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
		
		Set_WeaponAnim(id, 1)
	}

	if(iButton & IN_ATTACK2)
	{
		switch(iState)
		{
			case 0:
			{
				Set_WeaponAnim(id, 9)
				
				set_pdata_float(iEnt, 46, 0.8)
				set_pdata_float(iEnt, 47, 1.0)
				set_pdata_float(iEnt, 48, 1.7)
				
				set_pev(iEnt, pev_iuser3, 1)
			}
			case 1:
			{
				Set_WeaponAnim(id, 3)
				set_pdata_float(iEnt, 46, 0.36);
				set_pdata_float(iEnt, 47, 0.36);
				set_pdata_float(iEnt, 48, 0.36);

				set_pev(iEnt, pev_iuser3, 2)
			}
			case 2:
			{
				Set_WeaponAnim(id, 5)
				set_pdata_float(iEnt, 46, 1.4);
				set_pdata_float(iEnt, 47, 1.4);
				set_pdata_float(iEnt, 48, 1.03);
				
				set_pev(iEnt, pev_iuser3, 3)
			}
			case 3:
			{
				Set_WeaponAnim(id, 4)
				set_pdata_float(iEnt, 46, 0.36);
				set_pdata_float(iEnt, 47, 0.36);
				set_pdata_float(iEnt, 48, 0.36);

				set_pev(iEnt, pev_iuser3, 4)
			}
			case 4:
			{
				set_pdata_float(iEnt, 46, 1.03);
				set_pdata_float(iEnt, 47, 1.03);
				set_pdata_float(iEnt, 48, 1.03);
				
				Set_WeaponAnim(id, 6)
				set_pev(iEnt, pev_iuser3, 4)
			}
		}
	} else {
		if(iState == 1)
		{
			set_pev(iEnt, pev_iuser3, 0)
			
			SendSound(id, CHAN_ITEM, weapon_sound[1])
			set_pdata_float(id, 83, 0.2)
			set_pdata_float(iEnt, 46, 1.0)
			set_pdata_float(iEnt, 47, 1.0)
			set_pdata_float(iEnt, 48, 1.7)	
			
			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_iuser2, 0)
			set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
		}
	}
	
	iButton &= ~IN_ATTACK;
	iButton &= ~IN_ATTACK2;
	set_pev(id, pev_button, iButton);
	return HAM_IGNORED
}

stock SendSound(id, chan, sample[]) emit_sound(id, chan, sample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

stock KnifeAttack_Global(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
{
	new iHitResult
	if(fAngle > 0.0) iHitResult = KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
	else iHitResult = KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack)

	return iHitResult
}

stock KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
{
	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
	
	get_tr2(tr, TR_flFraction, flFraction);

	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new iHitResult = RESULT_HIT_NONE;
	
	if (flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit);
		iHitResult = RESULT_HIT_WORLD;
		
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 3.0;

			iHitResult = RESULT_HIT_PLAYER;
		}

		if (pev_valid(pEntity))
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
			ExecuteHamB(Ham_TakeDamage, pEntity, id, id, flDamage, bitsDamageType)
			Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			
			if (IsAlive(pEntity))
			{
				free_tr2(tr);
				return iHitResult;
			}
		}
	}
	free_tr2(tr);
	return iHitResult;
}

stock KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bNoTraceCheck = 0)
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
					flDamage *= 3.0;
			}

			if (get_tr2(tr, TR_pHit) == pEntity || bNoTraceCheck)
			{
				engfunc(EngFunc_MakeVectors, v_angle);
				global_get(glb_v_forward, vecForward);

				if (iHitgroup != -1) set_tr2(tr, TR_iHitgroup, iHitgroup);

				ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, DMG_NEVERGIB | DMG_CLUB);
				ExecuteHamB(Ham_TakeDamage, pEntity, id, id, flDamage, DMG_NEVERGIB | DMG_CLUB)
				Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			}
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock Set_WeaponAnim(id, anim)
{
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
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}

stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock Make_EffSprite(Float:fOrigin[3],bStab)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(bStab?spr1:spr2) 
	write_byte(bStab?6:3)
	write_byte(40)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
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

stock IsPlayer(pEntity) return is_user_connected(pEntity)

stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}

stock IsAlive(pEntity)
{
	if (pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}

stock GetGunPosition(id, Float:vecScr[3])
{
	new Float:vecViewOfs[3]
	pev(id, pev_origin, vecScr)
	pev(id, pev_view_ofs, vecViewOfs)
	xs_vec_add(vecScr, vecViewOfs, vecScr)
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

stock CheckAngle(iAttacker, iVictim, Float:fAngle)  return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))

stock Float:Stock_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]
	Stock_Get_Origin(id, vId_ori)
	Stock_Get_Origin(iTarget, vTar_ori)
	
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

stock SpawnBlood(const Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount == 0)
	return

	if (!iColor)
	return

	iAmount *= 2
	if(iAmount > 255) iAmount = 255
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(iColor)
	write_byte(min(max(3, iAmount / 10), 16))
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
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}	

stock Float:Stock_Get_Body_Dmg(iBody)
{
	switch (iBody)
	{
		case HIT_GENERIC: return 0.75
		case 1: return 4.0
		case 2: return 1.0
		case 3: return 1.25
		case 4,5,6,7: return 0.75
		default: return 0.75
	}
	return 1.0
}

stock Stock_BloodEffect(Float:vecOri[3], scale)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord,vecOri[0])
	engfunc(EngFunc_WriteCoord,vecOri[1])
	engfunc(EngFunc_WriteCoord,vecOri[2])
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(75)
	write_byte(scale)
	message_end()
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

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <orpheu>

// No need to separate plugin for normal and ZP anymore! One for all!
#define LIBRARY_ZP "zp50_core"
#include <zombieplague>

// only enable if you're using my CSO Hud mod
//#define ENABLE_HUDMOD

#if defined ENABLE_HUDMOD
	#include <md_csohud>
#endif

#define PLUGIN "Skull Series"
#define VERSION "3.0"
#define AUTHOR "Asdian"

// Vars
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame

enum _:SkullWpnKey
{
	SKULL1_KEY = 8152022,
	SKULL2_KEY,
	SKULL3_KEY,
	SKULL4_KEY,
	SKULL5_KEY,
	SKULL6_KEY,
	SKULL7_KEY,
	SKULL8_KEY,
	SKULL11_KEY
}

#define ANIMEXT_DUAL		"dualpistols"
#define ANIMEXT_SKULLAXE	"knife" //"skullaxe"
#define ANIMEXT_DEFAULT		"carbine"
#define ANIMEXT_DEFAULT_PISTOL	"onehanded"

#define TOTAL_SKULL 10

enum _:WhichSkull
{
	IS_SK1 = 0,
	IS_SK2,
	IS_SK3,
	IS_SK4,
	IS_SK5,
	IS_SK6,
	IS_SK7,
	IS_SK8,
	IS_SK9,
	IS_SK11
}

new const WEAPON_NAMES[][] = 
{ 
	"", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
	"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
	"weapon_ak47", "weapon_knife", "weapon_p90"
}

new const WEAPON_AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }
new const CSWPN_POSITION[] = { 0,3,0,9,1,12,3,13,14,3,5,6,15,16,17,18,4,2,2,7,4,5,6,11,3,2,1,10,1,1,8,0}

// Global vars
new g_is_attacking[33], Float:g_recoil[33], g_blood[2], g_smokepuff_spr, clip_shell, g_zoomed[33], g_had_wpnskull[33][TOTAL_SKULL], g_Sk_Clip[33][2], g_type[33][3], g_drop[33], g_reg
#define ENABLE_SKULLAXE_BUG

// skull 1
new g_anim[33], g_sk1_mode[33], cvar_sk1_damage, cvar_sk1_maxclip, cvar_sk1_bpammo, cvar_sk1_speed[2]

// skull 2
new g_sk2_mode[33], cvar_sk2_damage[2], cvar_sk2_maxclip[2], cvar_sk2_bpammo, cvar_sk2_speed[2]

// skull 3
new g_skull3_mode[33], g_skull3_ammo[33], g_skull3_changing[33], g_remove_ent[33], g_skull3_m2_ammo[33]
new cvar_sk3_recoil[2], cvar_sk3_maxclip[2], cvar_sk3_rof[2], cvar_sk3_damage[2], cvar_decrease_speed, cvar_sk3_bpammo

// skull 4
new cvar_sk4_damage, cvar_sk4_maxclip, cvar_sk4_bpammo, cvar_sk4_speed, cvar_sk4_recoil

// skull 5
new cvar_sk5_damage, cvar_sk5_maxclip, cvar_sk5_bpammo, cvar_sk5_speed[2], cvar_sk5_recoil

// skull 6
new cvar_sk6_damage, cvar_sk6_maxclip, cvar_sk6_bpammo, cvar_sk6_speed, cvar_sk6_recoil

// skull 7
new cvar_sk7_damage, cvar_sk7_maxclip, cvar_sk7_bpammo, cvar_sk7_speed, cvar_sk7_recoil

// skull 8
new cvar_sk8_damage[2], cvar_sk8_maxclip, cvar_sk8_bpammo, cvar_sk8_speed, cvar_sk8_recoil, cvar_sk8_kniferange, cvar_sk8_knifeangle, cvar_sk8_knifekb

// skull 9
new cvar_sk9_damage[2], cvar_sk9_range[2], cvar_sk9_angle, cvar_sk9_kb[2]

// skull 11
new cvar_sk11_damage[2], cvar_sk11_maxclip, cvar_sk11_bpammo, cvar_sk11_speed[2], cvar_sk11_recoil, g_sk11_mode[33]

// bcse im lazy (random from 0.01 to this value)
#define DEFAULT_MAX_ACC 0.7

#define SLOT_PRI 1
#define SLOT_SEC 2
#define SLOT_MEL 3

new const V_MODEL_SKULL[][] = 
{
	"models/v_skull1.mdl",
	"models/v_skull2.mdl",
	"models/v_skull3.mdl",
	"models/v_skull4.mdl",
	"models/v_skull5.mdl",
	"models/v_skull6.mdl",
	"models/v_m249ex.mdl",
	"models/v_skull8.mdl",
	"models/v_skullaxe.mdl",
	"models/v_skull11.mdl"
}

new const P_MODEL_SKULL[][] = 
{
	"models/p_skull1.mdl",
	"models/p_skull2.mdl",
	"models/p_skull3.mdl",
	"models/p_skull4.mdl",
	"models/p_skull5.mdl",
	"models/p_skull6.mdl",
	"models/p_m249ex.mdl",
	"models/p_skull8.mdl",
	"models/p_skullaxe.mdl",
	"models/p_skull11.mdl",
	
	"models/p_skull2dual.mdl",
	"models/p_skull3dual.mdl",
}

new const W_MODEL_SKULL[] = "models/w_skull_series.mdl"

new const S_SOUND[][] =
{
	"weapons/skull1-1.wav",
	"weapons/skull2-1.wav",
	"weapons/skull3-1.wav",
	"weapons/skull4_shoot1.wav",
	"weapons/skull5-1.wav",
	"weapons/skull6-1.wav",
	"weapons/m249ex.wav",
	"weapons/skull8-1.wav",
	"weapons/skull8-2.wav",
	"weapons/skull11_1.wav",
	"weapons/skull8_shoot3.wav",
	"weapons/skull8_shoot4.wav"
}

new const Skullaxe_Sounds[][] = 
{
	"weapons/skullaxe_draw.wav",
	"weapons/skullaxe_hit.wav", // 1
	"weapons/skullaxe_miss.wav",
	"weapons/skullaxe_slash1.wav",
	"weapons/skullaxe_slash2.wav",
	"weapons/skullaxe_wall.wav" // 5
}

new const SKULL_WEAPONSPR[][] = 
{
	"weapon_skull1",
	"weapon_skull2",
	"weapon_skull3",
	"weapon_skull4",
	"weapon_skull5",
	"weapon_skull6",
	"weapon_m249ex",
	"weapon_skull8",
	"knife_skullaxe",
	"weapon_skull11",
	
	"weapon_skull3d"
}

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_METAL			2
#define	RESULT_HIT_GENERIC			3

new g_item[TOTAL_SKULL]

const CSWPN_NOTREMOVE = (1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_C4)
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

//Weapon/Player Offset
const OFFSET_WEAPON = 4
const OFFSET_PLAYER = 5
const m_pPlayer = 41
const m_iId = 43
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack = 47
const m_flTimeWeaponIdle = 48
const m_iClip = 51
const m_fInReload = 54
const m_flAccuracy = 62
const m_iShotsFired = 64
const m_flNextAttack = 83
const m_iTeam = 114
const m_iFOV = 363
const m_pActiveItem = 373
const m_szAnimExtention = 492

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "Event_Death")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")	
	
	RegisterHam(Ham_TraceAttack, "func_wall", "ham_traceattack")
	RegisterHam(Ham_TraceAttack, "func_door", "ham_traceattack")
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "ham_traceattack")
	RegisterHam(Ham_TraceAttack, "func_plat", "ham_traceattack")
	RegisterHam(Ham_TraceAttack, "func_rotating", "ham_traceattack")
	RegisterHam(Ham_TraceAttack, "func_breakable", "ham_traceattack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "ham_traceattack")
	RegisterHam(Ham_TraceAttack, "player", "ham_traceattack")
				
	for(new i = 1; i <= CSW_P90; i++)
	{
		if (strlen(WEAPON_NAMES[i]) && !(CSWPN_NOTREMOVE & (1<<i)))
		{
			RegisterHam(Ham_Item_PostFrame, WEAPON_NAMES[i], "HamF_ItemPostFrame")
				
			if(!((1<<CSW_KNIFE) & (1<<i)))
			{
				RegisterHam(Ham_Item_AddToPlayer, WEAPON_NAMES[i], "HamF_AddToPlayer_Wpn", 1)
				RegisterHam(Ham_Item_Deploy, WEAPON_NAMES[i], "HamF_ItemDeploy_Post", 1)
				RegisterHam(Ham_Weapon_Reload, WEAPON_NAMES[i], "HamF_WeaponReload")
				RegisterHam(Ham_Weapon_Reload, WEAPON_NAMES[i], "HamF_WeaponReload_Post", 1)
				RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_NAMES[i], "HamF_WeaponPrimaryAttack")
				RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_NAMES[i], "HamF_WeaponPrimaryAttack_Post", 1)
			}
		}
	}
	
	cvar_sk1_speed[0] = register_cvar("skull1_speed1", "0.24")
	cvar_sk1_speed[1] = register_cvar("skull1_speed2", "0.14586")
	cvar_sk1_damage = register_cvar("skull1_dmg", "75.0")
	cvar_sk1_maxclip = register_cvar("skull1_clip", "7")
	cvar_sk1_bpammo = register_cvar("skull1_ammo", "70")
	
	cvar_sk2_speed[0] = register_cvar("skull2_speed_d", "0.17")
	cvar_sk2_speed[1] = register_cvar("skull2_speed_s", "0.23")
	cvar_sk2_damage[0] = register_cvar("skull2_dmg_d", "45.0")
	cvar_sk2_damage[1] = register_cvar("skull2_dmg_s", "82.0")
	cvar_sk2_maxclip[0] = register_cvar("skull2_clip_d", "14")
	cvar_sk2_maxclip[1] = register_cvar("skull2_clip_s", "7")
	cvar_sk2_bpammo = register_cvar("skull2_ammo", "70")
	
	cvar_sk3_recoil[0] = register_cvar("skull3_recoil_m1", "0.46")
	cvar_sk3_recoil[1] = register_cvar("skull3_recoil_m2", "0.56")
	cvar_sk3_maxclip[0] = register_cvar("skull3_clip_m1", "35")
	cvar_sk3_maxclip[1] = register_cvar("skull3_clip_m2", "70")
	cvar_sk3_bpammo = register_cvar("skull3_clip_m2", "200")
	cvar_sk3_rof[0] = register_cvar("skull3_speed_m1", "0.091")
	cvar_sk3_rof[1] = register_cvar("skull3_speed_m2", "0.074")
	cvar_sk3_damage[0] = register_cvar("skull3_damage_m1", "27")
	cvar_sk3_damage[1] = register_cvar("skull3_damage_m2", "31")
	cvar_decrease_speed = register_cvar("skull3_decrease_speed", "160.0")
	
	cvar_sk4_bpammo = register_cvar("skull4_ammo", "200")
	cvar_sk4_damage = register_cvar("skull4_dmg", "66.0")
	cvar_sk4_maxclip = register_cvar("skull4_clip", "48")
	cvar_sk4_recoil = register_cvar("skull4_recoil", "0.45")
	cvar_sk4_speed = register_cvar("skull4_speed", "0.204")
	
	cvar_sk5_bpammo = register_cvar("skull5_ammo", "200")
	cvar_sk5_damage = register_cvar("skull5_dmg", "91.0")
	cvar_sk5_maxclip = register_cvar("skull5_clip", "24")
	cvar_sk5_recoil = register_cvar("skull5_recoil", "1.65")
	cvar_sk5_speed[0] = register_cvar("skull5_speed", "0.28")
	cvar_sk5_speed[1] = register_cvar("skull5_speed_zoomed", "0.34")
	
	cvar_sk6_bpammo = register_cvar("skull6_ammo", "200")
	cvar_sk6_damage = register_cvar("skull6_dmg", "41.0")
	cvar_sk6_maxclip = register_cvar("skull6_clip", "100")
	cvar_sk6_recoil = register_cvar("skull6_recoil", "0.75")
	cvar_sk6_speed = register_cvar("skull6_speed", "0.1275")
	
	cvar_sk7_bpammo = register_cvar("skull7_ammo", "240")
	cvar_sk7_damage = register_cvar("skull7_dmg", "43.0")
	cvar_sk7_maxclip = register_cvar("skull7_clip", "120")
	cvar_sk7_recoil = register_cvar("skull7_recoil", "0.75")
	cvar_sk7_speed = register_cvar("skull7_speed", "0.1275")
	
	cvar_sk8_bpammo = register_cvar("skull8_ammo", "240")
	cvar_sk8_damage[0] = register_cvar("skull8_dmg", "32.0")
	cvar_sk8_damage[1] = register_cvar("skull8_dmg_knife", "1150.0")
	cvar_sk8_maxclip = register_cvar("skull8_clip", "120")
	cvar_sk8_recoil = register_cvar("skull8_recoil", "0.75")
	cvar_sk8_speed = register_cvar("skull8_speed", "0.1275")
	cvar_sk8_kniferange = register_cvar("skull8_kniferange", "65.0")
	cvar_sk8_knifeangle = register_cvar("skull8_knifeangle", "170.0")
	cvar_sk8_knifekb = register_cvar("skull8_knifekb", "25.0")
	
	cvar_sk9_damage[0] = register_cvar("skull9_slash_dmg", "50.0")
	cvar_sk9_damage[1] = register_cvar("skull9_stab_dmg", "80.0")
	cvar_sk9_range[0] = register_cvar("skull9_slash_range", "115.0")
	cvar_sk9_range[1] = register_cvar("skull9_stab_range", "105.0")
	cvar_sk9_angle = register_cvar("skull9_stab_angle", "120.0")
	cvar_sk9_kb[0] = register_cvar("skull9_slash_kb", "1.0")
	cvar_sk9_kb[1] = register_cvar("skull9_stab_kb", "1.0")

	cvar_sk11_bpammo = register_cvar("skull11_ammo", "40")
	cvar_sk11_damage[0] = register_cvar("skull11_dmg_buckshot", "43.0")
	cvar_sk11_damage[1] = register_cvar("skull11_dmg_slug", "47.0")
	cvar_sk11_maxclip = register_cvar("skull11_clip", "28")
	cvar_sk11_recoil = register_cvar("skull11_recoil", "0.75")
	cvar_sk11_speed[0] = register_cvar("skull11_speed_buckshot", "0.29")
	cvar_sk11_speed[1] = register_cvar("skull11_speed_slug", "0.52")
	
	if (!LibraryExists(LIBRARY_ZP, LibType_Library))
		register_clcmd("say", "CmdSay");
	
	for(new i = 0; i < TOTAL_SKULL; i++)
	{
		if (LibraryExists(LIBRARY_ZP, LibType_Library))
		{
			new szName[32]
			if(i == (TOTAL_SKULL - 1)) format(szName, 31, "Skull-11")
			else format(szName, 31, "Skull-%d", i+1)
			g_item[i] = zp_register_extra_item(szName, 0, ZP_TEAM_HUMAN)
		}
		
		if(i <= IS_SK2) register_clcmd(SKULL_WEAPONSPR[i], "hook_sk1")
		else if(i == IS_SK9) register_clcmd(SKULL_WEAPONSPR[i], "hook_change_weapon3")
		else if(i == (TOTAL_SKULL - 1)) register_clcmd(SKULL_WEAPONSPR[IS_SK11+1], "hook_change_weapon2")
		else register_clcmd(SKULL_WEAPONSPR[i], "hook_change_weapon1")
	}
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, W_MODEL_SKULL)
	
	new i
	for(i = 0; i < sizeof(S_SOUND); i++) engfunc(EngFunc_PrecacheSound, S_SOUND[i])
	for(i = 0; i < sizeof(Skullaxe_Sounds); i++) engfunc(EngFunc_PrecacheSound, Skullaxe_Sounds[i])
	for(i = 0; i < sizeof(V_MODEL_SKULL); i++)  engfunc(EngFunc_PrecacheModel, V_MODEL_SKULL[i])
	for(i = 0; i < sizeof(P_MODEL_SKULL); i++) engfunc(EngFunc_PrecacheModel, P_MODEL_SKULL[i])
	for(i = 0; i < sizeof(SKULL_WEAPONSPR); i++)
	{
		new szSpr[32]
		format(szSpr, charsmax(szSpr), "sprites/%s.txt", SKULL_WEAPONSPR[i])
		engfunc(EngFunc_PrecacheGeneric, szSpr)
	}
	
	g_blood[0] = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
	g_blood[1] = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")			
	clip_shell = engfunc(EngFunc_PrecacheModel, "models/rshell.mdl")
	g_smokepuff_spr = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
}

public zp_extra_item_selected(id, itemid)
{
	for(new i = 0; i < TOTAL_SKULL; i++)
	{
		if(itemid != g_item[i])
			continue
		
		if(i <= IS_SK2) give_skull_weapons(id, SLOT_SEC, i)
		else if(i == IS_SK9) give_skull_weapons(id, SLOT_MEL, i)
		else give_skull_weapons(id, SLOT_PRI, i)
	}
}

public zp_user_humanized_post(id) remove_all(id)
public zp_user_infected_post(id) remove_all(id)

public hook_sk1(id) 
{
	static iCSW; iCSW = Get_SkullCSW(id, SLOT_SEC)
	engclient_cmd(id, WEAPON_NAMES[iCSW])
}

public hook_change_weapon1(id) 
{
	static iCSW; iCSW = Get_SkullCSW(id, SLOT_PRI)
	engclient_cmd(id, WEAPON_NAMES[iCSW])
}

public hook_change_weapon2(id) 
{
	static iCSW; iCSW = Get_SkullCSW(id, SLOT_PRI, 1)
	engclient_cmd(id, WEAPON_NAMES[iCSW])
}

public hook_change_weapon3(id) 
{
	static iCSW; iCSW = Get_SkullCSW(id, SLOT_MEL)
	engclient_cmd(id, WEAPON_NAMES[iCSW])
	return PLUGIN_HANDLED
}

public client_putinserver(id)
{
	if(!g_reg && is_user_bot(id))
	{
		g_reg = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{	
	RegisterHamFromEntity(Ham_TraceAttack, id, "ham_traceattack")
}

public remove_all(id)
{
	for(new i = 0; i < TOTAL_SKULL; i++)
		remove_skull(id, i)
}

public CmdSay(id)
{
	new args[194];
	read_args(args, charsmax(args));
	remove_quotes(args);
    
	new command[32];
	argbreak(args, command, charsmax(command), args, charsmax(args));
	
	if(equali(command, "/sk") && args[0]) 
	{
		if(!is_str_num(args)) 
		{
			client_print(id, print_center, "invalid command")
			return PLUGIN_CONTINUE
		}
		
		new wut = str_to_num(args);
		if(!wut || wut == 10 || wut > 11) 
		{
			client_print(id, print_center, "invalid command")
			return PLUGIN_CONTINUE
		}
		
		if(wut == 9) give_skull_weapons(id, SLOT_MEL, IS_SK9)
		else give_skull_weapons(id, (wut <= 2) ? SLOT_SEC : SLOT_PRI, (wut == 11) ? (wut-2):(wut-1))
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public give_skull_weapons(id, slot, wut)
{
	if(!is_user_alive(id))
		return
	
	if(slot != SLOT_MEL) drop_weapons(id, slot)
	
	g_had_wpnskull[id][wut] = 1
	g_type[id][slot-1] = wut
			
	static iCSW, ActiveSlot, ent
	iCSW = Get_SkullCSW(id, slot)
	fm_give_item(id, WEAPON_NAMES[iCSW])
	
	switch (slot)
	{
		case 1:
		{
			g_zoomed[id] = 0
			
			if(wut == IS_SK3)
			{
				g_skull3_mode[id] = 0
				g_skull3_ammo[id] = Get_SkullMaxBpAmmo(id, 1)
				g_skull3_changing[id] = 0
				g_drop[id] = 0
			
				static iCSW2, ent2;
				iCSW2 = Get_SkullCSW(id, SLOT_PRI, 1)
				fm_give_item(id, WEAPON_NAMES[iCSW2])
				
				ent2 = fm_get_user_weapon_entity(id, iCSW2)
				if(pev_valid(ent2)) cs_set_weapon_ammo(ent2, Get_SkullMaxClip(id, 1, 1))
				cs_set_user_bpammo(id, iCSW2, g_skull3_ammo[id])
				
				engclient_cmd(id, WEAPON_NAMES[iCSW])
			}
			
			if(wut == IS_SK11) g_sk11_mode[id] = 0
		}
		case 2:
		{
			if(wut == IS_SK1) g_sk1_mode[id] = 0
			if(wut == IS_SK2) g_sk2_mode[id] = 0
		}
	}
	
	if(slot == SLOT_MEL)
	{
		if(get_user_weapon(id) == iCSW && wut == IS_SK9)
		{
			set_weapon_anim(id, 3)
			set_pdata_float(id, 83, 1.4, 5)
			set_pdata_string(id, 492 * 4, ANIMEXT_SKULLAXE, -1 , 20)
		} else engclient_cmd(id, WEAPON_NAMES[iCSW])
		
		set_weapon_list(id, g_had_wpnskull[id][wut] == 1 ? SKULL_WEAPONSPR[wut] : WEAPON_NAMES[iCSW], -1, -1, -1, -1, 2, 1, iCSW)
		
		#if defined ENABLE_HUDMOD
		mdcsohud_regwpnhud(id, iCSW, SKULL_WEAPONSPR[wut])
		#endif
	} else {
		ent = fm_get_user_weapon_entity(id, iCSW)
		if(!pev_valid(ent)) return
		ActiveSlot = Get_WeaponSlot(id)
		
		cs_set_weapon_ammo(ent, Get_SkullMaxClip(id, slot))
		cs_set_user_bpammo(id, iCSW, Get_SkullMaxBpAmmo(id, slot))
		
		if(ActiveSlot == slot) Update_Ammo(id, iCSW, Get_SkullMaxClip(id, slot))
	}
}

public remove_skull(id, wut)
{
	if(!is_user_connected(id))
		return
	
	#if defined ENABLE_HUDMOD
	static iCSW, iCSWd
	iCSW = Get_SkullCSW(id, Get_WeaponSlot(id))
	iCSWd = Get_SkullCSW(id, SLOT_PRI, 1)
	
	mdcsohud_resetwpnhud(id, iCSW)
	mdcsohud_resetwpnhud(id, iCSWd)
	#endif
	
	g_had_wpnskull[id][wut] = 0
	g_zoomed[id] = 0
	g_type[id][0] = g_type[id][1] = g_type[id][2] = 0
	
	switch(wut)
	{
		case IS_SK2: g_sk2_mode[id] = 0
		case IS_SK3:
		{
			g_skull3_mode[id] = 0
			g_skull3_ammo[id] = 0
			g_skull3_changing[id] = 0
		}
		case IS_SK11: g_sk11_mode[id] = 0
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) == CSW_KNIFE)
		return FMRES_IGNORED
	
	new iWpn = get_user_weapon(id)
	
	if((IsHaveSkull(id, SLOT_PRI) && (iWpn == Get_SkullCSW(id, 1) || iWpn == Get_SkullCSW(id, 1, 1))) || (IsHaveSkull(id, SLOT_SEC) && iWpn == Get_SkullCSW(id, 2)))
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001)
		
	return FMRES_IGNORED
}

public fw_SetModel(ent, model[])
{
	if(!is_valid_ent(ent))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(ent, pev_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(equal(model, "models/w_deagle.mdl"))
	{
		static weapon, iCSW;
		iCSW = Get_SkullCSW(id, SLOT_SEC)
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[iCSW], ent)
	
		if(!pev_valid(weapon))
			return FMRES_IGNORED
	
		if(g_had_wpnskull[id][IS_SK1])
		{
			set_pev(weapon, pev_impulse, SKULL1_KEY)
			g_had_wpnskull[id][IS_SK1] = 0
			
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
			set_pev(ent, pev_body, IS_SK1)
			return FMRES_SUPERCEDE
		}
	} 
	
	if(equal(model, "models/w_fiveseven.mdl"))
	{
		static weapon, iCSW;
		iCSW = Get_SkullCSW(id, SLOT_SEC)
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[iCSW], ent)
	
		if(!pev_valid(weapon))
			return FMRES_IGNORED
	
		if(g_had_wpnskull[id][IS_SK2])
		{
			set_pev(weapon, pev_impulse, SKULL2_KEY)
			
			g_had_wpnskull[id][IS_SK2] = 0
			g_sk2_mode[id] = 0
			
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
			set_pev(ent, pev_body, IS_SK2)
			return FMRES_SUPERCEDE
		}
	} 
	
	if(equal(model, "models/w_mp5.mdl")) 
	{
		static weapon, iCSW
		iCSW = Get_SkullCSW(id, SLOT_PRI)
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[iCSW], ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
	
		if(g_had_wpnskull[id][IS_SK3])
		{
			static weapon2, iCSW2
			iCSW2 = Get_SkullCSW(id, SLOT_PRI, 1)
			weapon2 = find_ent_by_owner(-1, WEAPON_NAMES[iCSW2], id)
			
			if(pev_valid(weapon2))
			{
				g_skull3_m2_ammo[id] = cs_get_weapon_ammo(weapon2)
				g_remove_ent[id] = ent
				g_had_wpnskull[id][IS_SK3] = 0
				g_drop[id] = 1
				
				engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
				set_pev(ent, pev_body, IS_SK3)
				
				reset_player_maxspeed(id)					
				remove_gun(id, iCSW2)
				
				set_pev(weapon, pev_impulse, SKULL3_KEY)
				return FMRES_SUPERCEDE
			}
		}
	} 
	
	if(equal(model, "models/w_p90.mdl")) 
	{
		static weapon, iCSW;
		iCSW = Get_SkullCSW(id, SLOT_PRI, 1)
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[iCSW], ent)
	
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_wpnskull[id][IS_SK3])
		{
			static weapon1, iCSW1
			iCSW1 = Get_SkullCSW(id, SLOT_PRI)
			weapon1 = find_ent_by_owner(-1, WEAPON_NAMES[iCSW1], id)	
			
			if(pev_valid(weapon1))
			{
				g_skull3_m2_ammo[id] = cs_get_weapon_ammo(weapon1)
				g_remove_ent[id] = ent
				g_had_wpnskull[id][IS_SK3] = 0
				g_drop[id] = 2
				
				engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
				set_pev(ent, pev_body, IS_SK3)
				
				reset_player_maxspeed(id)
				remove_gun(id, iCSW1)
				
				set_pev(weapon, pev_impulse, SKULL3_KEY)
				return FMRES_SUPERCEDE
			}
		}
	}
	
	if(equal(model, "models/w_ak47.mdl")) 
	{
		static weapon, iCSW;
		iCSW = Get_SkullCSW(id, SLOT_PRI)
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[iCSW], ent)
	
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_wpnskull[id][IS_SK4])
		{
			set_pev(weapon, pev_impulse, SKULL4_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
			set_pev(ent, pev_body, IS_SK4)
			
			g_had_wpnskull[id][IS_SK4] = 0
			return FMRES_SUPERCEDE
		}
	}
	
	if(equal(model, "models/w_g3sg1.mdl"))
	{
		static weapon, iCSW;
		iCSW = Get_SkullCSW(id, SLOT_PRI)
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[iCSW], ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_wpnskull[id][IS_SK5])
		{
			set_pev(weapon, pev_impulse, SKULL5_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
			set_pev(ent, pev_body, IS_SK5)
			
			g_had_wpnskull[id][IS_SK5] = 0
			return FMRES_SUPERCEDE
		}
	}
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static weapon, iCSW;
		iCSW = Get_SkullCSW(id, SLOT_PRI)
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[iCSW], ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_wpnskull[id][IS_SK6])
		{
			set_pev(weapon, pev_impulse, SKULL6_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
			set_pev(ent, pev_body, IS_SK6)
			
			g_had_wpnskull[id][IS_SK6] = 0
			return FMRES_SUPERCEDE
		}
		
		if(g_had_wpnskull[id][IS_SK7])
		{
			set_pev(weapon, pev_impulse, SKULL7_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
			set_pev(ent, pev_body, IS_SK7)
			
			g_had_wpnskull[id][IS_SK7] = 0
			return FMRES_SUPERCEDE
		}
		
		if(g_had_wpnskull[id][IS_SK8])
		{
			set_pev(weapon, pev_impulse, SKULL8_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
			set_pev(ent, pev_body, IS_SK8)
			
			g_had_wpnskull[id][IS_SK8] = 0
			return FMRES_SUPERCEDE
		}
	}
	
	if(equal(model, "models/w_xm1014.mdl"))
	{
		static weapon, iCSW;
		iCSW = Get_SkullCSW(id, SLOT_PRI)
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[iCSW], ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_wpnskull[id][IS_SK11])
		{
			set_pev(weapon, pev_impulse, SKULL11_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL)
			set_pev(ent, pev_body, IS_SK11)
			
			g_had_wpnskull[id][IS_SK11] = 0
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public remove_gun(id, CSW) 
{ 
	new weapons[32], num = 0
	get_user_weapons(id, weapons, num) 
	
	for(new i = 0; i < num; i++)
		if(weapons[i] == CSW) fm_strip_user_gun(id, weapons[i])
} 

public ham_traceattack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED
	if(get_user_weapon(attacker) == CSW_KNIFE)
		return HAM_IGNORED
	
	static ActiveSlot, iWPN, iCSWd, iCSW, isDouble, iSlot
	ActiveSlot = Get_WeaponSlot(attacker)
	iCSW = get_user_weapon(attacker)
	
	if(!IsHaveSkull(attacker, ActiveSlot))
		return HAM_IGNORED
	
	isDouble = IsSk3d(attacker)
	iSlot = (ActiveSlot-1)
	iWPN = Get_SkullCSW(attacker, ActiveSlot)
	iCSWd = Get_SkullCSW(attacker, SLOT_PRI, 1)
	
	static Float:flEnd[3], Float:Damage_New, body
	get_tr2(ptr, TR_vecEndPos, flEnd)
	body = get_tr2(ptr, TR_iHitgroup)
	
	if(iCSW == iWPN || iCSW == iCSWd) // ... idk :/ as long as it works
	{
		if(g_type[attacker][iSlot] == IS_SK1) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk1_damage))
		else if(g_type[attacker][iSlot] == IS_SK2) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk2_damage[g_sk2_mode[attacker]]))
		else if(g_type[attacker][iSlot] == IS_SK3) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk3_damage[isDouble]))
		else if(g_type[attacker][iSlot] == IS_SK4) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk4_damage))
		else if(g_type[attacker][iSlot] == IS_SK5) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk5_damage))
		else if(g_type[attacker][iSlot] == IS_SK6) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk6_damage))
		else if(g_type[attacker][iSlot] == IS_SK7) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk7_damage))
		else if(g_type[attacker][iSlot] == IS_SK8) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk8_damage[0]))
		else if(g_type[attacker][iSlot] == IS_SK11) Damage_New = get_damage_body(body, get_pcvar_float(cvar_sk11_damage[g_sk11_mode[attacker]]))
		
		if(g_is_attacking[attacker]) make_bullet(attacker, flEnd)
		SetHamParamFloat(3, Damage_New)
	}
	return HAM_IGNORED
}

public Float:get_damage_body(body, Float:damage)
{
	switch(body)
	{
		case HIT_HEAD: damage *= 2.0
		case HIT_CHEST: damage *= 1.5
		case HIT_STOMACH: damage *= 1.25
		case HIT_LEFTARM | HIT_RIGHTARM: damage *= 1.20
		case HIT_LEFTLEG | HIT_RIGHTLEG: damage *= 1.15
		default: damage *= 1.0
	}
	return damage
}

public HamF_AddToPlayer_Wpn(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(pev(ent, pev_impulse) == SKULL1_KEY)
	{
		g_had_wpnskull[id][IS_SK1] = 1
		g_type[id][1] = IS_SK1
		set_pev(ent, pev_impulse, 0)
	}
	
	if(pev(ent, pev_impulse) == SKULL2_KEY)
	{
		g_had_wpnskull[id][IS_SK2] = 1
		g_type[id][1] = IS_SK2
		set_pev(ent, pev_impulse, 0)
	}
	
	if(pev(ent, pev_impulse) == SKULL3_KEY)
	{
		if(pev_valid(g_remove_ent[id]))
		{
			set_pev(g_remove_ent[id], pev_renderfx, kRenderFxGlowShell)
			set_pev(g_remove_ent[id], pev_rendermode, kRenderTransAlpha)
			set_pev(g_remove_ent[id], pev_renderamt, 0)
			set_pev(g_remove_ent[id], pev_solid, SOLID_NOT)
			set_pev(g_remove_ent[id], pev_movetype, MOVETYPE_NONE)
			set_pev(g_remove_ent[id], pev_flags, FL_KILLME)
		}
		
		g_had_wpnskull[id][IS_SK3] = 1
		g_type[id][0] = IS_SK3
		set_pev(ent, pev_impulse, 0)
		
		g_skull3_mode[id] = (g_drop[id] - 1)
		g_drop[id] = 0
		
		static iCSW1, iCSW2
		iCSW1 = Get_SkullCSW(id, SLOT_PRI)
		iCSW2 = Get_SkullCSW(id, SLOT_PRI, 1)
		
		client_cmd(id, WEAPON_NAMES[g_skull3_mode[id] ? iCSW2 : iCSW1])
		fm_give_item(id, WEAPON_NAMES[g_skull3_mode[id] ? iCSW1 : iCSW2])
		
		static weapon
		weapon = find_ent_by_owner(-1, WEAPON_NAMES[g_skull3_mode[id] ? iCSW1 : iCSW2], id)		
		if(pev_valid(weapon)) cs_set_weapon_ammo(weapon, g_skull3_m2_ammo[id])
		
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL[IS_SK3])
		set_pev(id, pev_weaponmodel2, P_MODEL_SKULL[g_skull3_mode[id] ? (IS_SK11+1) : IS_SK3])
	}
	
	if(pev(ent, pev_impulse) == SKULL4_KEY)
	{
		g_had_wpnskull[id][IS_SK4] = 1
		g_type[id][0] = IS_SK4
		set_pev(ent, pev_impulse, 0)
	}
	
	if(pev(ent, pev_impulse) == SKULL5_KEY)
	{
		g_had_wpnskull[id][IS_SK5] = 1
		g_type[id][0] = IS_SK5
		set_pev(ent, pev_impulse, 0)
	}
	
	if(pev(ent, pev_impulse) == SKULL6_KEY)
	{
		g_had_wpnskull[id][IS_SK6] = 1
		g_type[id][0] = IS_SK6
		set_pev(ent, pev_impulse, 0)
	}
	
	if(pev(ent, pev_impulse) == SKULL7_KEY)
	{
		g_had_wpnskull[id][IS_SK7] = 1
		g_type[id][0] = IS_SK7
		set_pev(ent, pev_impulse, 0)
	}
	
	if(pev(ent, pev_impulse) == SKULL8_KEY)
	{
		g_had_wpnskull[id][IS_SK8] = 1
		g_type[id][0] = IS_SK8
		set_pev(ent, pev_impulse, 0)
	}
	
	if(pev(ent, pev_impulse) == SKULL11_KEY)
	{
		g_had_wpnskull[id][IS_SK11] = 1
		g_type[id][0] = IS_SK11
		set_pev(ent, pev_impulse, 0)
	}
	
	static iCSW1, iCSW2, iSlot, sTxt1[32], sTxt2[32], iMaxAmmo
	iSlot = Get_WeaponSlot(id, ent)
	iCSW1 = Get_SkullCSW(id, iSlot)
	iCSW2 = Get_SkullCSW(id, SLOT_PRI, 1)
	iMaxAmmo = Get_SkullMaxBpAmmo(id, iSlot)
	formatex(sTxt1,31,IsHaveSkull(id, iSlot) ? SKULL_WEAPONSPR[g_type[id][iSlot-1]] : WEAPON_NAMES[iCSW1])
	formatex(sTxt2,31,IsHaveSkull(id, iSlot) ? SKULL_WEAPONSPR[IS_SK11+1] : WEAPON_NAMES[iCSW2])
	
	set_weapon_list(id, sTxt1, WEAPON_AMMOID[iCSW1], iMaxAmmo, -1, -1, iSlot - 1, CSWPN_POSITION[iCSW1], iCSW1)
	if(iSlot == SLOT_PRI && g_had_wpnskull[id][IS_SK3]) set_weapon_list(id, sTxt2, WEAPON_AMMOID[iCSW2], iMaxAmmo, -1, -1, iSlot - 1, CSWPN_POSITION[iCSW2], iCSW2)
	
	return HAM_IGNORED
}

stock Get_SkullMaxBpAmmo(id, ActiveSlot)
{
	static iSlot; iSlot = (ActiveSlot-1)
	if(g_type[id][iSlot] == IS_SK1) return get_pcvar_num(cvar_sk1_bpammo)
	else if(g_type[id][iSlot] == IS_SK2) return get_pcvar_num(cvar_sk2_bpammo)
	else if(g_type[id][iSlot] == IS_SK3) return get_pcvar_num(cvar_sk3_bpammo)
	else if(g_type[id][iSlot] == IS_SK4) return get_pcvar_num(cvar_sk4_bpammo)
	else if(g_type[id][iSlot] == IS_SK5) return get_pcvar_num(cvar_sk5_bpammo)
	else if(g_type[id][iSlot] == IS_SK6) return get_pcvar_num(cvar_sk6_bpammo)
	else if(g_type[id][iSlot] == IS_SK7) return get_pcvar_num(cvar_sk7_bpammo)
	else if(g_type[id][iSlot] == IS_SK8) return get_pcvar_num(cvar_sk8_bpammo)
	else if(g_type[id][iSlot] == IS_SK11) return get_pcvar_num(cvar_sk11_bpammo)
	return 0
}

public Get_SkullDeployAnim(id, ActiveSlot, iClip)
{
	static iSlot; iSlot = (ActiveSlot-1)
	if(g_type[id][iSlot] == IS_SK1) return 7
	else if(g_type[id][iSlot] == IS_SK2) return g_sk2_mode[id] ? 2 : ((iClip == 1) ? 17:14)
	else if(g_type[id][iSlot] == IS_SK4) return (iClip == 1) ? 10 : 9
	else if(g_type[id][iSlot] == IS_SK9) return 3
	return 4
}

public Float:Get_SkullDeployTime(id, ActiveSlot)
{
	static iSlot; iSlot = (ActiveSlot-1)
	if(g_type[id][iSlot] == IS_SK1) return 1.3
	else if(g_type[id][iSlot] == IS_SK2) return g_sk2_mode[id] ? 1.03 : 1.37
	else if(g_type[id][iSlot] == IS_SK4) return 1.23
	else if(g_type[id][iSlot] == IS_SK5) return 1.53
	else if(g_type[id][iSlot] == IS_SK6) return 0.93
	else if(g_type[id][iSlot] == IS_SK7) return 1.03
	else if(g_type[id][iSlot] == IS_SK8) return 1.23
	else if(g_type[id][iSlot] == IS_SK9) return 1.4
	else if(g_type[id][iSlot] == IS_SK11) return 1.2
	return 1.0
}

public Event_CurWeapon(id) // ????
{
	if(!is_user_alive(id))
		return 1
	if(!g_had_wpnskull[id][IS_SK9])
		return 1
	if(get_user_weapon(id) != CSW_KNIFE)
		return 1
		
	set_pev(id, pev_viewmodel2, V_MODEL_SKULL[IS_SK9])
	
	#if !defined ENABLE_SKULLAXE_BUG
	static iEnt; iEnt = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(iEnt)) return 1
	
	set_pev(iEnt, pev_iuser1, 0)
	set_pev(iEnt, pev_iuser2, 0)
	#endif
	return 0
}

public HamF_ItemDeploy_Post(ent)
{
	if(!pev_valid(ent))
		return 
	
	static id
	id = fm_cs_get_weapon_ent_owner(ent)
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return 
		
	static iCSWSkull, iCSWd, iCSW, ActiveSlot, iClip, iSlot, pEnt, iClipD
	iCSW = get_pdata_int(ent, m_iId, OFFSET_WEAPON)
	ActiveSlot = Get_WeaponSlot(id, ent)
	
	if(!IsHaveSkull(id, ActiveSlot))
		return 
	
	iCSWSkull = Get_SkullCSW(id, ActiveSlot)
	iCSWd = Get_SkullCSW(id, SLOT_PRI, 1)
	iClip = get_pdata_int(ent, m_iClip, OFFSET_WEAPON)
	iSlot = (ActiveSlot-1)
	
	if(iCSW == iCSWSkull || iCSW == iCSWd) // ... idk :/ as long as it works
	{
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL[g_type[id][iSlot]])
	
		if(g_type[id][iSlot] == IS_SK2 && !g_sk2_mode[id]) set_pev(id, pev_weaponmodel2, P_MODEL_SKULL[IS_SK11 + 1])
		else if(g_type[id][iSlot] == IS_SK3 && IsSk3d(id)) set_pev(id, pev_weaponmodel2, P_MODEL_SKULL[IS_SK11 + 2])
		else set_pev(id, pev_weaponmodel2, P_MODEL_SKULL[g_type[id][iSlot]])
	
		set_weapon_anim(id, Get_SkullDeployAnim(id, ActiveSlot, iClip))
		set_nextattack(ent, id, Get_SkullDeployTime(id, ActiveSlot))
		
		if((iCSW == iCSWd && g_type[id][0] == IS_SK3) || (iCSW == iCSWSkull && g_type[id][0] == IS_SK4))
			set_pdata_string(id, 492 * 4, ANIMEXT_DUAL, -1 , 20)
		
		if(g_type[id][iSlot] == IS_SK3)
		{
			if(iCSW == iCSWd)
			{
				g_skull3_changing[id] = !g_skull3_mode[id]
				set_pev(id, pev_weaponmodel2, P_MODEL_SKULL[IS_SK11 + 1])
				
				set_weapon_anim(id, (iClip == 1) ? (19 - g_skull3_mode[id]) : (16 - g_skull3_mode[id]))
				set_nextattack(ent, id, (g_skull3_mode[id] ? 1.0 : 3.03))
			} else if(iCSW == iCSWSkull) {
				g_skull3_changing[id] = g_skull3_mode[id]
				set_pev(id, pev_weaponmodel2, P_MODEL_SKULL[IS_SK3])
							
				pEnt = fm_get_user_weapon_entity(id, iCSWd)
				if(pev_valid(pEnt)) iClipD = get_pdata_int(pEnt, m_iClip, OFFSET_WEAPON)
				
				set_weapon_anim(id, g_skull3_mode[id] ? (iClipD == 1 ? 20 : 17) : 2)
				set_nextattack(ent, id, g_skull3_mode[id] ? 3.03 : 1.0)
				
				set_pdata_string(id, m_szAnimExtention * 4, ANIMEXT_DEFAULT, -1 , 20)
			}
		}
		
		if(g_type[id][iSlot] == IS_SK8)
		{
			set_pev(ent, pev_iuser2, 0)
			set_pev(ent, pev_iuser1, 0)
		}
		
		#if defined ENABLE_HUDMOD
		if(g_type[id][iSlot] == IS_SK3) mdcsohud_regwpnhud(id, iCSWd, SKULL_WEAPONSPR[IS_SK11+1])
		mdcsohud_regwpnhud(id, iCSWSkull, SKULL_WEAPONSPR[g_type[id][iSlot]])
		#endif
	}
}

public HamF_WeaponPrimaryAttack(ent)
{
	new id = get_pdata_cbase(ent, m_pPlayer, OFFSET_WEAPON)
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(!cs_get_weapon_ammo(ent))
		return
		
	static ActiveSlot, iClip;
	ActiveSlot = Get_WeaponSlot(id, ent)
	iClip = get_pdata_int(ent, m_iClip, OFFSET_WEAPON)
	
	g_is_attacking[id] = iClip ? 1 : 0;
	g_Sk_Clip[id][ActiveSlot-1] = cs_get_weapon_ammo(ent)
	pev(id, pev_punchangle, g_recoil[id])
}

public HamF_WeaponPrimaryAttack_Post(ent)
{
	new id = get_pdata_cbase(ent, m_pPlayer, OFFSET_WEAPON)
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	
	static iCSWSk, iCSWd, iCSW, ActiveSlot, isDouble, iClip, iSlot;
	iCSW = get_pdata_int(ent, m_iId, OFFSET_WEAPON)
	ActiveSlot = Get_WeaponSlot(id, ent)
	iClip = get_pdata_int(ent, m_iClip, OFFSET_WEAPON)
	iSlot = (ActiveSlot-1)
	
	if(!IsHaveSkull(id, ActiveSlot))
		return 
		
	iCSWSk = Get_SkullCSW(id, ActiveSlot)
	iCSWd = Get_SkullCSW(id, SLOT_PRI, 1)
	
	if(iCSW == iCSWSk || iCSW == iCSWd) // ... idk :/ as long as it works
	{
		if(!g_Sk_Clip[id][iSlot] || !g_is_attacking[id])
			return 
		if(ActiveSlot == SLOT_SEC && get_pdata_int(ent, m_iShotsFired, OFFSET_WEAPON) != 1)
			return
		
		engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, S_SOUND[g_type[id][iSlot]], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			
		if(g_type[id][iSlot] == IS_SK1 && !(pev(id, pev_button) & IN_ATTACK2))
		{
			set_weapon_anim(id, random_num(2, 3))
			set_nextattack(ent, id, get_pcvar_float(cvar_sk1_speed[0]))
		}
				
		if(g_type[id][iSlot] == IS_SK2)
		{
			if(g_sk2_mode[id])
			{
				set_weapon_anim(id, iClip ? 3 : 4)
				EjectBrass(id, clip_shell, -7.0, 15.0, 5.0, -20.0, -100.0)
			} else {
				static anim
				anim = Get_LRState(iClip)
				
				if(iClip < 2)
				{
					set_weapon_anim(id, iClip ? 9 : 12)
					set_extension(id, !iClip, ANIMEXT_DUAL)
				} else {
					set_weapon_anim(id, anim?random_num(7, 8):random_num(10, 11))
					set_extension(id, anim, ANIMEXT_DUAL)
				}
			}
			
			set_nextattack(ent, id, get_pcvar_float(cvar_sk2_speed[g_sk2_mode[id]]), (iClip ? 0.0 : -1.0))
		}
		
		if(g_type[id][iSlot] == IS_SK3)
		{
			isDouble = IsSk3d(id)
			
			set_recoil(id, get_pcvar_float(cvar_sk3_recoil[isDouble]))
			set_nextattack(ent, id, get_pcvar_float(cvar_sk3_rof[isDouble]), (iClip ? 0.0 : -1.0))
			
			if(!isDouble)
			{
				set_weapon_anim(id, random_num(3, 5))
				EjectBrass(id, clip_shell, -7.0, 15.0, 5.0, -20.0, -100.0)
				set_extension(id, 0, ANIMEXT_DEFAULT)
			} else {
				static anim
				anim = Get_LRState(iClip)
				
				set_pdata_float(ent, m_flAccuracy, random_float(0.01, DEFAULT_MAX_ACC), OFFSET_WEAPON)
				
				if(iClip < 2)
				{
					set_weapon_anim(id, iClip ? 10 : 13)
					EjectBrass(id, clip_shell, -7.0, 15.0, iClip ? -6.0 : 6.0, -20.0, -100.0)
					set_extension(id, !iClip, ANIMEXT_DUAL)
				} else {
					set_weapon_anim(id, anim?random_num(8, 9):random_num(11, 12))
					EjectBrass(id, clip_shell, -7.0, 15.0, anim?6.0:-6.0, -20.0, -100.0)
					set_extension(id, anim, ANIMEXT_DUAL)
				}
			}
		}
			
		if(g_type[id][iSlot] == IS_SK4)
		{
			static anim
			anim = Get_LRState(iClip)
			
			if(iClip < 2)
			{
				set_weapon_anim(id, !iClip?7:4)
				EjectBrass(id, clip_shell, -9.0, 8.0, !iClip?7.0:-6.0, -50.0, -70.0)
				set_extension(id, !iClip, ANIMEXT_DUAL)
			} else {
				set_weapon_anim(id, anim ? (random_num(2, 3)) : (random_num(5, 6)))
				EjectBrass(id, clip_shell, -9.0, 8.0, anim ? 7.0 : -6.0, -50.0, -70.0)
				set_extension(id, !anim, ANIMEXT_DUAL)
			}
			
			set_pdata_float(ent, m_flAccuracy, random_float(0.01, DEFAULT_MAX_ACC), OFFSET_WEAPON)
			set_recoil(id, get_pcvar_float(cvar_sk4_recoil))
			set_nextattack(ent, id, get_pcvar_float(cvar_sk4_speed), (iClip ? 0.0 : -1.0))
		}
		
		if(g_type[id][iSlot] == IS_SK5)
		{
			set_pdata_float(ent, m_flAccuracy, random_float(0.01, DEFAULT_MAX_ACC), OFFSET_WEAPON)
			set_recoil(id, get_pcvar_float(cvar_sk5_recoil))
			set_weapon_anim(id, random_num(1,2))
			
			new isZoom = (get_pdata_int(id, m_iFOV, OFFSET_PLAYER) < 90)
			set_nextattack(ent, id, get_pcvar_float(cvar_sk5_speed[isZoom]))
		}
		
		if(g_type[id][iSlot] == IS_SK6)
		{
			set_pdata_float(ent, m_flAccuracy, random_float(0.01, DEFAULT_MAX_ACC), OFFSET_WEAPON)
			set_weapon_anim(id, random_num(1,2))
			
			set_recoil(id, get_pcvar_float(cvar_sk6_recoil))
			set_nextattack(ent, id, get_pcvar_float(cvar_sk6_speed))
		}
		
		if(g_type[id][iSlot] == IS_SK7)
		{
			set_pdata_float(ent, m_flAccuracy, random_float(0.01, DEFAULT_MAX_ACC), OFFSET_WEAPON)
			set_weapon_anim(id, random_num(1,2))
			
			set_recoil(id, get_pcvar_float(cvar_sk7_recoil))
			set_nextattack(ent, id, get_pcvar_float(cvar_sk7_speed))
		}
		
		if(g_type[id][iSlot] == IS_SK8)
		{
			set_pdata_float(ent, m_flAccuracy, random_float(0.01, DEFAULT_MAX_ACC), OFFSET_WEAPON)
			set_weapon_anim(id, random_num(1,2))
			
			set_recoil(id, get_pcvar_float(cvar_sk8_recoil))
			set_nextattack(ent, id, get_pcvar_float(cvar_sk8_speed))
		}
		
		if(g_type[id][iSlot] == IS_SK11)
		{
			set_recoil(id, get_pcvar_float(cvar_sk11_recoil))
			set_weapon_anim(id, random_num(1,2))
			set_nextattack(ent, id, get_pcvar_float(cvar_sk11_speed[g_sk11_mode[id]]))
		}
	}
	g_is_attacking[id] = 0
}

stock Get_LRState(iClip) return (iClip % 2)

stock Get_SkullMaxClip(id, ActiveSlot, isSk3d = 0)
{
	static iSlot; iSlot = (ActiveSlot-1)
	if(g_type[id][iSlot] == IS_SK1) return get_pcvar_num(cvar_sk1_maxclip)
	else if(g_type[id][iSlot] == IS_SK2) return get_pcvar_num(cvar_sk2_maxclip[g_sk2_mode[id]])
	else if(g_type[id][iSlot] == IS_SK3) return get_pcvar_num(cvar_sk3_maxclip[isSk3d])
	else if(g_type[id][iSlot] == IS_SK4) return get_pcvar_num(cvar_sk4_maxclip)
	else if(g_type[id][iSlot] == IS_SK5) return get_pcvar_num(cvar_sk5_maxclip)
	else if(g_type[id][iSlot] == IS_SK6) return get_pcvar_num(cvar_sk6_maxclip)
	else if(g_type[id][iSlot] == IS_SK7) return get_pcvar_num(cvar_sk7_maxclip)
	else if(g_type[id][iSlot] == IS_SK8) return get_pcvar_num(cvar_sk8_maxclip)
	else if(g_type[id][iSlot] == IS_SK11) return get_pcvar_num(cvar_sk11_maxclip)
	return 0
}

public HamF_ItemPostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return HAM_IGNORED
	
	static ActiveSlot, iWPN, iCSWd, iCSW, isSk3d, iButton, iSlot, iBpAmmo, iClip, fInReload, iMaxClip
	ActiveSlot = Get_WeaponSlot(id, ent)
	iCSW = get_pdata_int(ent, m_iId, OFFSET_WEAPON)
	
	if(!IsHaveSkull(id, ActiveSlot))
		return HAM_IGNORED
	
	isSk3d = IsSk3d(id)
	iWPN = Get_SkullCSW(id, ActiveSlot)
	iCSWd = Get_SkullCSW(id, SLOT_PRI, 1)
	iButton = pev(id, pev_button)
	iSlot = (ActiveSlot-1)
	
	if(iCSW == iWPN || iCSW == iCSWd) // ... idk :/ as long as it works
	{
		if(ActiveSlot < 3)
		{
			iBpAmmo = cs_get_user_bpammo(id, isSk3d ? iCSWd : iWPN)
			iClip = get_pdata_int(ent, m_iClip, OFFSET_WEAPON)
			fInReload = get_pdata_int(ent, m_fInReload, OFFSET_WEAPON) 
			iMaxClip = Get_SkullMaxClip(id, ActiveSlot, isSk3d)
			
			if(fInReload && get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER) <= 0.0)
			{
				new xClip = min(iMaxClip - iClip, iBpAmmo)
			
				set_pdata_int(ent, m_iClip, iClip + xClip, OFFSET_WEAPON)
				cs_set_user_bpammo(id, isSk3d ? iCSWd : iWPN, iBpAmmo - xClip)
				set_pdata_int(ent, m_fInReload, 0, OFFSET_WEAPON)
			}
		}
		
		if(g_type[id][iSlot] == IS_SK2 && get_pdata_float(ent, m_flTimeWeaponIdle, OFFSET_WEAPON) <= 0.0)
		{
			if(!g_sk2_mode[id]) set_weapon_anim(id, (iClip == 1) ? 6 : 5)
			else set_weapon_anim(id, 0)
			
			set_pdata_float(ent, m_flTimeWeaponIdle, 3.03, OFFSET_WEAPON)
		}
		
		if(g_type[id][iSlot] == IS_SK3)
		{
			if(g_skull3_changing[id] && get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER) <= 0.0)
			{
				g_skull3_mode[id] = 1 - g_skull3_mode[id]
				g_skull3_changing[id] = 0
				
				set_pev(id, pev_weaponmodel2, P_MODEL_SKULL[g_skull3_mode[id]?(IS_SK11+1):IS_SK3])
				
				if(g_skull3_mode[id])
				{
					if(pev(id, pev_maxspeed) != get_pcvar_float(cvar_decrease_speed))
						fm_set_user_maxspeed(id, get_pcvar_float(cvar_decrease_speed))
				} else reset_player_maxspeed(id)
			}
			
			if(get_pdata_float(ent, m_flTimeWeaponIdle, OFFSET_WEAPON) <= 0.0 && g_skull3_mode[id])
			{
				set_weapon_anim(id, (iClip == 1)? 7:6)
				set_pdata_float(ent, m_flTimeWeaponIdle, (iClip == 1)?5.1:12.0, OFFSET_WEAPON)
			}
		}
		
		if(g_type[id][iSlot] == IS_SK4)
		{
			if(get_pdata_float(ent, m_flTimeWeaponIdle, OFFSET_WEAPON) <= 0.0 && iClip == 1)
			{
				set_weapon_anim(id, 1)
				set_pdata_float(ent, m_flTimeWeaponIdle, 1.03, OFFSET_WEAPON)
			}
		}
		
		PostFrame_SpecialWeapon(id, ent, iSlot, ActiveSlot, iClip, iBpAmmo, iButton, isSk3d ? iCSWd : iWPN)
	}
	return HAM_IGNORED
}

public PostFrame_SpecialWeapon(id, ent, iSlot, ActiveSlot, iClip, iBpAmmo, iButton, iCSW)
{
	new Float:fKnifeData[4]
	new attacking = pev(ent, pev_iuser1)
	new anim = pev(ent, pev_iuser2)
	
	if(attacking && get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER) <= 0.0)
	{
		if(g_type[id][iSlot] == IS_SK8)
		{
			fKnifeData[0] = get_pcvar_float(cvar_sk8_kniferange)
			fKnifeData[1] = get_pcvar_float(cvar_sk8_knifeangle)
			fKnifeData[2] = get_pcvar_float(cvar_sk8_damage[1])
			fKnifeData[3] = get_pcvar_float(cvar_sk8_knifekb)
			
			new Result = WeaponDamage_Config(id, 0, 1, true, fKnifeData[0], fKnifeData[1], fKnifeData[2], fKnifeData[3])
			new sound[128]
			
			if(Result != RESULT_HIT_NONE)
			{
				if(Result == RESULT_HIT_PLAYER) formatex(sound, charsmax(sound), Skullaxe_Sounds[1])
				else formatex(sound, charsmax(sound), Skullaxe_Sounds[5])
			}
			client_cmd(id, "spk %s", sound)
			set_pev(ent, pev_iuser1, 0)
			
			set_pdata_float(ent, m_flTimeWeaponIdle, 0.92, OFFSET_WEAPON)
			set_pdata_float(id, m_flNextAttack, 0.92, OFFSET_PLAYER)
		}
		
		if (g_type[id][iSlot] == IS_SK9)
		{
			new bool:bStab = pev(ent, pev_iuser2)?true:false;
			fKnifeData[0] = get_pcvar_float(cvar_sk9_range[bStab])
			fKnifeData[1] = (bStab ? get_pcvar_float(cvar_sk9_angle) : 0.0)
			fKnifeData[2] = get_pcvar_float(cvar_sk9_damage[bStab])
			fKnifeData[3] = get_pcvar_float(cvar_sk9_kb[bStab])
			
			new Result = WeaponDamage_Config(id, 0, 1, bStab, fKnifeData[0], fKnifeData[1], fKnifeData[2], fKnifeData[3])
			new sound[128]
			
			if(Result != RESULT_HIT_NONE)
			{
				if(Result == RESULT_HIT_PLAYER) formatex(sound, charsmax(sound), Skullaxe_Sounds[1])
				else formatex(sound, charsmax(sound), Skullaxe_Sounds[5])
			}
			engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			//client_cmd(id, "spk %s", sound)
			
			if (!bStab) set_weapon_anim(id, !Result?5:1);
			set_pev(ent, pev_iuser1, 0);
		}
	}
	
	if((iButton & IN_ATTACK) && !(iButton & IN_ATTACK2))
	{
		if(g_type[id][iSlot] == IS_SK9 && get_pdata_float(ent, m_flNextPrimaryAttack, OFFSET_WEAPON) <= 0.0)
		{
			set_pdata_float(id, m_flNextAttack, 1.0, OFFSET_PLAYER);
			set_pdata_float(ent, m_flNextPrimaryAttack, 1.39, OFFSET_WEAPON);
			set_pdata_float(ent, m_flNextSecondaryAttack, 1.39 + 0.1, OFFSET_WEAPON);
			set_pdata_float(ent, m_flTimeWeaponIdle, 1.39 + 3.0, OFFSET_WEAPON);
			
			set_pev(ent, pev_iuser2, 0);
			
			#if defined ENABLE_SKULLAXE_BUG
			new param[2]; param[0] = id; param[1] = ent
			set_task(get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER),"Task_Bug_Skullaxe",SKULL11_KEY+6969,param,2)
			#else
			set_pev(ent, pev_iuser1, 1);
			set_pev(ent, pev_fuser4, get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER) + get_gametime());
			#endif
			
			set_weapon_anim(id, 8);
		}
	}
	
	if(!(iButton & IN_ATTACK) && (iButton & IN_ATTACK2))
	{
		if(g_type[id][iSlot] == IS_SK2 && get_pdata_float(ent, m_flNextPrimaryAttack, OFFSET_WEAPON) <= 0.0)
		{
			g_sk2_mode[id] = 1 - g_sk2_mode[id]
			
			set_pdata_string(id, m_szAnimExtention * 4, g_sk2_mode[id]?ANIMEXT_DEFAULT_PISTOL : ANIMEXT_DUAL, -1 , 20)
			set_weapon_anim(id, (g_sk2_mode[id] && iClip == 1)?18:15+g_sk2_mode[id])
			set_nextattack(ent, id, 3.03)
			
			new iMaxClip = Get_SkullMaxClip(id, ActiveSlot)
			new xClip = min(iMaxClip - iClip, iBpAmmo)
		
			set_pdata_int(ent, m_iClip, iClip + xClip, 4)
			cs_set_user_bpammo(id, iCSW, iBpAmmo - xClip)
		}
		
		if(g_type[id][iSlot] == IS_SK9 && get_pdata_float(ent, m_flNextPrimaryAttack, OFFSET_WEAPON) <= 0.0)
		{
			set_pdata_float(id, m_flNextAttack, 1.16, OFFSET_PLAYER);
			set_pdata_float(ent, m_flNextPrimaryAttack, 1.43, OFFSET_WEAPON);	
			set_pdata_float(ent, m_flNextSecondaryAttack, 1.43, OFFSET_WEAPON);		
			set_pdata_float(ent, m_flTimeWeaponIdle, 1.43 + 2.0, OFFSET_WEAPON);

			set_pev(ent, pev_iuser2, 1);
			
			#if defined ENABLE_SKULLAXE_BUG
			new param[2]; param[0] = id; param[1] = ent
			set_task(get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER),"Task_Bug_Skullaxe",SKULL11_KEY+6969,param,2)
			#else
			set_pev(ent, pev_iuser1, 1);
			set_pev(ent, pev_fuser4, get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER) + get_gametime());
			#endif
			
			set_weapon_anim(id, 2);
		}
		
		if(g_type[id][iSlot] == IS_SK1 && get_pdata_float(ent, m_flNextPrimaryAttack, OFFSET_WEAPON) <= 0.0)
		{
			if(!iClip)
			{
				PlayEmptySound(id)
				set_pdata_float(ent, m_flNextPrimaryAttack, get_pcvar_float(cvar_sk1_speed[1]) + 0.1, OFFSET_WEAPON)
				return HAM_IGNORED
			}
			
			ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
			set_pdata_float(ent, m_flNextPrimaryAttack, get_pcvar_float(cvar_sk1_speed[1]), OFFSET_WEAPON)
			
			engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, S_SOUND[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			
			g_anim[id] = 1 - g_anim[id]
			set_weapon_anim(id, g_anim[id] ? 4 : 5)
			
			static Float:punchAngle[3]
			punchAngle[0] = float(random_num(-200, 200)) / 100.0
			punchAngle[1] = float(random_num(-200, 200)) / 100.0
			punchAngle[2] = 0.0
			set_pev(id, pev_punchangle, punchAngle)
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, id);
			write_short((1<<12) * 1);
			write_short((1<<12) * 1);
			write_short((1<<12) * 1);
			message_end();
		}
		
		if(g_type[id][iSlot] == IS_SK8 && get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER) <= 0.0)
		{
			if(get_pdata_float(ent, 46, 4) <= 0.0 )
			{
				anim = 1 - anim
				set_pev(ent, pev_iuser2, anim)
				set_pev(ent, pev_iuser1, 1)
				set_weapon_anim(id, anim ? 5 : 6)
				
				set_pdata_float(ent, m_flTimeWeaponIdle, 1.76, OFFSET_WEAPON)
				set_pdata_float(ent, m_flNextPrimaryAttack, 1.76, OFFSET_WEAPON)
				set_pdata_float(id, m_flNextAttack, anim ? 0.84 : 0.95, OFFSET_PLAYER)
			}
		}
		
		if(ActiveSlot == 1 && g_type[id][iSlot] != IS_SK8 && get_pdata_float(ent, m_flNextPrimaryAttack, OFFSET_WEAPON) <= 0.0)
		{
			if((!g_skull3_mode[id] && g_type[id][iSlot] == IS_SK3) || g_type[id][iSlot] == IS_SK4 || g_type[id][iSlot] == IS_SK7)
			{
				g_zoomed[id] = 1 - g_zoomed[id]
				cs_set_user_zoom(id, g_zoomed[id] ? CS_SET_AUGSG552_ZOOM : CS_RESET_ZOOM, 1)
			}
			
			if(g_type[id][iSlot] == IS_SK6)
			{
				switch(g_zoomed[id])
				{
					case 1:
					{
						g_zoomed[id] = 2
						cs_set_user_zoom(id, CS_SET_SECOND_ZOOM, 1)
					}
					case 2:
					{
						g_zoomed[id] = 0
						cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
					}
					default:
					{
						g_zoomed[id] = 1
						cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 1)
					}
				}
			}
			
			if(g_type[id][iSlot] == IS_SK11)
			{
				g_sk11_mode[id] = 1 - g_sk11_mode[id]
				client_print(id, print_center, "Ammo changed to %s rounds.", g_sk11_mode[id] ? "slug" : "buckshot")
			}
			
			set_pdata_float(ent, m_flNextPrimaryAttack, 0.5, OFFSET_WEAPON)
		}
	}
	return HAM_IGNORED
}

public HamF_WeaponReload(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return HAM_IGNORED
		
	static ActiveSlot, iCSW, iCSWd, iWPN, isSk3d, iMaxClip, iClip, iBpAmmo, iSlot
	ActiveSlot = Get_WeaponSlot(id, ent)
	iCSW = get_pdata_int(ent, m_iId, OFFSET_WEAPON)
	
	if(!IsHaveSkull(id, ActiveSlot))
		return HAM_IGNORED
	
	isSk3d = IsSk3d(id)
	iWPN = Get_SkullCSW(id, ActiveSlot, isSk3d)
	iMaxClip = Get_SkullMaxClip(id, ActiveSlot, isSk3d)
	iBpAmmo = cs_get_user_bpammo(id, iWPN)
	iClip = get_pdata_int(ent, m_iClip, OFFSET_WEAPON)
	iSlot = (ActiveSlot-1)
	iCSWd = Get_SkullCSW(id, SLOT_PRI, 1)
	
	if(iCSW == iWPN || iCSW == iCSWd) // ... idk :/ as long as it works
	{
		g_Sk_Clip[id][iSlot] = -1
	
		if(iBpAmmo <= 0 || iClip >= iMaxClip)
			return HAM_SUPERCEDE
	
		g_Sk_Clip[id][iSlot] = iClip
	}
	return HAM_IGNORED
}

public HamF_WeaponReload_Post(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
		
	static ActiveSlot, isSk3d, iSlot, iCSW, iCSWd, iWPN
	ActiveSlot = Get_WeaponSlot(id, ent)
	iCSW = get_pdata_int(ent, m_iId, OFFSET_WEAPON)
	
	if(!IsHaveSkull(id, ActiveSlot))
		return HAM_IGNORED
		
	isSk3d = IsSk3d(id)
	iSlot = (ActiveSlot-1)
	iCSWd = Get_SkullCSW(id, SLOT_PRI, 1)
	iWPN = Get_SkullCSW(id, ActiveSlot, isSk3d)
	
	if(iCSW == iWPN || iCSW == iCSWd) // ... idk :/ as long as it works
	{
		if(g_Sk_Clip[id][iSlot] == -1)
		return HAM_IGNORED
	
		set_pdata_int(ent, m_iClip, g_Sk_Clip[id][iSlot], OFFSET_WEAPON)
		set_pdata_int(ent, m_fInReload, 1, OFFSET_WEAPON)
		
		set_nextattack(ent, id, Get_SkullReloadTime(id, ActiveSlot, isSk3d))
		set_weapon_anim(id, Get_SkullReloadAnim(id, ActiveSlot, isSk3d))
		
		cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
		if(isSk3d) set_pdata_string(id, m_szAnimExtention * 4, ANIMEXT_DUAL, -1 , 20)
	}
	return HAM_IGNORED
}

stock Get_SkullReloadAnim(id, ActiveSlot, isSk3d = 0)
{
	static iSlot; iSlot = (ActiveSlot-1)
	if(g_type[id][iSlot] == IS_SK1) return 6
	else if(g_type[id][iSlot] == IS_SK2) return g_sk2_mode[id] ? 1 : 13
	else if(g_type[id][iSlot] == IS_SK3) return isSk3d ? 14 : 1
	else if(g_type[id][iSlot] == IS_SK4) return 8
	return 3
}

stock Float:Get_SkullReloadTime(id, ActiveSlot, isSk3d = 0)
{
	static iSlot; iSlot = (ActiveSlot-1)
	if(g_type[id][iSlot] == IS_SK1) return 2.62
	else if(g_type[id][iSlot] == IS_SK2) return g_sk2_mode[id] ? 2.5 : 3.5
	else if(g_type[id][iSlot] == IS_SK3) return isSk3d ? 3.4 : 2.2
	else if(g_type[id][iSlot] == IS_SK4) return 3.4
	else if(g_type[id][iSlot] == IS_SK5) return 1.95
	else if(g_type[id][iSlot] == IS_SK6) return 3.64
	else if(g_type[id][iSlot] == IS_SK7 || g_type[id][iSlot] == IS_SK11) return 3.85
	else if(g_type[id][iSlot] == IS_SK8) return 4.4
	return 1.0
}

public Event_Death()
{
	static weapon[32], attacker, victim, isSk3d, iCSW1, iCSW2, iCSW3, ActiveSlot
	attacker = get_msg_arg_int(1)
	victim = get_msg_arg_int(2)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	ActiveSlot = Get_WeaponSlot(attacker)
	
	if(!is_user_connected(attacker) || attacker == victim)
		return PLUGIN_CONTINUE
	if(!IsHaveSkull(attacker, ActiveSlot))
		return PLUGIN_CONTINUE
	
	isSk3d = IsSk3d(attacker)
	iCSW1 = Get_SkullCSW(attacker, SLOT_PRI, isSk3d)
	iCSW2 = Get_SkullCSW(attacker, SLOT_SEC)
	iCSW3 = Get_SkullCSW(attacker, SLOT_MEL)
	
	if(ActiveSlot == 2 && get_user_weapon(attacker) == iCSW2) 
	{
		if(g_had_wpnskull[attacker][IS_SK1] && equal(weapon, "deagle")) set_msg_arg_string(4, "skull1")
		if(g_had_wpnskull[attacker][IS_SK2] && equal(weapon, "fiveseven")) set_msg_arg_string(4, "skull2")
	}
	
	if(ActiveSlot == 1 && get_user_weapon(attacker) == iCSW1) 
	{
		if(g_had_wpnskull[attacker][IS_SK3] && equal(weapon, "mp5navy") && !isSk3d) set_msg_arg_string(4, "skull3")
		else if(g_had_wpnskull[attacker][IS_SK3] && equal(weapon, "p90") && isSk3d) set_msg_arg_string(4, "skull3d")
		else if(g_had_wpnskull[attacker][IS_SK4] && equal(weapon, "ak47")) set_msg_arg_string(4, "skull4")
		else if(g_had_wpnskull[attacker][IS_SK5] && equal(weapon, "g3sg1")) set_msg_arg_string(4, "skull5")
		else if(g_had_wpnskull[attacker][IS_SK6] && equal(weapon, "m249")) set_msg_arg_string(4, "skull6")
		else if(g_had_wpnskull[attacker][IS_SK7] && equal(weapon, "m249")) set_msg_arg_string(4, "m249ex")
		else if(g_had_wpnskull[attacker][IS_SK8] && equal(weapon, "m249")) set_msg_arg_string(4, "skull8")
		else if(g_had_wpnskull[attacker][IS_SK11] && equal(weapon, "xm1014")) set_msg_arg_string(4, "skull11")
	}
	
	if(ActiveSlot == 3 && get_user_weapon(attacker) == iCSW3) 
		if(g_had_wpnskull[attacker][IS_SK9] && equal(weapon, "knife")) set_msg_arg_string(4, "skullaxe")
	
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
		 
	if(Get_WeaponSlot(id) == SLOT_PRI && g_had_wpnskull[id][IS_SK3] && get_user_weapon(id) == Get_SkullCSW(id, SLOT_PRI, 1))
	{
		if(pev(id, pev_maxspeed) != get_pcvar_float(cvar_decrease_speed))
			fm_set_user_maxspeed(id, get_pcvar_float(cvar_decrease_speed))
		
		set_pdata_string(id, m_szAnimExtention * 4, ANIMEXT_DUAL, -1 , 20)
	}
}

public Task_Bug_Skullaxe(param[])
{
	new id = param[0], ent = param[1], Float:fKnifeData[4]

	new bool:bStab = pev(ent, pev_iuser2)?true:false;
	fKnifeData[0] = get_pcvar_float(cvar_sk9_range[bStab])
	fKnifeData[1] = (bStab ? get_pcvar_float(cvar_sk9_angle) : 0.0)
	fKnifeData[2] = get_pcvar_float(cvar_sk9_damage[bStab])
	fKnifeData[3] = get_pcvar_float(cvar_sk9_kb[bStab])
	
	new Result = WeaponDamage_Config(id, 0, 1, bStab, fKnifeData[0], fKnifeData[1], fKnifeData[2], fKnifeData[3])
	new sound[128]
	
	if(Result != RESULT_HIT_NONE)
	{
		if(Result == RESULT_HIT_PLAYER) formatex(sound, charsmax(sound), Skullaxe_Sounds[1])
		else formatex(sound, charsmax(sound), Skullaxe_Sounds[5])
	}
	client_cmd(id, "spk %s", sound)
	
	if (!bStab) set_weapon_anim(id, !Result?5:1);
	set_pev(ent, pev_iuser1, 0);
}

stock IsSk3d(id) 
{
	static ActiveSlot; ActiveSlot = Get_WeaponSlot(id)
	
	if(ActiveSlot == SLOT_PRI && g_had_wpnskull[id][IS_SK3])
		return g_skull3_mode[id]
	return 0
}

stock IsHaveSkull(id, ActiveSlot) 
{
	if(!g_had_wpnskull[id][g_type[id][ActiveSlot-1]])
		return 0
	
	return 1
}

stock Get_WeaponSlot(id, iEnt = 0)
{
	static pEnt;
	if(!iEnt) pEnt = get_pdata_cbase(id, m_pActiveItem)
	else pEnt = iEnt
	
	if(!pev_valid(pEnt)) return 0
	return ExecuteHam(Ham_Item_ItemSlot, pEnt)
}

stock Get_SkullCSW(id, WhichSlot = 0, isSk3d = 0)
{
	static ActiveSlot;
	if(!WhichSlot) ActiveSlot = Get_WeaponSlot(id)
	else ActiveSlot = WhichSlot
	
	if(ActiveSlot == 1)
	{
		if(g_had_wpnskull[id][IS_SK3]) return isSk3d ? CSW_P90 : CSW_MP5NAVY
		if(g_had_wpnskull[id][IS_SK4]) return CSW_AK47
		if(g_had_wpnskull[id][IS_SK5]) return CSW_G3SG1
		if(g_had_wpnskull[id][IS_SK11]) return CSW_XM1014
		return CSW_M249
	}
	if(ActiveSlot == 2)
	{
		if(g_had_wpnskull[id][IS_SK1]) return CSW_DEAGLE
		if(g_had_wpnskull[id][IS_SK2]) return CSW_FIVESEVEN
	}
	if(ActiveSlot == 3 && g_had_wpnskull[id][IS_SK9]) return CSW_KNIFE
	return 0
}

stock set_recoil(id, Float:fRecoil)
{
	new Float:vRecoil[3]
	pev(id, pev_punchangle, vRecoil)
	xs_vec_sub(vRecoil, g_recoil[id], vRecoil)
	xs_vec_mul_scalar(vRecoil, fRecoil, vRecoil)
	xs_vec_add(vRecoil, g_recoil[id], vRecoil)
	set_pev(id, pev_punchangle, vRecoil)
}

stock set_extension(id, right, extension[])
{
	new szAnim[64], iAnim, Duck
	Duck = pev(id, pev_flags) & FL_DUCKING
	
	if(!right) formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot_%s" : "ref_shoot_%s", extension)
	else formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot2_%s" : "ref_shoot2_%s", extension)
	
	if((iAnim = lookup_sequence(id, szAnim)) == -1) iAnim = 0
	set_pev(id, pev_sequence, iAnim)
}

// Stocks
stock set_weapon_list(id, spr[], PriAmmoId, PriAmmoAmount, SecAmmoId, SecAmmoAmount, SlotId, NumSlot, CSW)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(spr)
	write_byte(PriAmmoId)
	write_byte(PriAmmoAmount)
	write_byte(SecAmmoId)
	write_byte(SecAmmoAmount)
	write_byte(SlotId)
	write_byte(NumSlot)
	write_byte(CSW)
	write_byte(0)
	message_end()
}

stock set_weapon_anim(id, anim)
{ 
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock set_nextattack(weapon, player, Float:nextTime, Float:nextIdle = 0.0)
{
	if(!pev_valid(weapon))	
		return
	
	static Float:fTime
	if(nextIdle == 0.0) fTime = (nextTime + 0.5)
	else fTime = nextIdle
	
	set_pdata_float(weapon, m_flNextPrimaryAttack, nextTime, OFFSET_WEAPON)
	set_pdata_float(weapon, m_flNextSecondaryAttack, nextTime, OFFSET_WEAPON)
	if(nextIdle != -1.0) set_pdata_float(weapon, m_flTimeWeaponIdle, fTime, OFFSET_WEAPON)
	set_pdata_float(player, m_flNextAttack, nextTime, OFFSET_PLAYER)
}

stock Update_Ammo(id, CSW, clip)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
	write_byte(1)
	write_byte(CSW)
	write_byte(clip)
	message_end()
}

stock PlayEmptySound(id)
{
	const CSWPN_SEC = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

	if (CSWPN_SEC & 1<<get_user_weapon(id)) emit_sound(id, CHAN_AUTO, "weapons/dryfire_pistol.wav", 0.8, ATTN_NORM, 0, PITCH_NORM);
	else emit_sound(id, CHAN_AUTO, "weapons/dryfire_rifle.wav", 0.8, ATTN_NORM, 0, PITCH_NORM);
}
stock fm_cs_get_weapon_ent_owner(ent) return get_pdata_cbase(ent, m_pPlayer, OFFSET_WEAPON)

stock WeaponDamage_Config(id, iEnt, isKnife, bStab, Float:flRadius, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bNoTraceCheck = 0, bitsDamageType = DMG_NEVERGIB | DMG_CLUB, bool:bSkipAttacker=true, bool:bCheckTeam=false)
{
	if(!id) id = iEnt
	
	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	
	if(isKnife) GetGunPosition(id, vecSrc);
	else pev(iEnt, pev_origin, vecSrc)
	
	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);
	
	new Float:flAdjustedDamage, Float:falloff
	falloff = flDamage / flRadius
	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER)
	if (!isKnife) vecSrc[2] += 1.0
	
	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRadius, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (isKnife && !bStab && flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
	
	get_tr2(tr, TR_flFraction, flFraction);

	new iHitResult = RESULT_HIT_NONE;
	
	if (isKnife && fAngle <= 0.0 && flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit);
		
		new iTtextureType, pTextureName[64];
		engfunc(EngFunc_TraceTexture, 0, vecSrc, vecEnd, pTextureName, charsmax(pTextureName));
		iTtextureType = dllfunc(DLLFunc_PM_FindTextureType, pTextureName);
		
		if (iTtextureType == 'M') iHitResult = RESULT_HIT_METAL
		else iHitResult = RESULT_HIT_GENERIC;
		
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 3.0;

			iHitResult = RESULT_HIT_PLAYER;
		}

		if (!bStab && pev_valid(pEntity))
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			if (can_damage(id, pEntity)) Stock_Fake_KnockBack(id, pEntity, flKnockBack)

			ClearMultiDamage();
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
			ApplyMultiDamage(id, id);
			
			if (IsAlive(pEntity))
			{
				free_tr2(tr);
				return iHitResult;
			}
		}
		free_tr2(tr);
	}
	
	if (isKnife && flFraction < 1.0)
	{
		new iTtextureType, pTextureName[64];
		engfunc(EngFunc_TraceTexture, 0, vecSrc, vecEnd, pTextureName, charsmax(pTextureName));
		iTtextureType = dllfunc(DLLFunc_PM_FindTextureType, pTextureName);
		
		if (iTtextureType == 'M') iHitResult = RESULT_HIT_METAL
		else iHitResult = RESULT_HIT_GENERIC;
	}
	
	new Float:vecEndZ = vecEnd[2];
		
	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if(isKnife)
		{
			if (!pev_valid(pEntity))
				continue;
			if (id == pEntity)
				continue;
			if (!IsAlive(pEntity))
				continue;
			if (!CheckAngle(id, pEntity, fAngle))
				continue;
		} else {
			if (pev(pEntity, pev_takedamage) == DAMAGE_NO)
				continue;
			if (bInWater && !pev(pEntity, pev_waterlevel))
				continue;
			if (!bInWater && pev(pEntity, pev_waterlevel) == 3)
				continue;
				
			if(bCheckTeam && pEntity != id)
				if(!can_damage(pEntity, id))
					continue
			
			if(bSkipAttacker && pEntity == id)
				continue
		} 
		
		Stock_Get_Origin(pEntity, vecEnd);
		
		if(isKnife && fAngle > 0.0)
		{
			GetGunPosition(id, vecSrc);
			vecEnd[2] = vecSrc[2] + (vecEndZ - vecSrc[2]) * (get_distance_f(vecSrc, vecEnd) / flRadius);
	
			xs_vec_sub(vecEnd, vecSrc, vecForward);
			xs_vec_normalize(vecForward, vecForward);
			xs_vec_mul_scalar(vecForward, flRadius, vecForward);
			xs_vec_add(vecSrc, vecForward, vecEnd);
		
			engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
			get_tr2(tr, TR_flFraction, flFraction);
	
			if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);

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
	
					if (can_damage(id, pEntity)) Stock_Fake_KnockBack(id, pEntity, flKnockBack)
	
					ClearMultiDamage();
					ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
					ApplyMultiDamage(id, id);
				}
			}
		}
		
		if(!isKnife && pev_valid(pEntity))
		{
			engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, 0, tr)

			new Float:flFraction
			get_tr2(tr, TR_flFraction, flFraction)
	
			if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, 0, tr)
			
			pev(pEntity, pev_origin, vecEnd)
			xs_vec_sub(vecEnd, vecSrc, vecEnd)

			new Float:fDistance = xs_vec_len(vecEnd)
			if(fDistance < 1.0) fDistance = 0.0

			flAdjustedDamage = fDistance * falloff
			
			if(get_tr2(tr, TR_pHit) != pEntity) flAdjustedDamage *= 0.3

			if(flAdjustedDamage <= 0)
				continue

			ClearMultiDamage();
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flAdjustedDamage, vecEnd, tr, bitsDamageType);
			ApplyMultiDamage(id, id);
			
			static Float:Velocity[3]
			Velocity[0] = Velocity[1] *= flKnockBack
			set_pev(pEntity, pev_velocity, Velocity)
			
			iHitResult = RESULT_HIT_PLAYER;
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock ClearMultiDamage() OrpheuCall(OrpheuGetFunction("ClearMultiDamage"));
stock ApplyMultiDamage(inflictor, iAttacker) OrpheuCall(OrpheuGetFunction("ApplyMultiDamage"), inflictor, iAttacker);

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

stock make_bullet(id, Float:Origin[3])
{
	new target, body, TE_FLAG, decal = 41
	get_user_aiming(id, target, body)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	if(target > 0 && target <= get_maxplayers())
	{
		if(!can_damage(id, target))
			return
		
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		velocity_by_aim(id, 64, fVel)
		
		fStart[0] = Origin[0]
		fStart[1] = Origin[1]
		fStart[2] = Origin[2]
		fEnd[0] = fStart[0] + fVel[0]
		fEnd[1] = fStart[1] + fVel[1]
		fEnd[2] = fStart[2] + fVel[2]
		
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_blood[1])
		write_short(g_blood[0])
		write_byte(70)
		write_byte(random_num(3,7))
		message_end()
	} else {
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			write_short(target)
			message_end()
		} else {
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(floatround(Origin[0]))
		write_coord(floatround(Origin[1]))
		write_coord(floatround(Origin[2]))
		write_short(id)
		write_byte(decal)
		message_end()
		
		engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2] - 10.0)
		write_short(g_smokepuff_spr)
		write_byte(2)
		write_byte(50)
		write_byte(TE_FLAG)
		message_end()
	}
}

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, m_iTeam) != get_pdata_int(id2, m_iTeam))
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock reset_player_maxspeed(id)
{
	if(!is_user_alive(id))
		return
	
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id);
}

enum (<<=1)
{
	v_angle = 1,
	punchangle
}

public EjectBrass(id, mdl, Float:up, Float:forw, Float:right , Float:right_coord1 , Float:right_coord2)
{
	static Float:velocity[3], Float:angle[3], Float:origin[3], Float:ViewOfs[3], i, Float:ShellOrigin[3],  Float:ShellVelocity[3], Float:Right[3], Float:Up[3], Float:Forward[3]
	make_vectors(id, v_angle + punchangle)
	
	pev(id, pev_velocity, velocity)
	pev(id, pev_view_ofs, ViewOfs)
	pev(id, pev_angles, angle)
	pev(id, pev_origin, origin)
	
	global_get(glb_v_right, Right)
	global_get(glb_v_up, Up)
	global_get(glb_v_forward, Forward)
	
	for( i = 0; i < 3; i++ )
	{
		ShellOrigin[i] = origin[i] + ViewOfs[i] + Up[i] * up + Forward[i] * forw + Right[i] * right
		ShellVelocity[i] = velocity[i] + Right[i] * random_float(right_coord1, right_coord2) + Up[i] * random_float(100.0, 150.0) + Forward[i] * 25.0
	}
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, ShellOrigin, 0)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, ShellOrigin[0])
	engfunc(EngFunc_WriteCoord, ShellOrigin[1])
	engfunc(EngFunc_WriteCoord, ShellOrigin[2])	
	engfunc(EngFunc_WriteCoord, ShellVelocity[0])
	engfunc(EngFunc_WriteCoord, ShellVelocity[1])
	engfunc(EngFunc_WriteCoord, ShellVelocity[2])
	engfunc(EngFunc_WriteAngle, angle[1])
	write_short(mdl)
	write_byte(1)
	write_byte(15) // 2.5 seconds
	message_end()
}

stock make_vectors(id, AngleType)
{
	static Float:PunchAngles[3], Float:angle[3]
	if(AngleType & v_angle) pev(id, pev_v_angle, angle)
	if(AngleType & punchangle) pev(id, pev_punchangle, PunchAngles)
	
	xs_vec_add(angle, PunchAngles, angle)
	engfunc(EngFunc_MakeVectors, angle)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

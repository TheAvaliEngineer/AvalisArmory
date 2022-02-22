global function TAE_WeaponPWave_Init

global function OnWeaponActivate_weapon_pwave
global function OnWeaponPrimaryAttack_weapon_pwave

#if SERVER
global function OnWeaponNpcPrimaryAttack_weapon_pwave
#endif // #if SERVER

global function OnWeaponCooldown_weapon_pwave
global function OnWeaponReload_weapon_pwave




// This is copied from the LSTAR code since I can't be bothered.
const PWAVE_COOLDOWN_EFFECT_1P = $"wpn_mflash_snp_hmn_smokepuff_side_FP"
const PWAVE_COOLDOWN_EFFECT_3P = $"wpn_mflash_snp_hmn_smokepuff_side"
const PWAVE_BURNOUT_EFFECT_1P = $"xo_spark_med"
const PWAVE_BURNOUT_EFFECT_3P = $"xo_spark_med"

const string PWAVE_WARNING_SOUND_1P = "PWAVE_lowammowarning"	// should be "PWAVE_LowAmmoWarning"
const string PWAVE_BURNOUT_SOUND_1P = "PWAVE_LensBurnout"		// should be "PWAVE_LensBurnout"
const string PWAVE_BURNOUT_SOUND_3P = "PWAVE_LensBurnout_3P"

// This too. I am lazy as fuck
void function TAE_WeaponPWave_Init() {
	PrecacheParticleSystem( PWAVE_COOLDOWN_EFFECT_1P )
	PrecacheParticleSystem( PWAVE_COOLDOWN_EFFECT_3P )
	PrecacheParticleSystem( PWAVE_BURNOUT_EFFECT_1P )
	PrecacheParticleSystem( PWAVE_BURNOUT_EFFECT_3P )
}

// Again, copied from LSTAR code. I don't care enough today to fuck with this shit
void function OnWeaponActivate_weapon_pwave( entity weapon )
{
	entity owner = weapon.GetOwner()
	if ( !owner.IsPlayer() )
		return

#if SERVER
	CheckForRCEE( weapon, owner )
#endif // #if SERVER
}

// Again, copied from LSTAR code. I don't care enough today to fuck with this shit
#if SERVER
void function CheckForRCEE( entity weapon, entity player ) {
	int milestone = weapon.GetReloadMilestoneIndex()
	if ( milestone != 4 )
		return

	bool badCombo = (player.IsInputCommandHeld( IN_MELEE ) && (player.IsInputCommandHeld( IN_DUCKTOGGLE ) || player.IsInputCommandHeld( IN_DUCK )) && player.IsInputCommandHeld( IN_JUMP ));
	if ( !badCombo )
		return

	bool fixButtons = (player.IsInputCommandHeld( IN_SPEED ) || player.IsInputCommandHeld( IN_ZOOM ) || player.IsInputCommandHeld( IN_ZOOM_TOGGLE ) || player.IsInputCommandHeld( IN_ATTACK ));
	if ( fixButtons )
		return

	const string RCEE_MODNAME = "rcee"
	if ( weapon.HasMod( RCEE_MODNAME ) )
		return

	weapon.AddMod( RCEE_MODNAME )
	weapon.ForceDryfireEvent()
	EmitSoundOnEntity( player, "lstar_lowammowarning" )
	EmitSoundOnEntity( player, "lstar_dryfire" )
}
#endif // #if SERVER

// This too. I am lazy as fuck
var function OnWeaponPrimaryAttack_weapon_pwave( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	return PWAVEPrimaryAttack( weapon, attackParams, true )
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_weapon_pwave( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	return PWAVEPrimaryAttack( weapon, attackParams, false )
}
#endif // #if SERVER


// This too. I am lazy as fuck
int function PWAVEPrimaryAttack( entity weapon, WeaponPrimaryAttackParams attackParams, bool isPlayerFired ) {
    #if CLIENT
	if ( !weapon.ShouldPredictProjectiles() )
		return 1

	// Warning sound:
	{
		entity owner = weapon.GetWeaponOwner()
		int currAmmo = weapon.GetWeaponPrimaryClipCount()
		int warnLimit = weapon.GetWeaponSettingInt( eWeaponVar.ammo_min_to_fire )
		if ( currAmmo == warnLimit )
			EmitSoundOnEntity( owner, PWAVE_WARNING_SOUND_1P )
	}
    #endif // #if CLIENT

	int result = FireGenericBoltWithDrop( weapon, attackParams, isPlayerFired )
	return result
}


// Final laziness copied code.
void function OnWeaponCooldown_weapon_pwave( entity weapon ) {
	weapon.PlayWeaponEffect( PWAVE_COOLDOWN_EFFECT_1P, PWAVE_COOLDOWN_EFFECT_3P, "SWAY_ROTATE" )
	weapon.EmitWeaponSound_1p3p( "LSTAR_VentCooldown", "LSTAR_VentCooldown_3p" )
}

void function OnWeaponReload_weapon_pwave( entity weapon, int milestoneIndex ) {
	if ( milestoneIndex != 0 )
		return

	weapon.PlayWeaponEffect( PWAVE_BURNOUT_EFFECT_1P, PWAVE_BURNOUT_EFFECT_3P, "shell" )
	weapon.PlayWeaponEffect( PWAVE_BURNOUT_EFFECT_1P, PWAVE_BURNOUT_EFFECT_3P, "spinner" )
	weapon.PlayWeaponEffect( PWAVE_BURNOUT_EFFECT_1P, PWAVE_BURNOUT_EFFECT_3P, "vent_cover_L" )
	weapon.PlayWeaponEffect( PWAVE_BURNOUT_EFFECT_1P, PWAVE_BURNOUT_EFFECT_3P, "vent_cover_R" )
	weapon.EmitWeaponSound_1p3p( PWAVE_BURNOUT_SOUND_1P, PWAVE_BURNOUT_SOUND_3P )
}
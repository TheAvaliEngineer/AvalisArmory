untyped

global function TAE_WeaponChargeSG_Init

global function OnWeaponPrimaryAttack_weapon_chargesg
#if SERVER
global function OnWeaponNpcPrimaryAttack_weapon_chargesg
#endif // #if SERVER

// Constants
const float SG_FULL_CHARGE_TIME = 5.0

const int SG_MAX_PELLETS = 20
const float CHARGE_TIME_PER_PELLET = 0.225

#if SERVER
const int SG_NPC_PELLET_COUNT = 10
#endif // #if SERVER

const float phi = ( 1 + sqrt(5) ) / 2

// Pellet offsets (this is calculated in the init function)
struct {
    float[2][SG_MAX_PELLETS] boltOffsets
} file


// Burnout effects - this will play if you overcharge the weapon
const string CHARGE_SG_WARNING_SOUND_1P = "lstar_lowammowarning"	    	// should be "LSTAR_LowAmmoWarning"
const string CHARGE_SG_BURNOUT_SOUND_1P = "LSTAR_LensBurnout"		    	// should be "LSTAR_LensBurnout"
const string CHARGE_SG_BURNOUT_SOUND_3P = "LSTAR_LensBurnout_3P"

void function TAE_WeaponChargeSG_Init() {
    ChargeSGPrecache()

    // calculate bolt offsets
    for( int boltIndex = 0; boltIndex < SG_MAX_PELLETS; boltIndex++ ) {
        float rho = sqrt(boltIndex)
        float theta = (2 * PI * boltIndex) / phi

        float x = rho * cos(theta)
        float y = rho * sin(theta)

        file.boltOffsets[boltIndex][0] = x
        file.boltOffsets[boltIndex][1] = y
    }
}
void function ChargeSGPrecache() {
    // Code copied from Charge Rifle/"defender" + L-STAR for now.
    PrecacheParticleSystem( $"P_wpn_defender_charge_FP" )
	PrecacheParticleSystem( $"P_wpn_defender_charge" )
	PrecacheParticleSystem( $"defender_charge_CH_dlight" )

	PrecacheParticleSystem( $"wpn_muzzleflash_arc_cannon_fp" )
	PrecacheParticleSystem( $"wpn_muzzleflash_arc_cannon" )
}

// Attack triggers
var function OnWeaponPrimaryAttack_weapon_chargesg( entity weapon, WeaponPrimaryAttackParams attackParams ) { 
    float chargeAmount = weapon.GetWeaponChargeFraction()
    
    if( chargeAmount >= 1.0 )
        return MisfireChargeSG( weapon, attackParams )
    
    int pelletCount = minint( (chargeAmount * SG_FULL_CHARGE_TIME * CHARGE_TIME_PER_PELLET).tointeger(), SG_MAX_PELLETS )

    return FireChargeSG( weapon, attackParams, true, pelletCount )
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_weapon_chargesg( entity weapon, WeaponPrimaryAttackParams attackParams ) { 
    return FireChargeSG( weapon, attackParams, false, SG_NPC_PELLET_COUNT )
}
#endif // if SERVER


// Handle weapon firing (mostly from Mastiff)
int function FireChargeSG( entity weapon, WeaponPrimaryAttackParams attackParams, bool playerFired, int pelletCount ) {
    // determine projectile creation I guess? I have
    // no idea why `shouldCreateProjectile` exists
    entity owner = weapon.GetWeaponOwner()
    bool shouldCreateProjectile = false

    if ( IsServer() || weapon.ShouldPredictProjectiles() )
		shouldCreateProjectile = true
	#if CLIENT
		if ( !playerFired )
			shouldCreateProjectile = false
	#endif

    // aim
    vector attackAngles = VectorToAngles( attackParams.dir )
	vector baseUpVec = AnglesToUp( attackAngles )
	vector baseRightVec = AnglesToRight( attackAngles )

	float zoomFrac
	if ( playerFired )
		zoomFrac = owner.GetZoomFrac()
	else
		zoomFrac = 0.5
    
    // spread calculation? I think this does the 'tightening' effect in ADS
    float spreadFrac = Graph( zoomFrac, 0, 1, 0.05, 0.025 ) * 1.0

    // start spawning projectiles actually
	array<entity> projectiles
    if ( shouldCreateProjectile ) {
		weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )

		for ( int index = 0; index < pelletCount; index++ ) {
			vector upVec = baseUpVec * file.boltOffsets[index][0] * spreadFrac
			vector rightVec = baseRightVec * file.boltOffsets[index][1] * spreadFrac

			vector attackDir = attackParams.dir + upVec + rightVec
			int damageFlags = weapon.GetWeaponDamageFlags()
			entity bolt = weapon.FireWeaponBolt( attackParams.pos, attackDir, 3000, damageFlags, damageFlags, playerFired, index )
			
            if ( bolt != null ) {
				bolt.kv.gravity = 0.09

				if ( !(playerFired && zoomFrac > 0.8) )
					bolt.SetProjectileLifetime( RandomFloatRange( 0.65, 0.85 ) )
				else
					bolt.SetProjectileLifetime( RandomFloatRange( 0.65, 0.85 ) * 1.25 )

				projectiles.append( bolt )

				#if SERVER
					EmitSoundOnEntity( bolt, "weapon_mastiff_projectile_crackle" )
				#endif
			}
		}
	}

    return 1
}

int function MisfireChargeSG( entity weapon, WeaponPrimaryAttackParams attackParams ) {
    weapon.EmitWeaponSound_1p3p( CHARGE_SG_BURNOUT_SOUND_1P, CHARGE_SG_BURNOUT_SOUND_3P )

    return 0
}
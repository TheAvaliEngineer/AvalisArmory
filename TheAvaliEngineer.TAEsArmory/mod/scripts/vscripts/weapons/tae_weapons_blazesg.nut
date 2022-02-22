untyped

global function OnWeaponPrimaryAttack_weapon_blazeSg

#if SERVER	
global function OnWeaponNpcPrimaryAttack_weapon_blazeSg
#endif // #if SERVER

// Functionally identical to OnWeaponPrimaryAttack_weapon_softball, so it's copied
var function OnWeaponPrimaryAttack_weapon_blazeSg( entity weapon, WeaponPrimaryAttackParams attackParams ) {
    entity player = weapon.GetWeaponOwner()

	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
    //vector bulletVec = ApplyVectorSpread( attackParams.dir, player.GetAttackSpreadAngle() * 2.0 )
	//attackParams.dir = bulletVec

    if ( IsServer() || weapon.ShouldPredictProjectiles() ) {
		vector offset = Vector( 30.0, 6.0, -4.0 )
		if ( weapon.IsWeaponInAds() )
			offset = Vector( 30.0, 0.0, -3.0 )
		vector attackPos = player.OffsetPositionFromView( attackParams[ "pos" ], offset )	// forward, right, up
		FireBlazeSlug( weapon, attackParams )
	}
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_weapon_blazeSg( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
	FireBlazeSlug( weapon, attackParams, true )
}
#endif // #if SERVER

function FireBlazeSlug( entity weapon, WeaponPrimaryAttackParams attackParams, isNPCFiring = false ) {
    vector angularVelocity = Vector(2000, 0, 0) // Slug doesn't tumble.
	
    int damageType = DF_RAGDOLL | DF_EXPLOSION | DF_STOPS_TITAN_REGEN

    entity slug = weapon.FireWeaponGrenade( attackParams.pos, attackParams.dir, angularVelocity, 0.0, damageType, damageType, !isNPCFiring, true, false )

    if ( slug )
    {
        #if SERVER
			Grenade_Init( slug, weapon )
        #else
            entity weaponOwner = weapon.GetWeaponOwner()
			SetTeam( slug, weaponOwner.GetTeam() )
        #endif 
    }
}
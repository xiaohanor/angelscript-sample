
class UGameplay_Projectile_Bullet_Impact_FlyingCarGunnerTurret_SoundDefAdapter : USkylineFlyingCarEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Stop Grounded Movement*/
	UFUNCTION(BlueprintOverride)
	void OnStopGroundedMovement()
	{
		//SoundDef.();
	}

	/*On Start Grounded Movement*/
	UFUNCTION(BlueprintOverride)
	void OnStartGroundedMovement()
	{
		//SoundDef.();
	}

	/*On Take Damage*/
	UFUNCTION(BlueprintOverride)
	void OnTakeDamage(FSkylineFlyingCarDamage InParams)
	{
		//SoundDef.(InParams);
	}

	/*Car just landed after jumping from spline*/
	UFUNCTION(BlueprintOverride)
	void OnSplineHopEnd()
	{
		//SoundDef.();
	}

	/*Car is jumping away from spline tunnel*/
	UFUNCTION(BlueprintOverride)
	void OnSplineHopStart()
	{
		//SoundDef.();
	}

	/*Car is no longer close to edge*/
	UFUNCTION(BlueprintOverride)
	void OnCloseToEdgeEnd()
	{
		//SoundDef.();
	}

	/*Car just got close to the edge and can jump to another tunnel*/
	UFUNCTION(BlueprintOverride)
	void OnCloseToEdgeStart()
	{
		//SoundDef.();
	}

	/*On Turret Projectile Flyby*/
	UFUNCTION(BlueprintOverride)
	void OnTurretProjectileFlyby(FSkylineFlyingCarTurretProjectileFlyby InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Turret Projectile Hit*/
	UFUNCTION(BlueprintOverride)
	void OnTurretProjectileHit(FSkylineFlyingCarTurretProjectileImpact InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(InParams.ImpactPhysMat.AudioAsset);
		ImpactParams.Location = InParams.ImpactLocation;
		//ImpactParams.NormalAngle = InParams.ImpactNormal;

		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/*On Turret Gun Shot*/
	UFUNCTION(BlueprintOverride)
	void OnTurretGunShot(FSkylineFlyingCarTurretGunshot InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Collision*/
	UFUNCTION(BlueprintOverride)
	void OnCollision(FSkylineFlyingCarCollision InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Dash*/
	UFUNCTION(BlueprintOverride)
	void OnDash()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

}

class UGameplay_Weapon_Automatic_RocketLauncher_SkylineChase_SoundDefAdapter : USkylineFlyingCarEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Ramp Boost End*/
	UFUNCTION(BlueprintOverride)
	void OnRampBoostEnd()
	{
		//SoundDef.();
	}

	/*On Ramp Boost Start*/
	UFUNCTION(BlueprintOverride)
	void OnRampBoostStart()
	{
		//SoundDef.();
	}

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

	/*On Car Exploded*/
	UFUNCTION(BlueprintOverride)
	void OnCarExploded()
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

	/*On Car Exit Highway*/
	UFUNCTION(BlueprintOverride)
	void OnCarExitHighway()
	{
		//SoundDef.();
	}

	/*On Car Enter Highway*/
	UFUNCTION(BlueprintOverride)
	void OnCarEnterHighway()
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

	/*On Bazooka Shot*/
	UFUNCTION(BlueprintOverride)
	void OnBazookaShot()
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);
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
		//SoundDef.(InParams);
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
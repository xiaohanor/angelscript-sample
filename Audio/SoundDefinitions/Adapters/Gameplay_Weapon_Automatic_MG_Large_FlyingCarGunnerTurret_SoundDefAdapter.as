
class UGameplay_Weapon_Automatic_MG_Large_FlyingCarGunnerTurret_SoundDefAdapter : USkylineFlyingCarEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Take Damage*/
	UFUNCTION(BlueprintOverride)
	void OnTakeDamage(FSkylineFlyingCarDamage CarDamage)
	{
		//SoundDef.();
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

	/*On Turret Gun Shot*/
	UFUNCTION(BlueprintOverride)
	void OnTurretGunShot(FSkylineFlyingCarTurretGunshot InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = InParams.OverheatAmount;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//Print("OVerHeatAmount" + InParams.OverheatAmount, 1);
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
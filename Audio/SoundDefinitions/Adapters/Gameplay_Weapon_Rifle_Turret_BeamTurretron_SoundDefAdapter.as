
class UGameplay_Weapon_Rifle_Turret_BeamTurretron_SoundDefAdapter : UBasicAIWeaponEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Triggered when finished reloading*/
	UFUNCTION(BlueprintOverride)
	void OnReloadComplete()
	{
		//SoundDef.();
	}

	/*Triggered when starting to reload*/
	UFUNCTION(BlueprintOverride)
	void OnReload(FWeaponHandlingReloadParams InParams)
	{
		//SoundDef.(InParams);
	}

	/*Triggered for every projectile which is launched*/
	UFUNCTION(BlueprintOverride)
	void OnShotFired(FWeaponHandlingLaunchParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.MagazinSize = InParams.MagazineSize;
		WeaponParams.ShotsFiredAmount = InParams.NumShotsFired;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/*Triggered when we're about to start launching projectiles*/
	UFUNCTION(BlueprintOverride)
	void OnTelegraphShooting(FWeaponHandlingTelegraphParams InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
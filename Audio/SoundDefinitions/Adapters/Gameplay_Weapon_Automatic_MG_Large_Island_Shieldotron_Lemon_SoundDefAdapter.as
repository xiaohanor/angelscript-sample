
class UGameplay_Weapon_Automatic_MG_Large_Island_Shieldotron_Lemon_SoundDefAdapter : UBasicAIWeaponEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	AAIIslandJetpackShieldotron JetShieldotron;
	UBasicAIProjectileLauncherComponent LemonWeapon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetShieldotron = Cast<AAIIslandJetpackShieldotron>(SoundDef.HazeOwner);
		LemonWeapon = JetShieldotron.LemonLauncherComp;
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
		if (InParams.Weapon != LemonWeapon)
			return;
		
		FGameplayWeaponParams WeaponParams;
		//WeaponParams.OverheatAmount = 0.0;
		//WeaponParams.OverheatMaxAmount = 1.0;
		WeaponParams.MagazinSize = InParams.MagazineSize;
		WeaponParams.ShotsFiredAmount = InParams.NumShotsFired;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreenScaled("OnShotFired - Lemon", 1);
	}

	/*Triggered when we're about to start launching projectiles*/
	UFUNCTION(BlueprintOverride)
	void OnTelegraphShooting(FWeaponHandlingTelegraphParams InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}

class UGameplay_Weapon_Automatic_RocketLauncher_Island_Shieldotron_Mortar_SoundDefAdapter : UBasicAIWeaponEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	AAIIslandShieldotron Shieldotron;
	UIslandShieldotronMortarLauncherLeft MortarLeft;
	UIslandShieldotronMortarLauncherRight MortarRight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Shieldotron = Cast<AAIIslandShieldotron>(SoundDef.HazeOwner);
		MortarLeft = Shieldotron.MortarLauncherLeftComp;
		MortarRight = Shieldotron.MortarLauncherRightComp;
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
		if (InParams.Weapon != MortarLeft && InParams.Weapon != MortarRight)
			return;
		
		FGameplayWeaponParams WeaponParams;
		//WeaponParams.OverheatAmount = 0.0;
		//WeaponParams.OverheatMaxAmount = 1.0;
		WeaponParams.MagazinSize = InParams.MagazineSize;
		WeaponParams.ShotsFiredAmount = InParams.NumShotsFired;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreenScaled("OnShotFired - Mortar", 1);
	}

	/*Triggered when we're about to start launching projectiles*/
	UFUNCTION(BlueprintOverride)
	void OnTelegraphShooting(FWeaponHandlingTelegraphParams InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
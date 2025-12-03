
class UGameplay_Weapon_Automatic_RocketLauncher_Island_Shieldotron_Orb_SideScroller_SoundDefAdapter : UBasicAIWeaponEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	AAIslandShieldotronSidescroller Shieldotron;
	UBasicAIProjectileLauncherComponent OrbSideScrollerLauncherComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Shieldotron = Cast<AAIslandShieldotronSidescroller>(SoundDef.HazeOwner);

		if (Shieldotron != nullptr)
		{
			OrbSideScrollerLauncherComp = Shieldotron.LauncherComp;
			return;
		}

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
		if (InParams.Weapon != OrbSideScrollerLauncherComp)
		return;
		
		FGameplayWeaponParams WeaponParams;
		//WeaponParams.OverheatAmount = 0.0;
		//WeaponParams.OverheatMaxAmount = 1.0;
		WeaponParams.MagazinSize = 1;
		WeaponParams.ShotsFiredAmount = 1;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreenScaled("OnShotFired - Orb", 1);
	}

	/*Triggered when we're about to start launching projectiles*/
	UFUNCTION(BlueprintOverride)
	void OnTelegraphShooting(FWeaponHandlingTelegraphParams InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
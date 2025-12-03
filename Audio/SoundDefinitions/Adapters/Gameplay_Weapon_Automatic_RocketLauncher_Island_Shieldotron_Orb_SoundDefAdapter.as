
class UGameplay_Weapon_Automatic_RocketLauncher_Island_Shieldotron_Orb_SoundDefAdapter : UBasicAIWeaponEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	AAIIslandJetpackShieldotron Shieldotron;
	UIslandShieldotronOrbLauncher OrbLauncherComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Shieldotron = Cast<AAIIslandJetpackShieldotron>(SoundDef.HazeOwner);

		if (Shieldotron != nullptr)
		{
			OrbLauncherComp = Shieldotron.OrbLauncherComp;
			return;
		}

		// Since they use the same component we can re-use the same SD logic.
		auto OtherShieldotronWithOrbLauncher = Cast<AAIIslandShieldotron>(SoundDef.HazeOwner);
		if (OtherShieldotronWithOrbLauncher != nullptr)
		{
			OrbLauncherComp = OtherShieldotronWithOrbLauncher.OrbLauncherComp;
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
		if (InParams.Weapon != OrbLauncherComp)
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
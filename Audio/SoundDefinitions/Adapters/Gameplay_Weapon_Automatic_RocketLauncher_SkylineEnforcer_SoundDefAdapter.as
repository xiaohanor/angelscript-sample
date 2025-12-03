
class UGameplay_Weapon_Automatic_RocketLauncher_SkylineEnforcer_SoundDefAdapter : UEnforcerWeaponEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Reload*/
	UFUNCTION(BlueprintOverride)
	void OnReload(FEnforcerWeaponEffectReloadParams InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Launch*/
	UFUNCTION(BlueprintOverride)
	void OnLaunch(FEnforcerWeaponEffectLaunchParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		//WeaponParams.OverheatAmount = 0.0;
		//WeaponParams.OverheatMaxAmount = 1.0;
		WeaponParams.MagazinSize = InParams.MagazineSize;
		WeaponParams.ShotsFiredAmount = InParams.NumShotsFired;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/*On Telegraph*/
	UFUNCTION(BlueprintOverride)
	void OnTelegraph(FEnforcerWeaponEffectTelegraphData InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
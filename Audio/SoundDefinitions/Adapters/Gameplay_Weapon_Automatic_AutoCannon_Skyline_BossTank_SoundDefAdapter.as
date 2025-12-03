
class UGameplay_Weapon_Automatic_AutoCannon_Skyline_BossTank_SoundDefAdapter : USkylineBossTankAutoCannonProjectileEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FSkylineBossTankAutoCannonProjectileOnImpactEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FSkylineBossTankAutoCannonProjectileOnFireEventData InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreen(f"Shoot - {Time::AudioTimeSeconds})", 10);
	}

	/* END OF AUTO-GENERATED CODE */

}
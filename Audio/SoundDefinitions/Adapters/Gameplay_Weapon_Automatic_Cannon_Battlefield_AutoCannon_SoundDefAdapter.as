
class UGameplay_Weapon_Automatic_Cannon_Battlefield_AutoCannon_SoundDefAdapter : UBattlefieldAutoCannonEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Shoot*/
	UFUNCTION(BlueprintOverride)
	void OnShoot()
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 1.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreen(f"Shoot - {Time::AudioTimeSeconds})", 10);
	}

	/* END OF AUTO-GENERATED CODE */

}
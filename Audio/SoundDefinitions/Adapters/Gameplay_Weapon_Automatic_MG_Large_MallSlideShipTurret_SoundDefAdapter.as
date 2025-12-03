
class UGameplay_Weapon_Automatic_MG_Large_MallSlideShipTurret_SoundDefAdapter : UAutoTurretEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Shot Fired*/
	UFUNCTION(BlueprintOverride)
	void OnShotFired(FGameplayWeaponParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;
		

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
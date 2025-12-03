
class UGameplay_Weapon_Automatic_MG_Large_DropShipTurret_Player_SoundDefAdapter : UControllableDropShipEffectEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Shot Fired*/
	UFUNCTION(BlueprintOverride)
	void ShotFired(FControllabeDropShipShootParams Params)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
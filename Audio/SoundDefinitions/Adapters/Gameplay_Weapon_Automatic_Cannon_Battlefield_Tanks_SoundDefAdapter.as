
class UGameplay_Weapon_Automatic_Cannon_Battlefield_Tanks_SoundDefAdapter : UBattlefieldTankEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Tank Fired*/
	UFUNCTION(BlueprintOverride)
	void OnTankFired(FBattlefieldTankFiredParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1.0;
		WeaponParams.MagazinSize = 1.0;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/* END OF AUTO-GENERATED CODE */

}

class UGameplay_Weapon_Automatic_MG_Large_MallStrafeRunShipTurret_SoundDefAdapter : UASkylineMallChaseStrafeRunProjectileEffectEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Shot Fired*/
	UFUNCTION(BlueprintOverride)
	void OnShotFired(FSkylineMallChaseStrafeRunWeaponParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.MagazinSize = InParams.MagazinSize;
		WeaponParams.ShotsFiredAmount = InParams.ShotsFiredAmount;
		

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/*Impact*/
	UFUNCTION(BlueprintOverride)
	void Impact(FSkylineMallChaseStrafeRunProjectileImpactParams InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}

class UGameplay_Weapon_Automatic_MG_Large_Skyline_HighwayBossVehicle_SoundDefAdapter : USkylineHighwayBossVehicleEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Shot Impact*/
	// UFUNCTION(BlueprintOverride)
	// void ShotImpact(FControllableDropShipShotImpactParams InParams)
	// {
	// 	//SoundDef.(InParams);
	// }

	/*Shot Fired*/
	UFUNCTION(BlueprintOverride)
	void OnGunFire(FSkylineHighwayBossVehicleEffectHandlerOnGunFireData InParams)
	{
		FGameplayWeaponParams Params;
		Params.MagazinSize = 8;
		Params.ShotsFiredAmount = InParams.ShotIndex;	
		SoundDef.TriggerOnShotFired(Params);
	}

	/* END OF AUTO-GENERATED CODE */

}
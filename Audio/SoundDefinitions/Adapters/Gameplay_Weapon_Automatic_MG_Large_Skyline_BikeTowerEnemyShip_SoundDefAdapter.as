
class UGameplay_Weapon_Automatic_MG_Large_Skyline_BikeTowerEnemyShip_SoundDefAdapter : USkylineBossTankAutoCannonProjectileEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */


	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FSkylineBossTankAutoCannonProjectileOnFireEventData InParams)
	{
		FGameplayWeaponParams Params;
		Params.MagazinSize = InParams.MagazinSize;
		Params.ShotsFiredAmount = InParams.FiredAmount;
		Params.ReloadTime = InParams.ReloadTime;

		SoundDef.TriggerOnShotFired(Params);
	}

	/* END OF AUTO-GENERATED CODE */

}
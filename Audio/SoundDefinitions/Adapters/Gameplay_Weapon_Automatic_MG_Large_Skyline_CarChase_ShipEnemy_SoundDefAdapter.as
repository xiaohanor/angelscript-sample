
class UGameplay_Weapon_Automatic_MG_Large_Skyline_CarChase_ShipEnemy_SoundDefAdapter : USkylineFlyingCarEnemyBurstFireProjectileEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Player Damage*/
	UFUNCTION(BlueprintOverride)
	void OnPlayerDamage(FSkylineFlyingCarEnemyBurstFireProjectileOnPlayerDamageEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FSkylineFlyingCarEnemyBurstFireProjectileOnImpactEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Launch*/
	UFUNCTION(BlueprintOverride)
	void OnLaunch()
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1;
		WeaponParams.MagazinSize = 1;
		WeaponParams.ReloadTime = 0;
		WeaponParams.OverheatAmount = 0;
		WeaponParams.OverheatMaxAmount = 1;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreenScaled("OnShotFired - ShipEnemy", 1);
	}

	/* END OF AUTO-GENERATED CODE */

}
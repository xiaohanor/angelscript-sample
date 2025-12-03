
class UGameplay_Weapon_Automatic_MG_Large_Skyline_CarChase_CarEnemy_SoundDefAdapter : USkylineFlyingCarEnemyTurretEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Hit*/
	UFUNCTION(BlueprintOverride)
	void OnHit(FSkylineFlyingCarEnemyTurretHitEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FSkylineFlyingCarEnemyTurretFireEventData InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1;
		WeaponParams.MagazinSize = 1;
		WeaponParams.ReloadTime = 0;
		WeaponParams.OverheatAmount = 0;
		WeaponParams.OverheatMaxAmount = 1;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
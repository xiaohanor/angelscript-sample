
class UGameplay_Weapon_Automatic_MG_Large_GravityCarEnemyRifle_SoundDefAdapter : UGravityBikeSplineCarEnemyTurretEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */
	
	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FGravityBikeSplineCarEnemyTurretFireEventData InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1;
		WeaponParams.MagazinSize = 1;
		WeaponParams.ReloadTime = 0;
		WeaponParams.OverheatAmount = 0;
		WeaponParams.OverheatMaxAmount = 1;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}
	/*On Hit*/
	UFUNCTION(BlueprintOverride)
	void OnHit(FGravityBikeSplineCarEnemyTurretHitEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */
}
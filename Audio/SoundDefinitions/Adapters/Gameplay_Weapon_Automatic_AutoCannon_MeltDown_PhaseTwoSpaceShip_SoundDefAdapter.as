
class UGameplay_Weapon_Automatic_AutoCannon_MeltDown_PhaseTwoSpaceShip_SoundDefAdapter : UMeltdownBossPhaseTwoSpaceShipEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Despawn*/
	UFUNCTION(BlueprintOverride)
	void Despawn()
	{
		//SoundDef.();
	}

	/*Shot Impact*/
	UFUNCTION(BlueprintOverride)
	void ShotImpact(FMeltdownBossPhaseTwoSpaceShipShotImpactParams InParams)
	{
		//SoundDef.(InParams);
	}

	/*Shoot*/
	UFUNCTION(BlueprintOverride)
	void Shoot(FMeltdownBossPhaseTwoSpaceShipShootParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreen(f"Shoot - {Time::AudioTimeSeconds})", 10);
	}

	/*Throw*/
	UFUNCTION(BlueprintOverride)
	void Throw()
	{
		//SoundDef.();
	}

	/*Spawn*/
	UFUNCTION(BlueprintOverride)
	void Spawn()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

}
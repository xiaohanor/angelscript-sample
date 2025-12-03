
class UGameplay_Weapon_Automatic_RocketLauncher_Coast_WingsuitBoss_SoundDefAdapter : UWingsuitBossEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Machine Gun Bullet Impact*/
	UFUNCTION(BlueprintOverride)
	void OnMachineGunBulletImpact(FWingsuitMachineGunBulletImpactEffectParams InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Shoot Machine Gun Bullet*/
	UFUNCTION(BlueprintOverride)
	void OnShootMachineGunBullet(FWingsuitShootMachineGunBulletEffectParams InParams)
	{
		//SoundDef.(InParams);
	}

	/*When the boss shoots a mine*/
	UFUNCTION(BlueprintOverride)
	void OnShootMine()
	{
		//SoundDef.();
	}

	/*When the boss shoots a mine*/
	UFUNCTION(BlueprintOverride)
	void OnShootAirMine()
	{
		//SoundDef.();
	}

	/*The enemy has fired a multi rocket (5 rockets towards the player)*/
	UFUNCTION(BlueprintOverride)
	void OnShootMultiRocket()
	{
		TriggerCount = 0;
		
		MultiRocketLaunched();
		HandleMultiRocketLaunchTimer = Timer::SetTimer(this,n"MultiRocketLaunched", 0.05, true);

		//Print("BombLaunched", 1.f);
	}

	/*The enemy has fired a single rocket.*/
	UFUNCTION(BlueprintOverride)
	void OnShootRocket()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

	int TriggerCount = 0;
	FTimerHandle HandleMultiRocketLaunchTimer;

	UFUNCTION()
	void MultiRocketLaunched()
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1.0;
		WeaponParams.MagazinSize = 1.0;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//Print("SoundDefTrigger", 1.f);

		++TriggerCount;

		if(TriggerCount == 5)
			Timer::ClearTimer(this, n"MultiRocketLaunched");

	}

}
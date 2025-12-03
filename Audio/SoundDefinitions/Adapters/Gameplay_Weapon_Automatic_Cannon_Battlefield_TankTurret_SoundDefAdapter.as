
class UGameplay_Weapon_Automatic_Cannon_Battlefield_TankTurret_SoundDefAdapter : UBattlefieldTankTurretEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Turret Stop Shoot*/
	UFUNCTION(BlueprintOverride)
	void OnTurretStopShoot()
	{
		Timer::ClearTimer(this, n"GattlingGunDelayAttack");
	}

	/*On Turret Start Shoot*/
	UFUNCTION(BlueprintOverride)
	void OnTurretStartShoot()
	{
		
		GattlingGunDelayAttack();
		GattlingGunShootTimer = Timer::SetTimer(this,n"GattlingGunDelayAttack", 0.18, true);

		//PrintToScreen(f"Shoot - {Time::AudioTimeSeconds})", 10);
	}

	/* END OF AUTO-GENERATED CODE */

	int TriggerCount = 0;
	FTimerHandle GattlingGunShootTimer;

	UFUNCTION()
	void GattlingGunDelayAttack()
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1.0;
		WeaponParams.MagazinSize = 1.0;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//Print("ShotFired", 1.f);

	}

}
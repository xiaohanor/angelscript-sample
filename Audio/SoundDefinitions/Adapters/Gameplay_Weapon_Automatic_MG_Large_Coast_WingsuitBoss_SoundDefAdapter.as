
class UGameplay_Weapon_Automatic_MG_Large_Coast_WingsuitBoss_SoundDefAdapter : UWingsuitBossEffectHandler
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
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
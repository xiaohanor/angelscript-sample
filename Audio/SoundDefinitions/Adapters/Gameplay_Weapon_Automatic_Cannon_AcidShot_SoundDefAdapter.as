
class UGameplay_Weapon_Automatic_Cannon_AcidShot_SoundDefAdapter : UAdultDragonAcidProjectileEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Acid Projectile Fire*/
	UFUNCTION(BlueprintOverride)
	void AcidProjectileFire(FAdultDragonAcidBoltFireParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);

		//PrintToScreen(f"Shoot - {Time::AudioTimeSeconds})", 10);
	}

	/*Acid Projectile Impact Explosion*/
	UFUNCTION(BlueprintOverride)
	void AcidProjectileImpactExplosion(FAdultDragonAcidBoltImpactParams InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
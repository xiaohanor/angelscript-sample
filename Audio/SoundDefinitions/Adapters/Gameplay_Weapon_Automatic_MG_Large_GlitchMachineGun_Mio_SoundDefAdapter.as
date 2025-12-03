
class UGameplay_Weapon_Automatic_MG_Large_GlitchMachineGun_Mio_SoundDefAdapter : UMeltdownGlitchShootingEffectHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Projectile Fired*/
	UFUNCTION(BlueprintOverride)
	void OnProjectileFired(FMeltdownGlitchProjectileFireEffectParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1;
		WeaponParams.MagazinSize = 1;
		WeaponParams.ReloadTime = 0;
		WeaponParams.OverheatAmount = 0;
		WeaponParams.OverheatMaxAmount = 0;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
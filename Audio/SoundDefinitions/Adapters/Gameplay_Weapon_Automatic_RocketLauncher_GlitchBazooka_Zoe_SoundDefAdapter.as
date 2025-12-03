
class UGameplay_Weapon_Automatic_RocketLauncher_GlitchBazooka_Zoe_SoundDefAdapter : UMeltdownGlitchShootingEffectHandler
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
		WeaponParams.MagazinSize = 1;
		WeaponParams.ShotsFiredAmount = 1;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/*Glitch Sword*/
	UFUNCTION(BlueprintOverride)
	void OnSwordAttackStarted(FMeltdownGlitchSwordSwingEffectParams InParams)
	{
		
	}

	/* END OF AUTO-GENERATED CODE */

}
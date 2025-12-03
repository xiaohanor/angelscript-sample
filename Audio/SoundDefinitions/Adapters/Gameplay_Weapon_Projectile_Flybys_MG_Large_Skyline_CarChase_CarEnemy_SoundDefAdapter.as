
class UGameplay_Weapon_Projectile_Flybys_MG_Large_Skyline_CarChase_CarEnemy_SoundDefAdapter : UBasicAIProjectileEffectHandler
{
	UGameplay_Weapon_Projectile_Flybys_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Flybys_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FBasicAiProjectileOnImpactData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Launch*/
	UFUNCTION(BlueprintOverride)
	void OnLaunch()
	{
		//SoundDef.();
	}

	/*On Prime*/
	UFUNCTION(BlueprintOverride)
	void OnPrime()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

}
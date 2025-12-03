
class UGameplay_Projectile_Bullet_Impact_Island_Shieldotron_Lemon_SoundDefAdapter : UBasicAIProjectileEffectHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FBasicAiProjectileOnImpactData InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.HitResult.Location;

		const FVector ToBullet = InParams.HitResult.TraceStart * -1;

		ImpactParams.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(ToBullet, InParams.HitResult.ImpactNormal);

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ETraceTypeQuery::WeaponTraceEnemy);

		ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(
			AudioTrace::GetPhysMaterialFromLocation(InParams.HitResult.Location, InParams.HitResult.ImpactNormal, TraceSettings).AudioAsset
			);

		SoundDef.Trigger_OnProjectileImpact(ImpactParams);

		//PrintToScreenScaled("OnImpact - Lemon", 1);
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
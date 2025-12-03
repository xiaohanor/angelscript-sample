
class UGameplay_Weapon_Projectile_NPC_Skyline_Enforcer_Rifle_Impact_SoundDefAdapter : USkylineEnforcerRifleProjectileEffectEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FSkylineEnforcerRifleProjectileOnImpactData InParams)
	{
		FProjectileSharedImpactAudioParams Params;
		Params.HitActor = InParams.HitResult.Actor;

		Params.Location = InParams.HitResult.Location;

		const FVector ToBullet = InParams.HitResult.TraceStart * -1;
		Params.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(ToBullet, InParams.HitResult.ImpactNormal);

		FHazeTraceSettings TraceSettings;
		TraceSettings.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);

		Params.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(InParams.HitResult, TraceSettings).AudioAsset);
		SoundDef.Trigger_OnProjectileImpact(Params);
	}

	/*On Deflected*/
	UFUNCTION(BlueprintOverride)
	void OnDeflected()
	{
		//SoundDef.();
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
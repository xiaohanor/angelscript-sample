
class UGameplay_Projectile_Bullet_Impact_BeamTurretron_SoundDefAdapter : UIslandBeamTurretronProjectileEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FIslandBeamTurretronProjectileOnImpactEventData InParams)
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

		//PrintToScreenScaled("OnImpact - Turretron", 1);
	}

	/*On Launch*/
	UFUNCTION(BlueprintOverride)
	void OnLaunch()
	{
		//SoundDef.();
	}

	
	/*On Player Damage*/
	UFUNCTION(BlueprintOverride)
	void OnPlayerDamage(FIslandBeamTurretronProjectileOnPlayerDamageEventData InParams)
	{
		//SoundDef.(InParams);
	}
/* END OF AUTO-GENERATED CODE */

}
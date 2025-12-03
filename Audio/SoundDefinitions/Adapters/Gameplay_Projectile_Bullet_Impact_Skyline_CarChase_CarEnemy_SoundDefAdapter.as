
class UGameplay_Projectile_Bullet_Impact_Skyline_CarChase_CarEnemy_SoundDefAdapter : USkylineFlyingCarEnemyTurretEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Hit*/
	UFUNCTION(BlueprintOverride)
	void OnHit(FSkylineFlyingCarEnemyTurretHitEventData InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.HitResult.Location;

		const FVector ToBullet = InParams.StartRotation.ForwardVector * -1;

		ImpactParams.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(ToBullet, InParams.HitResult.ImpactNormal);

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromLocation(ImpactParams.Location, ToBullet, Trace).AudioAsset);

		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FSkylineFlyingCarEnemyTurretFireEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
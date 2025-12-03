
class UGameplay_Projectile_Bullet_Impact_GravityCarEnemyRifle_SoundDefAdapter : UGravityBikeSplineCarEnemyTurretEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FGravityBikeSplineCarEnemyTurretFireEventData InParams)
	{
		//SoundDef.(InParams);
	}
	/*On Hit*/
	UFUNCTION(BlueprintOverride)
	void OnHit(FGravityBikeSplineCarEnemyTurretHitEventData InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.HitResult.Location;

		const FVector ToBullet = InParams.StartRotation.ForwardVector * -1;

		ImpactParams.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(ToBullet, InParams.HitResult.ImpactNormal);

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromLocation(ImpactParams.Location, ToBullet, Trace).AudioAsset);

		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/* END OF AUTO-GENERATED CODE */
}

class UGameplay_Projectile_Bullet_Impact_Skyline_CarChase_ShipEnemy_SoundDefAdapter : USkylineFlyingCarEnemyBurstFireProjectileEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Player Damage*/
	UFUNCTION(BlueprintOverride)
	void OnPlayerDamage(FSkylineFlyingCarEnemyBurstFireProjectileOnPlayerDamageEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FSkylineFlyingCarEnemyBurstFireProjectileOnImpactEventData InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.HitResult.Location;

		const FVector ToBullet = InParams.HitResult.ImpactNormal;

		ImpactParams.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(ToBullet, InParams.HitResult.ImpactNormal);

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromLocation(ImpactParams.Location, ToBullet, Trace).AudioAsset);

		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/*On Launch*/
	UFUNCTION(BlueprintOverride)
	void OnLaunch()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

}
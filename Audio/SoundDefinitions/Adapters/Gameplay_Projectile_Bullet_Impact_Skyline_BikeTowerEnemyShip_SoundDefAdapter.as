
class UGameplay_Projectile_Bullet_Impact_Skyline_BikeTowerEnemyShip_SoundDefAdapter : USkylineBossTankAutoCannonProjectileEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FSkylineBossTankAutoCannonProjectileOnImpactEventData InParams)
	{
		FProjectileSharedImpactAudioParams Params;

		Params.Location = InParams.ImpactPoint;
		const FVector ToBullet = (InParams.TraceStart - InParams.ImpactPoint).GetSafeNormal();
		Params.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(ToBullet, InParams.Normal);
		Params.HitActor = InParams.Actor;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);

		Params.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromLocation(Params.Location, InParams.Normal, Trace).AudioAsset);
		SoundDef.Trigger_OnProjectileImpact(Params);
	}


	/* END OF AUTO-GENERATED CODE */

}
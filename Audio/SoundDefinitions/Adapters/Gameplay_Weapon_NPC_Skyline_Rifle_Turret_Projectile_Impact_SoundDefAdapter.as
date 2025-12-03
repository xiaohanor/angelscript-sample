
class UGameplay_Weapon_NPC_Skyline_Rifle_Turret_Projectile_Impact_SoundDefAdapter : USkylineSniperProjectileEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

		/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FSkylineSniperProjectileImpactParams InParams)
	{
		FProjectileSharedImpactAudioParams Params;
		Params.HitActor = InParams.Hit.Actor;

		Params.Location = InParams.Hit.Location;

		const FVector ToBullet = InParams.Hit.TraceStart * -1;
		Params.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(ToBullet, InParams.Hit.ImpactNormal);

		FHazeTraceSettings TraceSettings;
		TraceSettings.TraceWithChannel(ECollisionChannel::ECC_WorldDynamic);

		Params.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(InParams.Hit, TraceSettings).AudioAsset);

		SoundDef.Trigger_OnProjectileImpact(Params);
	}


	/* END OF AUTO-GENERATED CODE */

}
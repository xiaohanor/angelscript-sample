
class UGameplay_Projectile_Bullet_Impact_GravityBikeFree_SoundDefAdapter : UGravityBikeMissileLauncherProjectileEventHandler
{
	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Spawn*/
	UFUNCTION(BlueprintOverride)
	void OnSpawn()
	{
		//SoundDef.();
	}

	/*On Impact*/
	UFUNCTION(BlueprintOverride)
	void OnImpact(FGravityBikeMissileLauncherProjectileImpactEventData InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.ImpactPoint;		
		//ImpactParams.NormalAngle = InParams.ImpactNormal;

		auto TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromLocation(InParams.ImpactPoint, InParams.ImpactNormal, TraceSettings).AudioAsset);
		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/*On Phase Activated*/
	UFUNCTION(BlueprintOverride)
	void OnPhaseActivated(FGravityBikeMissileLauncherProjectilePhaseActivatedEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Un Spawn*/
	UFUNCTION(BlueprintOverride)
	void OnUnSpawn()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */
}
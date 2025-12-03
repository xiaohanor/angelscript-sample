
class UGameplay_Projectile_Bullet_Impact_HackableSniperTurret_SoundDefAdapter : UHackableSniperTurretEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Draw Laser Pointer*/
	UFUNCTION(BlueprintOverride)
	void OnDrawLaserPointer(FSniperTurretOnDrawLaserPointer InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Hit*/
	UFUNCTION(BlueprintOverride)
	void OnHit(FSniperTurretOnHitParams InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.AudioTraceParams.ImpactPoint;
		ImpactParams.NormalAngle = InParams.NormalAngle;

		ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromTraceQuery(InParams.AudioTraceParams).AudioAsset);

		SoundDef.Trigger_OnProjectileImpact(ImpactParams);

	}

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FSniperTurretOnFireParams InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Zoom Deactivated*/
	UFUNCTION(BlueprintOverride)
	void OnZoomDeactivated()
	{
		//SoundDef.();
	}

	/*On Zoom Activated*/
	UFUNCTION(BlueprintOverride)
	void OnZoomActivated()
	{
		//SoundDef.();
	}

	/*On Deactivated*/
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//SoundDef.();
	}

	/*On Activated*/
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

}
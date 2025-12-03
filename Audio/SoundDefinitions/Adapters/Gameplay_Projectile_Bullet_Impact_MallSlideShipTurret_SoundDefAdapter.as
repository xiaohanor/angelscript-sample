
class UGameplay_Projectile_Bullet_Impact_MallSlideShipTurret_SoundDefAdapter : UAutoTurretProjectileEffectEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Shot Impact*/
	UFUNCTION(BlueprintOverride)
	void ShotImpact(FAutoTurretProjectileImpactParams InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.ImpactLocation;
		ImpactParams.AudioPhysMat = InParams.AudioPhysMat;
		ImpactParams.NormalAngle = InParams.ImpactNormal;
		
		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
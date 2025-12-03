
class UGameplay_Projectile_Bullet_Impact_MallStrafeRunShipTurret_SoundDefAdapter : UASkylineMallChaseStrafeRunProjectileEffectEventHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Impact*/
	UFUNCTION(BlueprintOverride)
	void Impact(FSkylineMallChaseStrafeRunProjectileImpactParams InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.ImpactLocation;
		ImpactParams.AudioPhysMat = InParams.AudioPhysMat;
		ImpactParams.NormalAngle = InParams.ImpactNormal;
		
		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
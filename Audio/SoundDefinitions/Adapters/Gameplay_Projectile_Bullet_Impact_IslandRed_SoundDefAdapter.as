
class UGameplay_Projectile_Bullet_Impact_IslandRed_SoundDefAdapter : UIslandRedBlueWeaponBulletEffectHandler
{

	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*Called when the bullet impacts something*/
	UFUNCTION(BlueprintOverride)
	void OnBulletImpact(FIslandRedBlueWeaponOnBulletImpactParams InParams)
	{
		//SoundDef.(InParams);

		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.Location = InParams.ImpactPoint;

		auto AudioPhysMaterial = Cast<UPhysicalMaterialAudioAsset>(InParams.PhysMat.AudioAsset);
		ImpactParams.AudioPhysMat = AudioPhysMaterial;

		ImpactParams.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle((InParams.BulletLocation - InParams.ImpactPoint).GetSafeNormal(), InParams.ImpactNormal);


		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/* END OF AUTO-GENERATED CODE */

}
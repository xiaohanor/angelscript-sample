
class UGameplay_Projectile_Bullet_Impact_SoundDefAdapter : UScifiCopsGunEventHandler
{
	UGameplay_Weapon_Projectile_Impact_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Projectile_Impact_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Overheat*/
	UFUNCTION(BlueprintOverride)
	void OnOverheat(FScifiPlayerCopsGunOverheatData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Weapon Detach*/
	UFUNCTION(BlueprintOverride)
	void OnWeaponDetach(FScifiPlayerCopsGunWeaponDetachEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Weapon Attach*/
	UFUNCTION(BlueprintOverride)
	void OnWeaponAttach(FScifiPlayerCopsGunWeaponAttachEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Bullet Impact*/
	UFUNCTION(BlueprintOverride)
	void OnBulletImpact(FScifiPlayerCopsGunBulletOnImpactEventData InParams)
	{
		FProjectileSharedImpactAudioParams ImpactParams;
		ImpactParams.HitActor = InParams.BulletTarget != nullptr ? InParams.BulletTarget.Owner : nullptr;
		ImpactParams.Location = InParams.ImpactLocation;
		ImpactParams.NormalAngle = AudioSharedProjectiles::GetProjectileImpactAngle(InParams.ToBullet, InParams.ImpactNormal);

		if(InParams.PhysMat != nullptr)
			ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(InParams.PhysMat.AudioAsset);
		else
			ImpactParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(Game::GetHazeGameInstance().GlobalAudioDataAsset.DefaultAudioPhysMat);

		SoundDef.Trigger_OnProjectileImpact(ImpactParams);
	}

	/*On Recall*/
	UFUNCTION(BlueprintOverride)
	void OnRecall(FScifiPlayerCopsGunWeaponRecallEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Shoot*/
	UFUNCTION(BlueprintOverride)
	void OnShoot(FScifiPlayerCopsGunOnShootEventData InParams)
	{
		//SoundDef.(InParams);
	}

	/*On Aim Stopped*/
	UFUNCTION(BlueprintOverride)
	void OnAimStopped()
	{
		//SoundDef.();
	}

	/*On Aim Started*/
	UFUNCTION(BlueprintOverride)
	void OnAimStarted()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

}
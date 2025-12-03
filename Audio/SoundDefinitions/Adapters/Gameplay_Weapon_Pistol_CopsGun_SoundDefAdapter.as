
class UGameplay_Weapon_Pistol_CopsGun_SoundDefAdapter : UScifiCopsGunEventHandler
{
	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
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
		//SoundDef.(InParams);
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
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = InParams.OverheatAmount;
		WeaponParams.OverheatMaxAmount = InParams.OverheatMaxAmount;

		SoundDef.TriggerOnShotFired(WeaponParams);
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
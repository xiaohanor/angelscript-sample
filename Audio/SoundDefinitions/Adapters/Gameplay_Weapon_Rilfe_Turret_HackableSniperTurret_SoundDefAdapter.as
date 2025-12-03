
class UGameplay_Weapon_Rilfe_Turret_HackableSniperTurret_SoundDefAdapter : UHackableSniperTurretEventHandler
{

	UGameplay_Weapon_Automatic_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Weapon_Automatic_SoundDef>(Outer);
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
		//SoundDef.(InParams);
	}

	/*On Fire*/
	UFUNCTION(BlueprintOverride)
	void OnFire(FSniperTurretOnFireParams InParams)
	{
		FGameplayWeaponParams WeaponParams;
		WeaponParams.OverheatAmount = 0.0;
		WeaponParams.OverheatMaxAmount = 1.0;

		SoundDef.TriggerOnShotFired(WeaponParams);
	}

	/*On Zoom Deactivated*/
	UFUNCTION(BlueprintOverride)
	void OnZoomDeactivated()
	{
		SoundDef.TriggerOnZoomOut();
	}

	/*On Zoom Activated*/
	UFUNCTION(BlueprintOverride)
	void OnZoomActivated()
	{
		SoundDef.TriggerOnZoomIn();
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
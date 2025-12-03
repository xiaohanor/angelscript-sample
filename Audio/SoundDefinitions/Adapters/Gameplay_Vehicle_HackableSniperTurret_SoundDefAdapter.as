
class UGameplay_Vehicle_HackableSniperTurret_SoundDefAdapter : UHackableSniperTurretEventHandler
{

	UGameplay_Vehicle_HackableObject_SoundDef GetSoundDef() const property
	{
		return Cast<UGameplay_Vehicle_HackableObject_SoundDef>(Outer);
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
		SoundDef.OnAbilityOneshot();
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

	
	/*On Zoom Deactivated*/
	UFUNCTION(BlueprintOverride)
	void OnZoomDeactivated()
	{
		SoundDef.OnAbilityToggleDeactivated();
	}

	/*On Zoom Activated*/
	UFUNCTION(BlueprintOverride)
	void OnZoomActivated()
	{
		SoundDef.OnAbilityToggleActivated();
	}
/* END OF AUTO-GENERATED CODE */

}
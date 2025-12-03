
UCLASS(Abstract)
class UVO_Prison_Stealth_Shared_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void PrisonStealthGuard_OnStunStarted(FPrisonStealthGuardOnStunStartedParams PrisonStealthGuardOnStunStartedParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonStealthCamera_OnPlayerSpotted(){}

	UFUNCTION(BlueprintEvent)
	void PrisonStealthCamera_OnStunStarted(FPrisonStealthCameraOnStunStartedParams PrisonStealthCameraOnStunStartedParams){}

	UFUNCTION(BlueprintEvent)
	void HackableSniperTurret_OnHit(FSniperTurretOnHitParams SniperTurretOnHitParams){}

	UFUNCTION(BlueprintEvent)
	void HackableSniperTurret_OnFire(FSniperTurretOnFireParams SniperTurretOnFireParams){}

	UFUNCTION(BlueprintEvent)
	void HackableSniperTurret_OnActivated(){}

	/* END OF AUTO-GENERATED CODE */

}

UCLASS(Abstract)
class UPrison_Stealth_Shared_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnReset(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerLost(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerSpotted(){}

	UFUNCTION(BlueprintEvent)
	void OnStunStopped(){}

	UFUNCTION(BlueprintEvent)
	void OnStunStarted(FPrisonStealthCameraOnStunStartedParams PrisonStealthCameraOnStunStartedParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonStealthGuard_OnReset(){}

	UFUNCTION(BlueprintEvent)
	void PrisonStealthGuard_OnPlayerLost(){}

	UFUNCTION(BlueprintEvent)
	void PrisonStealthGuard_OnPlayerSpotted(){}

	UFUNCTION(BlueprintEvent)
	void PrisonStealthGuard_OnGuardStateChanged(FPrisonStealthGuardOnGuardStateChangedParams PrisonStealthGuardOnGuardStateChangedParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonStealthGuard_OnStunStopped(){}

	UFUNCTION(BlueprintEvent)
	void PrisonStealthGuard_OnStunStarted(FPrisonStealthGuardOnStunStartedParams PrisonStealthGuardOnStunStartedParams){}

	/* END OF AUTO-GENERATED CODE */

}
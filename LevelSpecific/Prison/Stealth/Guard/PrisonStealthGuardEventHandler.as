struct FPrisonStealthGuardOnGuardStateChangedParams
{
	UPROPERTY()
	EPrisonStealthGuardState GuardState;
}

struct FPrisonStealthGuardOnStunStartedParams
{
	UPROPERTY()
	bool bReset;
}

/**
 * 
 */
 UCLASS(Abstract)
 class UPrisonStealthGuardEventHandler : UPrisonStealthEnemyEventHandler
 {
	UPROPERTY(NotEditable)
	APrisonStealthGuard StealthGuard = nullptr;

	UPROPERTY()
	UNiagaraSystem Sys_Stunned;

	UPROPERTY()
	UNiagaraSystem Sys_Laser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		StealthGuard = Cast<APrisonStealthGuard>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStunStarted(FPrisonStealthGuardOnStunStartedParams Params) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStunStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGuardStateChanged(FPrisonStealthGuardOnGuardStateChangedParams Params) { }

	/**
	 * We have spotted a player, meaning it entered our vision. However we have not yet detected it (killed)
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerSpotted() { }

	/**
	 * A player was previously spotted or detected, and is no longer
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLost() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReset() { }
	
 }
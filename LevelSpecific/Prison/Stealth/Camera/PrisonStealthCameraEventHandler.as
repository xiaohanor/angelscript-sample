struct FPrisonStealthCameraOnStunStartedParams
{
	UPROPERTY()
	bool bReset;
}

UCLASS(Abstract)
class UPrisonStealthCameraEventHandler : UPrisonStealthEnemyEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APrisonStealthCamera StealthCamera = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		StealthCamera = Cast<APrisonStealthCamera>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStunStarted(FPrisonStealthCameraOnStunStartedParams Params) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStunStopped() { }

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
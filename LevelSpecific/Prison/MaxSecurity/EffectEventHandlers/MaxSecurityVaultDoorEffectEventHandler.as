UCLASS(Abstract)
class UMaxSecurityVaultDoorEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateLockdown() {}
}
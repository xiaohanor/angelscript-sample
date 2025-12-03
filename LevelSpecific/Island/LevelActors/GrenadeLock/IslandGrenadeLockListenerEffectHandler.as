struct FIslandGrenadeLockListenerOnePlayerEffectParams
{
	UPROPERTY()
	AIslandGrenadeLockListener Listener;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FIslandGrenadeLockListenerGenericEffectParams
{
	FIslandGrenadeLockListenerGenericEffectParams(AIslandGrenadeLockListener In_Listener)
	{
		Listener = In_Listener;
	}

	UPROPERTY()
	AIslandGrenadeLockListener Listener;
}

UCLASS(Abstract)
class UIslandGrenadeLockListenerEffectHandler : UHazeEffectEventHandler
{
	// When one player succeeds with their grenade locks.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOnePlayerSucceeded(FIslandGrenadeLockListenerOnePlayerEffectParams Params) {}

	// When one player who previously succeeded fails with their grenade locks.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOnePlayerFailed(FIslandGrenadeLockListenerOnePlayerEffectParams Params) {}

	// When the grenade lock listener completes.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnListenerCompleted(FIslandGrenadeLockListenerGenericEffectParams Params) {}

	// When the grenade lock listener resets (this is only called if the listener is resettable or the reset function is manually called).
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnListenerReset(FIslandGrenadeLockListenerGenericEffectParams Params) {}
}
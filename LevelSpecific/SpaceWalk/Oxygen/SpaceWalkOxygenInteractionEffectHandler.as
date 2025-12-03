struct FSpaceWalkOxygenInteractionEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USpaceWalkOxygenInteractionEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	// When a player pumps and it was correct
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenPumpSuccesful(FSpaceWalkOxygenInteractionEffectParams Params) {}
	// When a player pumps and it was incorrect
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenPumpFailed(FSpaceWalkOxygenInteractionEffectParams Params) {}
	// When a player doesn't press to pump and it reaches the end and fails
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenFailedTimeout(FSpaceWalkOxygenInteractionEffectParams Params) {}

	// When the full oxygen tank is completed
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenCompleted() {}
};
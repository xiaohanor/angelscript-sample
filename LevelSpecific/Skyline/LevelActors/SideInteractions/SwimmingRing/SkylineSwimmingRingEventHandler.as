struct FSkylineSwimmingRingEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FSkylineSwimmingBumpRingEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	FVector Force;
}

struct FSkylineSwimmingBumpEnvRingEventData
{
	UPROPERTY()
	float ImpulseStrength;
	UPROPERTY()
	FVector ApproxBumpPoint;
}

UCLASS(Abstract)
class USkylineSwimmingRingEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnterJumpIntoFromAbove(FSkylineSwimmingRingEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnterSwimIntoFromBelow(FSkylineSwimmingRingEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLeaveJumpOut(FSkylineSwimmingRingEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerBumpIntoSide(FSkylineSwimmingBumpRingEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBumpIntoOtherRing(FSkylineSwimmingBumpEnvRingEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBumpIntoWall(FSkylineSwimmingBumpEnvRingEventData Data) {}
};
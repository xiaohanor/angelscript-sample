struct FUnluckyBirdEventData
{
	UPROPERTY()
	ATundra_IcePalace_UnluckyBird UnluckyBird;
}

struct FUnluckyBirdThrowableRockEventData
{
	UPROPERTY()
	ATundra_IcePalace_ThrowableRock Rock;
}

UCLASS(Abstract)
class UTundra_IcePalace_UnluckyBirdEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnluckyBirdHit(FUnluckyBirdEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnluckyBirdStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedThrowingRock(FUnluckyBirdThrowableRockEventData Data) {}
};
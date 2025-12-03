UCLASS(Abstract)
class UTundraCrackRootMonkeyHangerEffectHandler : UHazeEffectEventHandler
{
	ATundraCrackRootMonkeyHanger MonkeyHanger;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MonkeyHanger = Cast<ATundraCrackRootMonkeyHanger>(Owner);
	}

	// Will get called when the snow monkey starts hanging from the monkey hanger
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartHanging() {}

	// Will get called when the snow monkey stops hanging from the monkey hanger
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopHanging() {}

	// Will get called when the hanger reaches its lowest point
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedBottom() {}

	// Will get called when the hanger reaches its highest point
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedTop() {}

	// -1 = Down, 0 = still, 1 = Up
	UFUNCTION(BlueprintPure)
	int GetMonkeyHangerDirection() const property
	{
		return int(Math::Sign(MonkeyHanger.AcceleratedAlpha.Velocity));
	}

	// Absolute value of how fast the monkey hanger is moving up/down (this is in alpha/s so it might be lower than you expect!)
	UFUNCTION(BlueprintPure)
	float GetMonkeyHangerSpeed() const property
	{
		return Math::Abs(MonkeyHanger.AcceleratedAlpha.Velocity);
	}
}
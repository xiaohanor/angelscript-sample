struct FTundraMonkeyHangerReachParams
{
	UPROPERTY()
	float HitStrength;
}

UCLASS(Abstract)
class UTundraMonkeyHangerEffectHandler : UHazeEffectEventHandler
{
	ATundraMonkeyHanger MonkeyHanger;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MonkeyHanger = Cast<ATundraMonkeyHanger>(Owner);
	}

	// Will get called when the snow monkey starts hanging from the monkey hanger
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartHanging() {}

	// Will get called when the snow monkey stops hanging from the monkey hanger
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopHanging() {}

	// Will get called when the monkey's feet hit the ground
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedBottomOnGround(FTundraMonkeyHangerReachParams Params) {}

	// Will get called when monkey's feet hit the top of the flower (if the flower is closed while the monkey is hanging)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedBottomOnFlower(FTundraMonkeyHangerReachParams Params) {}

	// Will get called when the monkey hanger reaches the top (it's original location)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedTop(FTundraMonkeyHangerReachParams Params) {}

	// -1 = Down, 0 = still, 1 = Up
	UFUNCTION(BlueprintPure)
	int GetMonkeyHangerDirection() const property
	{
		return int(Math::Sign(MonkeyHanger.MonkeyHangerVelocity));
	}

	// Absolute value of how fast the monkey hanger is moving up/down
	UFUNCTION(BlueprintPure)
	float GetMonkeyHangerSpeed() const property
	{
		return Math::Abs(MonkeyHanger.MonkeyHangerVelocity);
	}
}
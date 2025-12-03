struct FPinballPlungerOnLaunchBallEventData
{
	UPROPERTY()
	UPinballBallComponent BallComp;
}

struct FPinballPlungerOnLaunchForwardEventData
{
	UPROPERTY()
	float LaunchDistance = 0.0;

	UPROPERTY()
	bool bHitTop = false;
}

UCLASS(Abstract)
class UPinballPlungerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	APinballPlunger Plunger;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plunger = Cast<APinballPlunger>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartPullBack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachBottom() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLaunchForward(FPinballPlungerOnLaunchForwardEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitTop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLaunchForward(FPinballPlungerOnLaunchForwardEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchBall(FPinballPlungerOnLaunchBallEventData EventData) {}

	UFUNCTION(BlueprintPure)
	float GetCurrentPullBackAlpha() const
	{
		return Plunger.GetCurrentPullBackAlpha();
	}

	UFUNCTION(BlueprintPure)
	float GetStopPullBackAlpha() const
	{
		return Plunger.GetStopPullBackAlpha();
	}
};
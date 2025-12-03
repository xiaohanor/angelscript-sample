struct FMoonmarketYarnBallEventParams
{
	UPROPERTY()
	float Velocity;

	FMoonmarketYarnBallEventParams(float InVelocity)
	{
		Velocity = InVelocity;
	}
}

UCLASS(Abstract)
class UMoonMarketYarnBallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand(FMoonmarketYarnBallEventParams LandingVelocity) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHorizontalCollide(FMoonmarketYarnBallEventParams HorizontalVelocity) {}
};
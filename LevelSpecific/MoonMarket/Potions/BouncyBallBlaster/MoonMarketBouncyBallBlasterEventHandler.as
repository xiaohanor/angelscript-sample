UCLASS(Abstract)
class UMoonMarketBouncyBallBlasterEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot() {}
};
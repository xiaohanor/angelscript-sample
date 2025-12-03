struct FMoonMarketBouncyBallHitEventParams
{
	AActor HitActor;
}

UCLASS(Abstract)
class UMoonMarketBouncyBallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FMoonMarketBouncyBallHitEventParams Params) {}
};
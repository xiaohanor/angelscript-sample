struct FEvergreenShootingPlantPlayerEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FEvergreenShootingPlantPoleCrawlerEffectParams
{
	UPROPERTY()
	AEvergreenPoleCrawler PoleCrawler;
}

UCLASS(Abstract)
class UEvergreenShootingPlantEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSquishPlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSquishPoleCrawler() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCaughtPoleCrawler(FEvergreenShootingPlantPoleCrawlerEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCaughtPlayer(FEvergreenShootingPlantPlayerEffectParams Params) {}
}
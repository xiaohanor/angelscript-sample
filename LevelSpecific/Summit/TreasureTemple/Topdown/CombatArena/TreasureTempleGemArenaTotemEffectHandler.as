struct FOnGemTotemFireParams
{
	UPROPERTY()
	FVector Location;
}

struct FOnGemTotemInitiateParams
{
	UPROPERTY()
	FVector Location;
}

struct FOnGemTotemDestroyedParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UTreasureTempleGemArenaTotemEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGemTotemFire(FOnGemTotemFireParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGemTotemInitiate(FOnGemTotemInitiateParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGemTotemDestroyed(FOnGemTotemDestroyedParams Params) {}
}
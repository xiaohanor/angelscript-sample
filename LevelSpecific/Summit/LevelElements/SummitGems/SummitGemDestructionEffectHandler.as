struct FOnSummitGemDestroyedParams
{
	UPROPERTY()
	float Scale;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;
}


UCLASS(Abstract)
class USummitGemDestructionEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyRegularGem(FOnSummitGemDestroyedParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroySmallGem(FOnSummitGemDestroyedParams Params) {}
};
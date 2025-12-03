struct FGemBrazierDeactivateParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UGemBrazierEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeactivateBrazier(FGemBrazierDeactivateParams Params) {}
}
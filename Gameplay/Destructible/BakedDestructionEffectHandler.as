struct FOnBakedDestructionTriggeredParams
{
	UPROPERTY()
	FVector WorldLocation;
}

UCLASS(Abstract)
class UBakedDestructionEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyObjectTriggered(FOnBakedDestructionTriggeredParams Params) {}
}
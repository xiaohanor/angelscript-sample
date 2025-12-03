struct FGameShowArenaBombHolderLoweringParams
{
	UPROPERTY()
	AGameShowArenaBombHolder BombHolder;
}

UCLASS(Abstract)
class UGameShowArenaBombHolderEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLowering(FGameShowArenaBombHolderLoweringParams Params)
	{
	}
};
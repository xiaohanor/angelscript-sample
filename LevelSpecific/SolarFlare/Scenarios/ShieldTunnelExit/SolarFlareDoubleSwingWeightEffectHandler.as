struct FSolarFlareDoubleSwingWeightParams
{
	UPROPERTY()
	FVector Location;
}

struct FSolarFlareDoubleSwingWeightAttachParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USolarFlareDoubleSwingWeightEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolarFlareDoubleSwingPlayerAttach(FSolarFlareDoubleSwingWeightAttachParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolarFlareDoubleSwingPlayerDettach(FSolarFlareDoubleSwingWeightAttachParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolarFlareDoubleSwingStartMoving(FSolarFlareDoubleSwingWeightParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolarFlareDoubleSwingStopMoving(FSolarFlareDoubleSwingWeightParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolarFlareContainerStartBreak() {}
};
struct FSolarFlareQuickCoverGeneralParams
{
	UPROPERTY()
	FVector Location;
}

struct FSolarFlareQuickCoverButtonMashParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	float Progress = 0.0;
}

UCLASS(Abstract)
class USolarFlareQuickCoverEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void QuickCoverButtonMashing(FSolarFlareQuickCoverButtonMashParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void QuickCoverOn(FSolarFlareQuickCoverGeneralParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void QuickCoverOff(FSolarFlareQuickCoverGeneralParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void QuickCoverImpact(FSolarFlareQuickCoverGeneralParams Params)
	{
	}
};
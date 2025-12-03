UCLASS(Abstract)
class USkylineTorRainDebrisEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkylineTorRainDebrisOnImpactEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphStart(FSkylineTorRainDebrisEventHandlerOnTelegraphStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanded(FSkylineTorRainDebrisEventHandlerOnLandedStartData Data) {}
}

struct FSkylineTorRainDebrisOnImpactEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FSkylineTorRainDebrisOnImpactEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FSkylineTorRainDebrisEventHandlerOnTelegraphStartData
{
	UPROPERTY()
	FVector TargetLocation;

	FSkylineTorRainDebrisEventHandlerOnTelegraphStartData(FVector InTargetLocation)
	{
		TargetLocation = InTargetLocation;
	}
}

struct FSkylineTorRainDebrisEventHandlerOnLandedStartData
{
	UPROPERTY()
	FHitResult HitResult;

	FSkylineTorRainDebrisEventHandlerOnLandedStartData(FHitResult Hit)
	{
		HitResult = Hit;
	}
}
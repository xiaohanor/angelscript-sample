struct FSkylineSlingableImpactEventData
{
	UPROPERTY()
	TArray<FHitResult> HitResults;
	UPROPERTY()
	FVector Velocity;
}

UCLASS(Abstract)
class UWhipSlingableObjectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbed()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrown()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkylineSlingableImpactEventData EventData)
	{
	}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeHitImpact()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRubberDuckLandInWater(FSkylineWaterToyLandInWaterData Data) {}
};
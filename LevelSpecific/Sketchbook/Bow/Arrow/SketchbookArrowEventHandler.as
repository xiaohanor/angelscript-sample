UCLASS(Abstract)
class USketchbookArrowEventHandler : UHazeEffectEventHandler
{
	ASketchbookArrow Arrow = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Arrow = Cast<ASketchbookArrow>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch(FSketchbookArrowLaunchEventData LaunchData) { }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hit(FSketchbookArrowHitEventData HitData) { }

    UFUNCTION(BlueprintPure)
    AHazePlayerCharacter GetPlayer() const
    {
        return Arrow.Player;
    }

    UFUNCTION(BlueprintPure)
    ASketchbookArrow GetArrow() const
    {
        return Arrow;
    }

    UFUNCTION(BlueprintPure)
    float GetChargeFactor() const
    {
        return Arrow.ChargeFactor;
    }
}

struct FSketchbookArrowHitEventData
{
    FSketchbookArrowHitEventData(ASketchbookArrow Arrow)
    {
        ChargeFraction = Arrow.ChargeFactor;
        Component = Arrow.HitData.Component;
		BoneName = Arrow.HitData.BoneName;
        RelativeImpactPoint = Component.WorldTransform.InverseTransformPosition(Arrow.HitData.ImpactPoint);
        RelativeImpactNormal = Component.WorldTransform.InverseTransformVector(Arrow.HitData.ImpactNormal);

		FHazeTraceSettings TraceSettings = Arrow.GetTraceSettings();
		AudioTraceParams = FHazeAudioTraceQuery(Arrow.HitData.Component, 
												Arrow.HitData.ImpactPoint, 
												Arrow.HitData.ImpactNormal, 
												TraceSettings.Shape, 
												TraceSettings.bTraceComplex);
    }
    
	UPROPERTY()
	float ChargeFraction;

    UPROPERTY()
	UPrimitiveComponent Component;

    UPROPERTY()
	FVector RelativeImpactPoint;

    UPROPERTY()
	FVector RelativeImpactNormal;

	UPROPERTY()
	FName BoneName;

	bool bHasControl;

	// Used for audio
	UPROPERTY()
	FHazeAudioTraceQuery AudioTraceParams;

	FVector GetImpactPoint() const
	{
		return Component.WorldTransform.TransformPosition(RelativeImpactPoint);
	}

	FVector GetImpactNormal() const
	{
		return Component.WorldTransform.TransformVector(RelativeImpactNormal);
	}
}
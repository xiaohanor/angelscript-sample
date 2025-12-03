UCLASS(Abstract)
class UWindArrowEventHandler : UHazeEffectEventHandler
{
	AHazePlayerCharacter Player = nullptr;
	AWindArrow WindArrow = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WindArrow = Cast<AWindArrow>(Owner);
		Player = WindArrow.Player;
	}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activate() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDraw() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnArrowFullyCharged() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch(FWindArrowLaunchEventData LaunchData) { }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hit(FWindArrowHitEventData HitData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEndDraw() { }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Deactivate() { }

    UFUNCTION(BlueprintPure)
    AHazePlayerCharacter GetPlayer() const
    {
        return Player;
    }

    UFUNCTION(BlueprintPure)
    AWindArrow GetWindArrow() const
    {
        return WindArrow;
    }

    UFUNCTION(BlueprintPure)
    float GetChargeFactor() const
    {
        return WindArrow.ChargeFactor;
    }
}

struct FWindArrowHitEventData
{
    FWindArrowHitEventData(AWindArrow WindArrow)
    {
        ChargeFraction = WindArrow.ChargeFactor;
        Component = WindArrow.HitData.Component;
        ImpactPoint = WindArrow.HitData.ImpactPoint;
        ImpactNormal = WindArrow.HitData.ImpactNormal;

		FHazeTraceSettings TraceSettings = WindArrow.GetTraceSettings();
		AudioTraceParams = FHazeAudioTraceQuery(WindArrow.HitData.Component, 
												WindArrow.HitData.ImpactPoint, 
												WindArrow.HitData.ImpactNormal, 
												TraceSettings.Shape, 
												TraceSettings.bTraceComplex);
    }

    FWindArrowHitEventData(ABlizzardArrow BlizzardArrow)
    {
        ChargeFraction = 1.0;
        Component = BlizzardArrow.HitData.Component;
        ImpactPoint = BlizzardArrow.HitData.ImpactPoint;
        ImpactNormal = BlizzardArrow.HitData.ImpactNormal;

		FHazeTraceSettings TraceSettings = BlizzardArrow.GetTraceSettings();
		AudioTraceParams = FHazeAudioTraceQuery(BlizzardArrow.HitData.Component, 
												BlizzardArrow.HitData.ImpactPoint, 
												BlizzardArrow.HitData.ImpactNormal, 
												TraceSettings.Shape, 
												TraceSettings.bTraceComplex);
    }
    
	UPROPERTY()
	float ChargeFraction;

    UPROPERTY()
	UPrimitiveComponent Component;

    UPROPERTY()
	FVector ImpactPoint;

    UPROPERTY()
	FVector ImpactNormal;

	// Used for audio
	UPROPERTY()
	FHazeAudioTraceQuery AudioTraceParams;
}
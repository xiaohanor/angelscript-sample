UCLASS(Abstract)
class UIceArrowEventHandler : UHazeEffectEventHandler
{
    
	AHazePlayerCharacter Player = nullptr;
	AIceArrow IceArrow = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Game::GetPlayer(IceBow::Player);
		IceArrow = Cast<AIceArrow>(Owner);
	}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activate() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch(FIceArrowLaunchEventData LaunchData) { }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hit(FIceArrowHitEventData HitData) { }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Deactivate() { }

    UFUNCTION(BlueprintPure)
    AHazePlayerCharacter GetPlayer() const
    {
        return Player;
    }

    UFUNCTION(BlueprintPure)
    AIceArrow GetIceArrow() const
    {
        return IceArrow;
    }

    UFUNCTION(BlueprintPure)
    float GetChargeFactor() const
    {
        return IceArrow.ChargeFactor;
    }
}

struct FIceArrowHitEventData
{
    FIceArrowHitEventData(AIceArrow IceArrow)
    {
        ChargeFraction = IceArrow.ChargeFactor;
        Component = IceArrow.HitData.Component;
        ImpactPoint = IceArrow.HitData.ImpactPoint;
        ImpactNormal = IceArrow.HitData.ImpactNormal;

		FHazeTraceSettings TraceSettings = IceArrow.GetTraceSettings();
		AudioTraceParams = FHazeAudioTraceQuery(IceArrow.HitData.Component, 
												IceArrow.HitData.ImpactPoint, 
												IceArrow.HitData.ImpactNormal, 
												TraceSettings.Shape, 
												TraceSettings.bTraceComplex);
    }

    FIceArrowHitEventData(ABlizzardArrow BlizzardArrow)
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
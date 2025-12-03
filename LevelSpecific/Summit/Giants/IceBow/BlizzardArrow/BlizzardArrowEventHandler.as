UCLASS(Abstract)
class UBlizzardArrowEventHandler : UHazeEffectEventHandler
{
    
	AHazePlayerCharacter Player = nullptr;
	ABlizzardArrow BlizzardArrow = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Game::GetPlayer(IceBow::Player);
		BlizzardArrow = Cast<ABlizzardArrow>(Owner);
	}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activate() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch(FBlizzardArrowLaunchEventData LaunchData) { }

    /**
     * Arrow hit a wind surface and attached to it
     */
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitValid(FBlizzardArrowHitEventData HitData) { }

    /**
     * Arrow did not attach to a valid surface, and must be destroyed
     */
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitInvalid(FBlizzardArrowHitEventData HitData) { }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Deactivate() { }

    UFUNCTION(BlueprintPure)
    AHazePlayerCharacter GetPlayer() const
    {
        return Player;
    }

    UFUNCTION(BlueprintPure)
    ABlizzardArrow GetBlizzardArrow() const
    {
        return BlizzardArrow;
    }
}

struct FBlizzardArrowHitEventData
{
    FBlizzardArrowHitEventData(ABlizzardArrow BlizzardArrow)
    {
        HitComponent = BlizzardArrow.HitData.Component;
        ImpactPoint = BlizzardArrow.HitData.ImpactPoint;
        ImpactNormal = BlizzardArrow.HitData.ImpactNormal;

		FHazeTraceSettings TraceSettings = BlizzardArrow.GetTraceSettings();
		AudioTraceParams = FHazeAudioTraceQuery(BlizzardArrow.HitData.Component, 
												BlizzardArrow.HitData.ImpactPoint, 
												BlizzardArrow.HitData.ImpactNormal, 
												TraceSettings.Shape, 
												TraceSettings.bTraceComplex);	
    }

	FBlizzardArrowHitEventData(FIceArrowHitEventData IceArrowHitEventData)
	{
		HitComponent = IceArrowHitEventData.Component;
        ImpactPoint = IceArrowHitEventData.ImpactPoint;
        ImpactNormal = IceArrowHitEventData.ImpactNormal;
		//PhysMat = IceArrowHitEventData.PhysMat;		
	}

    UPROPERTY()
	bool bHitValidSurface;

    UPROPERTY()
	UPrimitiveComponent HitComponent;

    UPROPERTY()
	FVector ImpactPoint;

    UPROPERTY()
	FVector ImpactNormal;

	// Used for audio
	UPROPERTY()
	FHazeAudioTraceQuery AudioTraceParams;
}
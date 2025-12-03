UCLASS()
class USpotLookAtSoundDef_Base : USoundDefBase
{
	UPROPERTY(VisibleAnywhere)
	USpotSoundComponent SpotComponent;

	UPROPERTY(VisibleAnywhere)
	ASpotSoundPlaneLookAtVolume LookAtVolume;

	// If we want to exclude any audio component we could list which components to update.
	// TArray<UHazeAudioComponents> ComponentsToUpdate;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LookAtVolume = Cast<ASpotSoundPlaneLookAtVolume>(HazeOwner.AttachParentActor);
		SpotComponent = USpotSoundComponent::Get(HazeOwner);

		if(LookAtVolume == nullptr)
		{
			devCheck(false, f"SpotLookAtSoundDef_Base: {GetName()} - Missing ASpotSoundPlaneLookAtVolume as owner ('{HazeOwner}')");
		}

		// Make sure they get a first valid position
		if (LookAtVolume != nullptr)
			SetMultiplePositions(LookAtVolume.LookAtPositions);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (LookAtVolume != nullptr)
			SetMultiplePositions(LookAtVolume.LookAtPositions);
	}

	void SetMultiplePositions(const TArray<FAkSoundPosition>& Positions)
	{
		for (auto AudioComponent : AudioComponents)
		{
			AudioComponent.SetMultipleSoundPositions(Positions);
		}
	}

	// Uses DefaultEmitter by default, supply specific one to use as target instead
	UFUNCTION(BlueprintPure)
	float GetZoneLinkValue(UHazeAudioEmitter Emitter = nullptr, bool bAutoSetRtpc = true)
	{
		if(SpotComponent != nullptr)
		{
			auto ZoneLinkEmitter = Emitter != nullptr ? Emitter : DefaultEmitter;
			return ZoneLinkEmitter.AudioComponent.GetZoneOcclusion(SpotComponent.bLinkedZoneFollowRelevance, LinkedZone = SpotComponent.LinkedZone, bAutoSetRtpc = bAutoSetRtpc);
		}

		return 0.0;
	}
	
	UFUNCTION(BlueprintPure)
	float GetDistanceToClosestListenerFocusPoint()
	{
		return LookAtVolume.DistanceToClosestPlayerFocusPoint;
	}
}
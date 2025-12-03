UCLASS(Abstract)
class USpot_Tracking_SoundDef : USoundDefBase
{

	UPROPERTY(VisibleAnywhere)
	USpotSoundComponent SpotComponent;

	UPROPERTY(VisibleAnywhere)
	USpotSoundSplineComponent SpotSpline;

	UPROPERTY(VisibleAnywhere)
	USpotSoundPlaneComponent SpotPlane;

	// If we want to exclude any audio component we could list which components to update.
	// TArray<UHazeAudioComponents> ComponentsToUpdate;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SpotComponent = USpotSoundComponent::Get(HazeOwner);

		if(SpotComponent != nullptr)
		{
			SpotSpline = Cast<USpotSoundSplineComponent>(SpotComponent.ModeComponent);
			SpotPlane = Cast<USpotSoundPlaneComponent>(SpotComponent.ModeComponent);

			if (SpotSpline != nullptr)
			{
				for (auto AudioComponent: AudioComponents)
				{
					AudioComponent.SetAttenuationPadding(SpotSpline.Radius + SpotSpline.DisableDistanceBuffer);
				}
			}
		}
		else
		{
			devCheck(false, f"Spot_Tracking_SoundDef: {GetName()} - Missing SpotSoundComponent in owner");
		}

		// Make sure they get a first valid position
		if (SpotSpline != nullptr)
			TrackSpline();

		if (SpotPlane != nullptr)
			TrackPlane();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (SpotSpline != nullptr)
			TrackSpline();

		if (SpotPlane != nullptr)
			TrackPlane();
	}

	void TrackSpline()
	{
		SpotSpline.UpdateComponentPositions();

		SetMultiplePositions(SpotSpline.Positions);
	}

	void TrackPlane()
	{
		SpotPlane.UpdateComponentPositions();

		SetMultiplePositions(SpotPlane.Positions);
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

	// ONLY WORKS IF IT HAS A "USpotSoundSplineComponent"!
	UFUNCTION(BlueprintPure)
	float GetSplineDistance()
	{
		if (SpotSpline != nullptr)
			return SpotSpline.GetSplineDistance();
		return 0;
	}
}
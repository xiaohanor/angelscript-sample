class USpotSoundSplineComponent : USpotSoundModeComponent
{
	default SpotMode = EHazeSpotSoundMode::Spline;

	UPROPERTY(EditInstanceOnly)
	TArray<UHazeAudioEvent> StartLoops;

	UPROPERTY(EditInstanceOnly)
	AkMultiPositionType PositioningType = AkMultiPositionType::MultiDirections;

	UPROPERTY(VisibleAnywhere)
	UHazeSplineComponent SplineComponent;

	UPROPERTY(EditAnywhere)
	TSoftObjectPtr<AActor> ExistingSplineActor;

	// // If 'LazyOverlapsEnabled' is used, the disable the actor cant enable until at least 1 player is inside the range
	// UPROPERTY(VisibleAnywhere)
	// UHazeLazyPlayerOverlapComponent EnableArea;

	UPROPERTY(EditAnywhere)
	int32 DisableDistanceBuffer = 3000;

	private TArray<UHazeAudioListenerComponentBase> Listeners;
	private TArray<FAkSoundPosition> SoundPositions;
	private UHazeAudioComponent AudioComponent;
	private UHazeSplineComponent SpotSpline;
	private float CurrentSplineDistance = 0;

	const TArray<FAkSoundPosition>& GetPositions() property
	{
		return SoundPositions;
	}

	float64 GetRadius() property
	{
		if (SpotSpline != nullptr)
			return SpotSpline.BoundsRadius;

		return 0;
	}

	float GetSplineDistance() property
	{
		return CurrentSplineDistance;
	}

	TSoftObjectPtr<AActor> GetActorDependency() override property
	{
		// We have this instead of linkedmeshowner since it wasn't a AActor or SoftObjectPtr from start.
		return ExistingSplineActor;
	}

#if EDITOR

	void OnModeRemoved(USpotSoundComponent Spot) override
	{
		// if (EnableArea != nullptr)
		// 	EnableArea.DestroyComponent(GetOwner());

		if (SplineComponent != nullptr)
			SplineComponent.DestroyComponent(Spot.GetOwner());
	}

	void OnModeAdded(USpotSoundComponent Spot) override
	{
		SplineComponent = Cast<UHazeSplineComponent>(
			Editor::AddInstanceComponentInEditor(Spot.GetOwner(), UHazeSplineComponent, n"SpotSpline")
			);
		SplineComponent.EditingSettings.SplineColor = FLinearColor(252/255., 159/255., 53/255.);
		SplineComponent.bRenderWhileNotSelected = false;
		SplineComponent.EditingSettings.bShowWhenSelected = true;
		// Rerun so it's properly displayed (calculates it's spline data)
		SplineComponent.UpdateSpline();
		GetOwner().RerunConstructionScripts();

		// // If 'LazyOverlapsEnabled' is used, the disable the actor cant enable until at least 1 player is inside the range
		// EnableArea = Cast<UHazeLazyPlayerOverlapComponent>(
		// 	Editor::AddInstanceComponentInEditor(GetOwner(), UHazeLazyPlayerOverlapComponent, n"SpotLazyOverlap")
		// 	);
		// EnableArea.SetLazyOverlapsEnabled(false);
		// // EnableArea.bAlwaysCheckLazyOverlaps = true;
	}

#endif

	void Start() override
	{
		if (!ExistingSplineActor.IsNull())
		{
			SpotSpline = Spline::GetGameplaySpline(ExistingSplineActor.Get(), this);
		}
		else
		{
			if (SplineComponent != nullptr)
				SpotSpline = SplineComponent;
			else
			{
				SpotSpline = Spline::GetGameplaySpline(GetOwner(), this);
			}
		}

		if (!devEnsure(SpotSpline != nullptr, f"{GetName()} doesn't have a valid spline component and will be disabled!"))
		{
			return;
		}

		if(ParentSpot.SoundDef.SoundDef != nullptr)
		{
			FSpawnSoundDefSpotSoundParams SpotParams;
			SpotParams.SpotParent = Cast<AHazeActor>(GetOwner());
			SpotParams.SoundDefRef = ParentSpot.SoundDef;

			if(ParentSpot.bLinkToZone)
			{
				SpotParams.LinkedOcclusionZone = ParentSpot.LinkedZone;
			}

			SpotParams.bLinkedZoneFollowRelevance = ParentSpot.bLinkToZone && ParentSpot.bLinkedZoneFollowRelevance;
			
			Audio::GetListeners(this, Listeners);
			SoundPositions.SetNum(Listeners.Num());
			UpdateComponentPositions();

			SoundDef::SpawnSoundDefSpot(SpotParams);
		}
		else
		{
			ParentSpot.GetAudioComponentAndEmitter(ParentSpot.Settings, false);

			auto ParentEmitter = ParentSpot.Emitter;
			ParentEmitter.GetListeners(Listeners);

			// Doesn't support scene attachment
			ParentSpot.SetupEmitter(ParentSpot.Settings, ParentEmitter, nullptr);

			AudioComponent = ParentEmitter.GetAudioComponent();
			AudioComponent.SetAttenuationPadding(SpotSpline.BoundsRadius + DisableDistanceBuffer);

			SoundPositions.SetNum(Listeners.Num());
			UpdateComponentPositions();

			if (StartLoops.Num() == 0 && ParentSpot.Event != nullptr)
			{
				ParentEmitter.PostEvent(ParentSpot.Event, PostType = EHazeAudioEventPostType::Ambience);
			}
			else
			{
				for (const auto LoopingEvent : StartLoops)
					ParentEmitter.PostEvent(LoopingEvent, PostType = EHazeAudioEventPostType::Ambience);
			}

			ParentSpot.SetComponentTickEnabled(true);
			ParentSpot.Emitter.OnEventStarted.AddUFunction(this, n"OnEventStarted");
		}

	}

	void Stop() override
	{
		ParentSpot.SetComponentTickEnabled(false);
		// Will use a fade out for the stopping of the event.
		ParentSpot.InternalStop();
	}

	void UpdateComponentPositions()
	{
		if (SpotSpline == nullptr)
			return;

		CurrentSplineDistance = 0;
		for (int i = 0; i < Listeners.Num(); i++)
		{
			auto SplinePosition = SpotSpline.GetClosestSplinePositionToWorldLocation(Listeners[i].GetWorldLocation(), true);
			CurrentSplineDistance = Math::Max(SplineDistance, SplinePosition.CurrentSplineDistance);
			FVector NewLocation = SplinePosition.GetWorldLocation();
			SoundPositions[i].SetPosition(NewLocation);
		}

		if (AudioComponent != nullptr)
			AudioComponent.SetMultipleSoundPositions(SoundPositions, PositioningType);
	}

	UFUNCTION(BlueprintCallable)
	void PostEvent(UHazeAudioEvent Event)
	{
		ParentSpot.Emitter.PostEvent(Event, PostType = EHazeAudioEventPostType::Ambience);
	}

	// Restart tracking position updates.
	UFUNCTION()
	void OnEventStarted(const FHazeAudioPostEventInstance&in Instance)
	{
		if (!ParentSpot.IsComponentTickEnabled())
		{
			ParentSpot.SetComponentTickEnabled(true);
		}
	}

	void TickMode(float DeltaSeconds) override
	{
		if (!ParentSpot.Emitter.IsPlaying())
		{
			ParentSpot.SetComponentTickEnabled(false);
			return;
		}

		UpdateComponentPositions();
	}
}
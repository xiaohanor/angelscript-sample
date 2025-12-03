class ABallistaHydraSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(BallistaHydraSplineSheet);

	access ReadOnly = private, * (readonly), UBallistaHydraSplineMoveCapability;
	access:ReadOnly TArray<ABallistaHydraSplinePlatform> Platforms;
	TArray<FInstigator> PauseProgressInstigators;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent PlayerInheritMovementComponent;
	default PlayerInheritMovementComponent.FollowType = EPlayerInheritMovementFollowType::FollowInheritComponent;
	default PlayerInheritMovementComponent.FollowBehavior = EMovementFollowComponentType::ReferenceFrame;
	default PlayerInheritMovementComponent.Shape.Type = EHazeShapeType::Sphere;
	default PlayerInheritMovementComponent.Shape.SphereRadius = 1000000000;
	default PlayerInheritMovementComponent.DisableTrigger(this);
	default PlayerInheritMovementComponent.FollowPriority = EInstigatePriority::Normal;


	// UPROPERTY(DefaultComponent)
	// UInheritVelocityComponent InheritVelocityComp;

	UPROPERTY(DefaultComponent)
	access:ReadOnly UHazeTwoWaySyncedFloatComponent SyncedCurrentSplineDistance;
	access:ReadOnly float LocalSplineDistance = 0.0;
	access:ReadOnly float PlatformsFloatDistance = 0.0;
	access:ReadOnly float PlatformsSinkDistance = 0.0;

	access:ReadOnly float Ballista1Dist = 0.0;
	access:ReadOnly float Ballista2Dist = 0.0;
	access:ReadOnly float Ballista3Dist = 0.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(Transient)
	TArray<USanctuaryBallistaHydraSplineEventComponent> EventComponents;

	private uint LastRefreshFrame = 0;
	bool bUseDevProgressSetup = false;

#if EDITOR
	default Spline.EditingSettings.SplineColor = ColorDebug::Cyan;

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Spline.UpdateSpline();
		RefreshAll();
		Spline.EditingSettings.VisualizeScale = 1;
	}
#endif

	UFUNCTION(NotBlueprintCallable)
	void SetSplineDistanceFromProgressPoint(float SplineDist)
	{
		LocalSplineDistance = SplineDist;
		SyncedCurrentSplineDistance.SetValue(LocalSplineDistance);	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SanctuaryBallistaHydraDevToggles::SanctuaryBallistaHydraCategory.MakeVisible();
		RefreshAll();
	}

	UFUNCTION(CallInEditor)
	void RefreshAll()
	{
		if(LastRefreshFrame == Time::FrameNumber)
			return;
		RefreshEventComponents();
		LastRefreshFrame = Time::FrameNumber;
	}

	UFUNCTION(CallInEditor)
	void RefreshEventComponents()
	{
		if (LastRefreshFrame == Time::FrameNumber)
			return;

		EventComponents.Reset();
		GetComponentsByClass(EventComponents);

		for (USanctuaryBallistaHydraSplineEventComponent EventComp : EventComponents)
		{
			EventComp.DistanceAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(EventComp.WorldLocation);
			if (EventComp.EventType == ESanctuaryBallistaHydraSplineEventType::PlatformsFullySurfaced)
				PlatformsFloatDistance = EventComp.DistanceAlongSpline;
			if (EventComp.EventType == ESanctuaryBallistaHydraSplineEventType::PlatformsStartSink)
				PlatformsSinkDistance = EventComp.DistanceAlongSpline;
		}

		EventComponents.Sort();
	}

// YW shamelessly stolen from AJetskiSpline, thanks findity
// @return False if only one or no components are valid
	bool GetSplineEventComponents(float DistanceAlongSpline, USanctuaryBallistaHydraSplineEventComponent&out Previous, USanctuaryBallistaHydraSplineEventComponent&out Next, float&out Alpha) const
	{
		if(EventComponents.Num() == 0)
		{
			Previous = nullptr;
			Next = nullptr;
			Alpha = 0;
			return false;
		}

		if(EventComponents.Num() == 1)
		{
			Previous = nullptr;
			Next = EventComponents[0];
			Alpha = 1;
			return false;
		}

		if(DistanceAlongSpline < KINDA_SMALL_NUMBER || DistanceAlongSpline < EventComponents[0].DistanceAlongSpline)
		{
			// Before the spline or the first look component
			Previous = EventComponents[0];
			Next = EventComponents[1];
			Alpha = 0;
			return true;
		}

		if(DistanceAlongSpline > Spline.SplineLength - KINDA_SMALL_NUMBER || DistanceAlongSpline > EventComponents[EventComponents.Num() - 1].DistanceAlongSpline)
		{
			// After the spline or the last look component
			Previous = EventComponents[EventComponents.Num() - 2];
			Next = EventComponents[EventComponents.Num() - 1];
			Alpha = 1;
			return true;
		}

		// FB TODO: Faster search?
		for(int i = 1; i < EventComponents.Num(); i++)
		{
			USanctuaryBallistaHydraSplineEventComponent PreviousComp = EventComponents[i - 1];
			if(PreviousComp.DistanceAlongSpline > DistanceAlongSpline)
				continue;

			USanctuaryBallistaHydraSplineEventComponent NextComp = EventComponents[i];
			if(NextComp.DistanceAlongSpline < DistanceAlongSpline)
				continue;
			
			Previous = PreviousComp;
			Next = NextComp;

			Alpha = Math::NormalizeToRange(DistanceAlongSpline, PreviousComp.DistanceAlongSpline, NextComp.DistanceAlongSpline);
			return true;
		}

		check(false);
		return false;
	}


};
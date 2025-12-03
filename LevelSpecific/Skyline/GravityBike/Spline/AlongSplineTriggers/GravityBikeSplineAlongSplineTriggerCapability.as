class UGravityBikeSplineAlongSplineTriggerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSpline GravityBike;
	AGravityBikeSplineActor Spline;
	float DistanceAlongSpline = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!GravityBike.HasControl())
			return false;

		if(GravityBike.GetActiveSplineActor() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GravityBike.HasControl())
			return true;

		if(GravityBike.GetActiveSplineActor() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		OnSplineChanged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Spline != GravityBike.GetActiveSplineActor())
		{
			OnSplineChanged();
		}
		else
		{
			float NewDistanceAlongSpline = Spline.SplineComp.GetClosestSplineDistanceToWorldLocation(GravityBike.ActorLocation);

			ActivateTriggersInRange(FHazeRange(DistanceAlongSpline, NewDistanceAlongSpline), false);

			DistanceAlongSpline = NewDistanceAlongSpline;
		}
	}

	void OnSplineChanged()
	{
		Spline = GravityBike.GetActiveSplineActor();
		DistanceAlongSpline = Spline.SplineComp.GetClosestSplineDistanceToWorldLocation(GravityBike.ActorLocation);

		// Activate every trigger up until us
		ActivateTriggersInRange(FHazeRange(0, DistanceAlongSpline), true);
	}

	void ActivateTriggersInRange(FHazeRange Range, bool bOnSplineChanged)
	{
		TArray<FAlongSplineComponentData> PassedTriggers;
		if(!Spline.SplineComp.FindComponentsInRangeAlongSpline(UGravityBikeSplineAlongSplineTriggerComponent, true, Range, PassedTriggers))
			return;
		
		TArray<UGravityBikeSplineAlongSplineTriggerComponent> TriggersToActivate;
		TriggersToActivate.Reserve(PassedTriggers.Num());

		for(auto Trigger : PassedTriggers)
		{
			auto TriggerComp = Cast<UGravityBikeSplineAlongSplineTriggerComponent>(Trigger.Component);
			if(TriggerComp == nullptr)
				continue;

			if(TriggerComp.bActivated)
				continue;

			if(bOnSplineChanged)
			{
				// Triggers can choose to only activate when passed
				if(!TriggerComp.bActivateOnSplineChangedEvenWhenPassed)
					continue;
			}

			TriggersToActivate.Add(TriggerComp);
		}

		CrumbActivate(TriggersToActivate);
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivate(TArray<UGravityBikeSplineAlongSplineTriggerComponent> TriggersToActivate)
	{
		for(auto TriggerToActivate : TriggersToActivate)
		{
			if(!IsValid(TriggerToActivate))
				continue;
			
			TriggerToActivate.ActivateTrigger();
		}
	}
};
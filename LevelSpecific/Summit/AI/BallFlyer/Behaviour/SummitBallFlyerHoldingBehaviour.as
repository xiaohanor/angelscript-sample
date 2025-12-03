class USummitBallFlyerHoldingBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitBallFlyerSettings Settings;
	float ChangeDestinationTime;
	FVector Destination;
	FVector InitialLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitBallFlyerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ChangeDestinationTime = 0.0;
		InitialLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Drift around near initial position
		if ((Time::GameTimeSeconds > ChangeDestinationTime) || 
			Owner.ActorLocation.IsWithinDist(Destination, Settings.HoldingSpeed * 0.5))
		{
			Destination = InitialLocation + Math::GetRandomPointOnSphere() * Settings.HoldingRadius;
			ChangeDestinationTime = Time::GameTimeSeconds + 3.0;
		}
		DestinationComp.MoveTowards(Destination, Settings.HoldingSpeed);	
		if (TargetComp.HasValidTarget() && TargetComp.Target.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.ChaseRange))
			DestinationComp.RotateTowards(TargetComp.Target);

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Green, 10);
		}
#endif
	}
}

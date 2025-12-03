class USummitCritterSwarmHoldingBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCritterSwarmSettings SwarmSettings;
	USummitCritterSwarmComponent SwarmComp;
	float ChangeDestinationTime;
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SwarmSettings = USummitCritterSwarmSettings::GetSettings(Owner);
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Drift around near initial position
		if ((Time::GameTimeSeconds > ChangeDestinationTime) || 
			Owner.ActorLocation.IsWithinDist(Destination, SwarmSettings.HoldingSpeed * 0.5))
		{
			Destination = SwarmComp.InitialLocation + Math::GetRandomPointOnSphere() * SwarmSettings.HoldingRadius;
			ChangeDestinationTime = Time::GameTimeSeconds + 3.0;
		}
		DestinationComp.MoveTowards(Destination, SwarmSettings.HoldingSpeed);	

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Green, 10);
		}
#endif
	}
}

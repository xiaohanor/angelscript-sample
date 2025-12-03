class UEnforcerJetpackTraverseMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"Jetpack");	
	default CapabilityTags.Add(n"TraversalMovement");	

	UArcTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings; 
	
	FTraversalArc TraversalArc;
	float TraversedDistance = 0.0;
	float TraversalArcLength = 0.0;
	FVector ArcLocation;
	FHazeAcceleratedFloat SpeedAlongArc;
	UTeleportingMovementData TeleportingMovement;
	UEnforcerJetpackComponent JetpackComp;
	UHazeCrumbSyncedFloatComponent AlphaSyncedComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UArcTraversalComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		TeleportingMovement = Cast<UTeleportingMovementData>(Movement);
		JetpackComp = UEnforcerJetpackComponent::Get(Owner);
		AlphaSyncedComp = UHazeCrumbSyncedFloatComponent::Get(Owner, n"JetpackTraversalAlphaSyncedComp");
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupTeleportingMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(TeleportingMovement);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TraversalComp.HasDestination())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TraversalComp.HasDestination())
			return true; 
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.BlockCapabilitiesExcluding(CapabilityTags::Movement, n"TraversalMovement", this);
		TraversalArc = FTraversalArc();
		JetpackComp.AnimArcAlpha = 0.0;
		AlphaSyncedComp.Value = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateTraversal();

		Super::TickActive(DeltaTime);

		if (TraversedDistance >= TraversalArcLength)
		 	TraversalComp.ReachDestination(TraversalArc.LandLocation);

		if (HasControl())
			AlphaSyncedComp.Value = JetpackComp.AnimArcAlpha;
		else
			JetpackComp.AnimArcAlpha = AlphaSyncedComp.Value;
	}

	void UpdateTraversal()
	{
		if (!HasControl())
			return; // No need to set up update, this is only used on control side

		FTraversalArc PrevArc = TraversalArc;

		// Consume traversing point
		TraversalComp.ConsumeDestination(TraversalArc);
		if (PrevArc != TraversalArc)
		{
			// Start new traversal
			TraversedDistance = 0.0;
			TraversalArcLength = TraversalArc.GetLength();
			ArcLocation = TraversalArc.GetLocation(0.0);
			SpeedAlongArc.SnapTo(TraversalArc.LaunchTangent.GetSafeNormal().DotProduct(MoveComp.Velocity));
		}
	}

	void ComposeMovement(float DeltaTime) override
	{	
		if (TraversalArcLength == 0.0)
			return;

		float TargetSpeed = TraversalComp.Speed;
		if (ActiveDuration < TraversalSettings.LaunchDuration)
			TargetSpeed *= Math::EaseInOut(0.0, 1.0, ActiveDuration / TraversalSettings.LaunchDuration, 4.0); 
		float LandThreshold = Math::Max(TraversalArcLength * 0.75, TraversalArcLength - TraversalComp.Speed * 0.25);	
		if (TraversedDistance > LandThreshold)
			TargetSpeed *= Math::EaseInOut(1.0, 0.1, (TraversedDistance - LandThreshold) / (TraversalArcLength - LandThreshold), 2.0); 
		SpeedAlongArc.AccelerateTo(TargetSpeed, 1.0, DeltaTime);
		float TraverseDelta = SpeedAlongArc.Value * DeltaTime;

		TraversedDistance += TraverseDelta;
		float ArcFraction = TraversedDistance / TraversalArcLength;
		FVector NewArcLocation = TraversalArc.GetLocation(ArcFraction);
		FVector DeltaAlongArc = NewArcLocation - ArcLocation;
		
		FVector Delta = DeltaAlongArc; 

		Movement.AddDelta(Delta);

		// Turn towards focus or in direction of arc
		if (DestinationComp.Focus.IsValid())
		 	MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, TraversalSettings.TurnDuration, DeltaTime, Movement);
		else 
		{
			FQuat Rot = FQuat::Slerp(TraversalArc.LaunchTangent.ToOrientationQuat(), TraversalArc.LandTangent.ToOrientationQuat(), ArcFraction);
			MoveComp.RotateTowardsDirection(Rot.Vector(), TraversalSettings.TurnDuration, DeltaTime, Movement);
		}

		Movement.AddPendingImpulses();

		ArcLocation = NewArcLocation;

		JetpackComp.AnimArcAlpha = ArcFraction;
	}
}

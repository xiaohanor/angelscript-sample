class UCoastWaterJetChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastWaterJetSettings Settings;
	float FlyOverTime;
	UBasicAICharacterMovementComponent MoveComp;
	UCoastWaterJetComponent WaterJetComp;
	float HoldingDuration;
	float HoldingSideOffset;
	float ExtraSideOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastWaterJetSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		WaterJetComp = UCoastWaterJetComponent::Get(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
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
		HoldingDuration = 0.0;
		ExtraSideOffset = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorCenterLocation;

		FVector Destination;
		float HeightThreshold = 1000.0 + Math::Min(WaterJetComp.RailPosition.WorldLocation.Z, TargetComp.Target.ActorLocation.Z + Settings.EngageOffset.Z);

		if (IsObstructed())
			FlyOverTime = Time::GameTimeSeconds + 0.2;

		if (Time::GameTimeSeconds < FlyOverTime)
		{
			Destination = OwnLoc + FVector(0.0, 0.0, 1000.0);

			// Reduce flyover duration when we get too high
			if (OwnLoc.Z > HeightThreshold)
				FlyOverTime -= DeltaTime;
		}
		else
		{
			// Chase to a flanking position
			FTransform TargetTransform = TargetComp.Target.ActorTransform;
			FVector RelativeLoc = TargetTransform.InverseTransformPosition(OwnLoc);
			RelativeLoc.X = Settings.EngageOffset.X;
			RelativeLoc.Y = Math::Sign(RelativeLoc.Y) * (Settings.EngageOffset.Y + ExtraSideOffset);
			RelativeLoc.Z = Settings.EngageOffset.Z;
			Destination = TargetTransform.TransformPosition(RelativeLoc);

			// Don't climb too high (even if target has been flung up)
			if (Destination.Z > HeightThreshold)
				Destination.Z = HeightThreshold;
			
			// Brake if plummeting down
			if (Owner.ActorVelocity.Z < Math::Min(0.0, (Destination.Z - OwnLoc.Z)))
				Destination.Z = OwnLoc.Z + 1000.0;
		}

		// Slower acc when moving backwards along rail
		float SpeedFactor = Math::Min(1.0, 1.2 + WaterJetComp.RailPosition.WorldForwardVector.DotProduct((Destination - Owner.ActorLocation).GetSafeNormal2D()));
		DestinationComp.MoveTowards(Destination, Settings.EngageSpeed * SpeedFactor);
		DestinationComp.RotateTowards(TargetComp.Target);

		// If we remain static along rail for a while we add an extra sideways offset to spice up movement a bit
		float SideOffset = TargetComp.Target.ActorRightVector.DotProduct(OwnLoc - TargetComp.Target.ActorLocation);
		if (Math::Abs(HoldingSideOffset - SideOffset) < Settings.EngageHoldingThreshold)
		{
			HoldingDuration += DeltaTime;
			if (HoldingDuration > Settings.EngageHoldingMaxDuration)
			{
				ExtraSideOffset = Math::RandRange(-1.0, 1.0) * Settings.EngageHoldingExtraOffset;
				HoldingDuration = 0.0;
			}
		}
		else
		{
			HoldingDuration = 0.0;
			HoldingSideOffset = SideOffset;
		}

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Destination, 100, 4, FLinearColor::Red, 10);
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Red, 10);
		}
#endif
	}

	bool IsObstructed()
	{
		if (MoveComp.HasAnyValidBlockingContacts())
			return true;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::EnemyCharacter);		
		Trace.UseLine();
		Trace.IgnoreActor(Owner);
		FVector ProbeDir = (Owner.ActorVelocity.IsNearlyZero(1.0)) ? WaterJetComp.RailPosition.WorldForwardVector : Owner.ActorVelocity.GetSafeNormal2D();
		FHitResult Obstruction = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + ProbeDir * 1000.0);
		if (Obstruction.bBlockingHit)
			return true;
		return false;
	}
}

class UIslandPunchotronGroundMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"GroundMovement");	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UPathfollowingMoveToComponent PathFollowingComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UIslandPunchotronElevatorFallComponent ElevatorFallComp;

	USteppingMovementData Movement;
	//USimpleMovementData Movement;

  	FVector CustomVelocity;
	FVector PrevLocation;
	FRotator PrevRot;

	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;
	UGroundPathfollowingSettings GroundPathfollowingSettings;

	AAIIslandPunchotron Punchotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		PathFollowingComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner, n"SyncedPosition"); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		ElevatorFallComp = UIslandPunchotronElevatorFallComponent::GetOrCreate(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		GroundPathfollowingSettings = UGroundPathfollowingSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSteppingMovementData();		
		//Movement = MoveComp.SetupSimpleMovementData();		
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		return false;		
	}
 

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		UPathfollowingSettings::SetAtWaypointRange(Owner, 100, this, EHazeSettingsPriority::Gameplay);		
		UPathfollowingSettings::SetAtDestinationRange(Owner, 120, this, EHazeSettingsPriority::Gameplay);
		UMovementGravitySettings::SetGravityScale(Owner, 5, this, EHazeSettingsPriority::Defaults);		
		//UIslandPunchotronEffectHandler::Trigger_OnSmallJetsStart(Owner, FIslandPunchotronJetsParams(Punchotron.LeftJetLocation, Punchotron.RightJetLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearSettingsByInstigator(this);
		UIslandPunchotronEffectHandler::Trigger_OnSmallJetsStop(Owner);
	}

	bool bWasLeftJetOn = false;
	bool bWasRightJetOn = false;
 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		// Handle turn sparks
		if (DeltaTime > 0.0)
		{
			FRotator CurRot = Owner.ActorRotation;
			float TurnRate = FRotator::NormalizeAxis(CurRot.Yaw - PrevRot.Yaw) / DeltaTime;
			const float TurnRateTreshold = 30;
			const float ForwardVelocityTreshold = 300;
			if (Owner.ActorForwardVector.DotProduct(Owner.ActorHorizontalVelocity) > ForwardVelocityTreshold)
			{
				if (TurnRate < -TurnRateTreshold && !bWasRightJetOn)
				{
					if (bWasLeftJetOn)
						UIslandPunchotronEffectHandler::Trigger_OnSmallJetsStop(Owner);
					UIslandPunchotronEffectHandler::Trigger_OnSmallJetSingleStart(Owner, FIslandPunchotronSingleJetParams(Punchotron.RightJetLocation));
					bWasLeftJetOn = false;
					bWasRightJetOn = true;
				}
				else if (TurnRate > TurnRateTreshold && !bWasLeftJetOn)
				{
					if (bWasRightJetOn)
						UIslandPunchotronEffectHandler::Trigger_OnSmallJetsStop(Owner);
					UIslandPunchotronEffectHandler::Trigger_OnSmallJetSingleStart(Owner, FIslandPunchotronSingleJetParams(Punchotron.LeftJetLocation));
					bWasLeftJetOn = true;
					bWasRightJetOn = false;
				}
			}
			
			if (Math::Abs(TurnRate) < TurnRateTreshold)
			{
				UIslandPunchotronEffectHandler::Trigger_OnSmallJetsStop(Owner);
				bWasLeftJetOn = false;
				bWasRightJetOn = false;
			}

			PrevRot = CurRot;
		}

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
#endif
		FVector MoveDir = Owner.ActorForwardVector;	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity - CustomVelocity;
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;
		FVector Destination = GetCurrentDestination();

		float Friction = Settings.GroundFriction;
		float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);

#if !RELEASE
		TemporalLog.Value("Friction", Friction);
		TemporalLog.Sphere("Initial;OwnLoc", OwnLoc, 50, FLinearColor::LucBlue);
		TemporalLog.DirectionalArrow("Initial;Velocity", OwnLoc, Velocity);
		TemporalLog.Sphere("Initial;Destination", Destination, 50, FLinearColor::Green);
		TemporalLog.DirectionalArrow("Initial;HorizontalVelocity", OwnLoc, HorizontalVelocity);
		TemporalLog.DirectionalArrow("Initial;VerticalVelocity", OwnLoc, VerticalVelocity);
		TemporalLog.Value("Initial;HorizontalSpeed", HorizontalVelocity.Size());
		TemporalLog.Value("Initial;VerticalSpeed", VerticalVelocity.Size());
		TemporalLog.DirectionalArrow("Initial;MoveDir", OwnLoc, MoveDir);
		TemporalLog.Value("Initial;HasDestination", DestinationComp.HasDestination());
#endif

		if (DestinationComp.HasDestination())
		{
			MoveDir = (Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal2D();
			if (IsMovingToFinalDestination() && OwnLoc.IsWithinDist2D(Destination, PathingSettings.AtDestinationRange))
			{
								
				// Keep applying slowed down velocity until we're moving away from destination
				if (MoveDir.DotProduct(HorizontalVelocity) > 0.0)
				{
					HorizontalVelocity *= FrictionFactor;
					if (HorizontalVelocity.DotProduct(Owner.ActorForwardVector) < 0)
				 		HorizontalVelocity += Owner.ActorForwardVector * 2 * HorizontalVelocity.Size2D() * DeltaTime;
					HorizontalVelocity = HorizontalVelocity.Size2D() > Settings.CobraStrikeAttackMoveSpeed ? HorizontalVelocity.GetSafeNormal2D() * Settings.CobraStrikeAttackMoveSpeed : HorizontalVelocity;
					Movement.AddHorizontalVelocity(HorizontalVelocity);
#if !RELEASE
					TemporalLog.Status("HasDestination;SlowingDown", FLinearColor::Yellow);
					TemporalLog.DirectionalArrow("HasDestination;IsMovingToFinalDestination;MoveDir", Owner.ActorLocation, MoveDir);
#endif
				}
				else
				{
					// MoveTo is completed (note that this will usually mean this capability will deactivate)
					PathFollowingComp.ReportComplete(true);
					MoveDir = Owner.ActorForwardVector;
#if !RELEASE
					TemporalLog.Status("HasDestination;Stopping", FLinearColor::Red);
					TemporalLog.DirectionalArrow("HasDestination;IsMovingToFinalDestination;MoveDir", Owner.ActorLocation, MoveDir);
#endif
				}
			}
			else
			{
				HorizontalVelocity += MoveDir * DestinationComp.Speed * DeltaTime;
				HorizontalVelocity *= FrictionFactor;
				if (HorizontalVelocity.DotProduct(Owner.ActorForwardVector) < 0)
				 	HorizontalVelocity += Owner.ActorForwardVector * 2 * HorizontalVelocity.Size2D() * DeltaTime;
				HorizontalVelocity = HorizontalVelocity.Size2D() > Settings.CobraStrikeAttackMoveSpeed ? HorizontalVelocity.GetSafeNormal2D() * Settings.CobraStrikeAttackMoveSpeed : HorizontalVelocity;
				Movement.AddHorizontalVelocity(HorizontalVelocity);
#if !RELEASE
				TemporalLog.Status("HasDestination;FullSpeedAhead", FLinearColor::Green);
				TemporalLog.DirectionalArrow("HasDestination;MoveDir", Owner.ActorLocation, MoveDir);
				TemporalLog.DirectionalArrow("HasDestination;Horizontal Velocity", Owner.ActorLocation, HorizontalVelocity);
#endif
			}

		}
		else
		{
			// No destination, slow to a stop
			DestinationComp.ReportStopping();
			HorizontalVelocity *= FrictionFactor;
			Movement.AddHorizontalVelocity(HorizontalVelocity);			
#if !RELEASE
			TemporalLog.Status("No Destination;Slow to a stop", FLinearColor::DPink);			
#endif
		}

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= FrictionFactor;
		Movement.AddVelocity(CustomVelocity);

		float TurnDuration = Settings.TurnDuration;
		TurnDuration = Math::GetMappedRangeValueClamped(FVector2D(0, 1000),FVector2D(Settings.TurnDuration * 1.25, Settings.TurnDuration), TurnDuration);
		
		
		if (Owner.IsAnyCapabilityActive(n"FallThroughHole"))
		{
			// Tip over towards target rotation
			MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
			TurnDuration = Settings.TurnDuration * 0.5;
			MoveComp.AccRotation.Value = Owner.ActorRotation;
			MoveComp.AccRotation.AccelerateTo(ElevatorFallComp.FallTargetRotation, TurnDuration, DeltaTime);
			Movement.SetRotation(MoveComp.AccRotation.Value);
		}
		else
		{
			MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
			if (DestinationComp.Focus.IsValid())
				MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, TurnDuration, DeltaTime, Movement);
			else 
				MoveComp.RotateTowardsDirection(MoveDir, TurnDuration, DeltaTime, Movement);
		}

		Movement.AddPendingImpulses();
		float VerticalFrictionFactor = Math::Pow(Math::Exp(-Settings.AirFriction), DeltaTime);		
		VerticalVelocity *= VerticalFrictionFactor;
		Movement.AddVelocity(VerticalVelocity);
		Movement.AddGravityAcceleration();
	}

	FVector GetCurrentDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return DestinationComp.Destination;

		return PathFollowingComp.GetPathfindingDestination();	
	}

	bool IsMovingToFinalDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return true;

		return PathFollowingComp.IsMovingToFinalDestination();
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.DirectionalArrow("ForwardVector", Owner.ActorLocation, Owner.ActorForwardVector * 100);
	}

}
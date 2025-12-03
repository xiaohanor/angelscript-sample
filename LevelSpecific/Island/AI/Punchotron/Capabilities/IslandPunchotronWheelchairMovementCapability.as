class UIslandPunchotronWheelchairMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UPathfollowingMoveToComponent PathFollowingComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UIslandPunchotronAttackComponent AttackComp;

	USimpleMovementData Movement;

  	FVector CustomVelocity;
	FVector PrevLocation;

	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;

	AAIIslandPunchotron Punchotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		PathFollowingComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
		AttackComp = UIslandPunchotronAttackComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (AttackComp.AttackState != EIslandPunchotronAttackState::WheelchairKickAttack)
			return false;
		if (!AttackComp.bIsAttacking)
			return false;
		if (AttackComp.bIsInterruptAttack)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (AttackComp.AttackState != EIslandPunchotronAttackState::WheelchairKickAttack)
			return true;
		if (!AttackComp.bIsAttacking)
			return true;
		return false;		
	}
 

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		UPathfollowingSettings::SetAtWaypointRange(Owner, 80, this, EHazeSettingsPriority::Gameplay);		
		UPathfollowingSettings::SetAtDestinationRange(Owner, 120, this, EHazeSettingsPriority::Gameplay);
		UIslandPunchotronEffectHandler::Trigger_OnSmallJetsStart(Owner, FIslandPunchotronJetsParams(Punchotron.LeftJetLocation, Punchotron.RightJetLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearSettingsByInstigator(this);
		UIslandPunchotronEffectHandler::Trigger_OnSmallJetsStop(Owner);
	}

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

		// TODO: use different friction for different attack moves.
		float Friction = MoveComp.IsInAir() ? Settings.AirFriction : Settings.GroundFriction;
		float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);
#if !RELEASE
		TemporalLog.Value("Friction", Friction);
#endif

		FVector Destination = GetCurrentDestination();
		if (DestinationComp.HasDestination())
		{
			FVector DesiredMoveDir = (Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			MoveDir = MoveDir.SlerpTowards(DesiredMoveDir, DeltaTime * 20.0);
			if (IsMovingToFinalDestination() && OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			{
								
				// Keep applying slowed down velocity until we're moving away from destination
				if (MoveDir.DotProduct(HorizontalVelocity) > 0.0)
				{
					HorizontalVelocity *= FrictionFactor;
					Movement.AddVelocity(HorizontalVelocity);
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
				Movement.AddVelocity(HorizontalVelocity);
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
			Movement.AddVelocity(HorizontalVelocity);
#if !RELEASE
			TemporalLog.Status("No Destination;Slow to a stop", FLinearColor::DPink);			
#endif
		}

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= FrictionFactor;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of spline
		float TurnDuration = 0.75;
		MoveComp.RotateTowardsDirection(HorizontalVelocity, TurnDuration, DeltaTime, Movement);

		Movement.AddPendingImpulses();
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

}
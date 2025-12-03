class USanctuaryLightBirdCompanionFollowCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"FlyingMovement");	
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 150; // This is a fallback behaviour
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryLightBirdCompanionComponent CompanionComp;
	UPlayerMovementComponent PlayerMoveComp;
	USanctuaryLightBirdCompanionSettings Settings;
	USimpleMovementData Movement;

	FHazeAcceleratedVector FollowOffset;
	FVector FollowTarget;
	float RepositionCountdown;
	UTargetTrailComponent PlayerTrailComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner, n"SyncedPosition"); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner);
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();

		UTargetTrailComponent::GetOrCreate(Game::Zoe);
		UTargetTrailComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (CompanionComp.State != ELightBirdCompanionState::Follow)
			return false;
		if (CompanionComp.Player.IsPlayerDead())
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (CompanionComp.State != ELightBirdCompanionState::Follow)
			return true;
		if (CompanionComp.Player.IsPlayerDead())
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = ELightBirdCompanionState::Follow;
		
		PlayerTrailComp = UTargetTrailComponent::Get(CompanionComp.Player);
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);

		// We must detach before commencing move
		CompanionComp.Detach();

		FollowTarget = GetRandomVector(Settings.FollowOffsetMin, Settings.FollowOffsetMax);
		FollowTarget.Z = Math::Lerp(FollowTarget.Z, Settings.FollowOffsetMax.Z, Math::Max(1.0 - Math::Abs(FollowTarget.Y) * 0.01, 0.0));
		FollowOffset.SnapTo(FollowTarget);
		RepositionCountdown = Math::RandRange(0.5, 1.0) * Settings.FollowRepositionInterval;

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::Follow, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
			ComposeMovement(DeltaTime);
		else
			Movement.ApplyCrumbSyncedAirMovement();

		MoveComp.ApplyMove(Movement);

		if ((CompanionComp.UserComp.PreviousState == ELightBirdState::Lantern) && 
			(Time::GetGameTimeSince(CompanionComp.UserComp.StateTimestamp) < 0.5))
			AnimComp.RequestFeature(LightBirdCompanionAnimTags::LanternExit, EBasicBehaviourPriority::Medium, this);
		else 
			AnimComp.RequestFeature(LightBirdCompanionAnimTags::Follow, EBasicBehaviourPriority::Medium, this);
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (DeltaTime < SMALL_NUMBER)
			return;

		AHazePlayerCharacter Player = CompanionComp.Player;	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = UpdateDestination(DeltaTime);
		bool bIsAtDestination = OwnLoc.IsWithinDist(Destination, Settings.FollowAtDestinationRange);
		
		FVector Velocity = MoveComp.Velocity;
		FVector Impulse = CompanionComp.ConsumeFollowImpulse();
		Velocity += Impulse;
		bool bCanStrafe = Velocity.IsNearlyZero(Settings.MaxStrafeSpeed) && OwnLoc.IsWithinDist(Destination, Settings.MaxStrafeDistance); 

		FVector FocusDir = (Player.FocusLocation + Player.ActorForwardVector * 5000.0 - OwnLoc).GetSafeNormal();
		FVector ToDest = (Destination - OwnLoc);
		float DestDist = ToDest.Size();
		FVector DestDir = ToDest / DestDist;

		float NearRange = Settings.FollowNearRange * Math::Clamp(ActiveDuration, 0.25, 1.0);
		bool bIsNear = OwnLoc.IsWithinDist(Destination, NearRange) && SceneView::IsInView(CompanionComp.Player, Owner.ActorLocation);
		if (bIsNear)
		{
			// Near, precision movement
			FVector PlayerVelocity = PlayerTrailComp.GetAverageVelocity(0.5);
			if (!bIsAtDestination)
			{
				FVector2D AccInputRange = FVector2D(Settings.FollowAtDestinationRange, Settings.FollowNearRange * 0.25);
				float Acceleration = Math::GetMappedRangeValueClamped(AccInputRange, FVector2D(0.25, 1.0), DestDist) * Settings.FollowNearSpeed;
				if (bCanStrafe)
					Acceleration *= 0.5;
				Velocity += DestDir * Acceleration * DeltaTime;
			}

			// Apply friction
			float Friction = Settings.AirFriction;

			// Additional braking friction when moving quickly relative to player and getting close
			FVector RelativeVelocity = Velocity - PlayerVelocity;
			if (!RelativeVelocity.IsNearlyZero(Settings.FollowNearSpeed) && (Velocity.DotProduct(ToDest) > 0.0))
			{
				float Braking = (RelativeVelocity.Size() - Settings.FollowNearSpeed) * 2.0 / DestDist;
				Friction += Braking;
			}

			float IntegratedFriction = Math::Exp(-Friction);
			Velocity *= Math::Pow(IntegratedFriction, DeltaTime);

			Movement.AddVelocity(Velocity);

			// Only reposition when near destination
			RepositionCountdown -= DeltaTime;
		}
		else 
		{
			FVector Forward = Owner.ActorForwardVector;

			FVector2D AccInputRange = FVector2D(Settings.FollowNearRange, Settings.FollowNearRange * 2.0);
			FVector2D AccOutputRange = FVector2D(Settings.FollowNearSpeed, Settings.FollowFarSpeed);
			float Acceleration = Math::GetMappedRangeValueClamped(AccInputRange, AccOutputRange, DestDist);

			float FwdFraction = Math::Clamp(1.0 - Forward.DotProduct(DestDir), 0.0, 1.0) * 0.5;
			FVector AccDir = Forward * FwdFraction + DestDir * (1.0 - FwdFraction);
			if (AccDir.IsNearlyZero()) // We're facing straight away from destination
				AccDir = Forward * FwdFraction + Owner.ActorRightVector * (1.0 - FwdFraction);

			float AccDot = AccDir.DotProduct(DestDir);
			Acceleration *= Math::GetMappedRangeValueClamped(FVector2D(-1.0, 0.8), FVector2D(0.2, 1.0), AccDot);

			Velocity += AccDir * Acceleration * DeltaTime;
			float IntegratedFriction = Math::Exp(-Settings.FollowFarFriction);
			Velocity *= Math::Pow(IntegratedFriction, DeltaTime);

			Movement.AddVelocity(Velocity);
		}

		if (Time::GetGameTimeSince(CompanionComp.LaunchObstructionTime) < Settings.FollowLookaAtLaunchObstacleDuration)
			MoveComp.RotateTowardsDirection(CompanionComp.LaunchObstructionLoc - Owner.ActorLocation, Settings.TurnDuration, DeltaTime, Movement); // We've been bounced into an obstacle, look at that for a while
		else if (bCanStrafe && Destination.IsWithinDist(Player.FocusLocation, 400.0))
			MoveComp.RotateTowardsDirection(FocusDir, Settings.TurnDuration, DeltaTime, Movement); // Strafing slow near user, look where player is looking
		else if (!bIsAtDestination)
			MoveComp.RotateTowardsDirection(DestDir, Settings.TurnDuration, DeltaTime, Movement); // Turn towards destination
		else  
			MoveComp.StopRotating(Settings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Destination, 40, 4, bIsNear ? FLinearColor::Green : FLinearColor::LucBlue);
		}
#endif
	}

	FVector UpdateDestination(float DeltaTime)
	{
		if (RepositionCountdown < 0.0)
		{
			FollowTarget = GetRandomVector(Settings.FollowOffsetMin, Settings.FollowOffsetMax);
			FollowTarget.Z = Math::Lerp(FollowTarget.Z, Settings.FollowOffsetMax.Z, Math::Max(1.0 - Math::Abs(FollowTarget.Y) * 0.025, 0.0));
			RepositionCountdown = Math::RandRange(0.5, 1.0) * Settings.FollowRepositionInterval;
		}
		FollowOffset.AccelerateTo(FollowTarget, 3.0, DeltaTime);

		FVector PlayerVel = PlayerTrailComp.GetAverageVelocity(0.5);
		PlayerVel.Z *= 0.2; // Reduce predicted vertical velocity
		FVector PlayerVelDir = PlayerVel.GetSafeNormal();

		// Move to position offset from player
		AHazePlayerCharacter Player = CompanionComp.Player;		
		FRotator ViewRot = Player.ViewRotation;
		FVector Offset;
		Offset = Player.ActorForwardVector * FollowOffset.Value.X;
		float SideFactor = Math::Max(0.0, (1.0 - (2.0 * Math::Abs(PlayerVelDir.DotProduct(ViewRot.RightVector)))));		
		Offset += ViewRot.RightVector * FollowOffset.Value.Y * SideFactor;
		Offset.Z = FollowOffset.Value.Z;
		FVector Destination = Player.ActorLocation + Offset;

		// Add some prediction, more if player is moving away from camera
		float DirFactor = PlayerVelDir.DotProduct(ViewRot.ForwardVector); 
		float PredictionTime = Math::GetMappedRangeValueClamped(FVector2D(-0.5, 1.0), FVector2D(0.0, 1.5), DirFactor);
		Destination += PlayerVel * PredictionTime;
		Destination += CompanionComp.UpdatePlayerGroundVelocity(DeltaTime) * 0.8;
		return Destination;
	}	

	FVector GetRandomVector(FVector Min, FVector Max)
	{
		FVector Range;
		Range.X = Math::RandRange(Min.X, Max.X); 
		Range.Y = Math::RandRange(Min.Y, Max.Y); 
		Range.Z = Math::RandRange(Min.Z, Max.Z); 
		return Range;
	}
}

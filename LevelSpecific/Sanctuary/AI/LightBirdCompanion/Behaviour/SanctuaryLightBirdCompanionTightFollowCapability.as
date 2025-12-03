class USanctuaryLightBirdCompanionTightFollowCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"FlyingMovement");
	default CapabilityTags.Add(n"BlockedDuringIntro");	

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 140; // This is a fallback behaviour, but overrides regular follow
	default DebugCategory = CapabilityTags::Movement;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	UPlayerAimingComponent UserAimComp;	
	TPerPlayer<UTargetTrailComponent> Trails;
	USanctuaryLightBirdCompanionSettings Settings;
	UTeleportingMovementData Movement;
	
	FVector StartLocation; 
	FVector StartTangent;
	FVector EndTangent;
	FVector Destination;

	FHazeAcceleratedFloat Speed;
	float CurrentDistance;
	float CurveLength;

	bool bAtUser = false;
	FHazeAcceleratedVector AccWorldLocation;
	FHazeAcceleratedRotator AccWorldRotation;

	float MovingDuration;
	FHazeAcceleratedVector PredictionOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		UserAimComp = UPlayerAimingComponent::Get(Game::Zoe);
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();

		Trails[Game::Zoe] = UTargetTrailComponent::GetOrCreate(Game::Zoe);
		Trails[Game::Mio] = UTargetTrailComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())
			return;

		if (Trails[CompanionComp.Player].GetAverageVelocity(0.5).SizeSquared() > Math::Square(200.0))
			MovingDuration += DeltaTime;
		else 
			MovingDuration = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!Settings.bFollowTightAllowed)
			return false;
		if (CompanionComp.State != ELightBirdCompanionState::Follow)
			return false;
		if (SceneView::IsInView(CompanionComp.Player, Owner.ActorLocation, FVector2D(0.2, 0.8), FVector2D(0.2, 0.8)))
		{
			if (Time::GetGameTimeSince(CompanionComp.LastLaunchedTime) < Settings.FollowTightAfterLaunchDelay)
				return false;
			if ((MovingDuration < Settings.FollowTightMovingDuration) && 
				Owner.ActorLocation.IsWithinDist(CompanionComp.Player.FocusLocation, Settings.FollowTightRange))
				return false;
		}
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
		if ((ActiveDuration > 2.0) && (MovingDuration == 0.0) && 
			Owner.ActorLocation.IsWithinDist(CompanionComp.Player.FocusLocation, Settings.FollowTightRange * 0.5))
			return true;
		if (CompanionComp.Player.IsPlayerDead())
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = ELightBirdCompanionState::Follow;

		// We must detach before commencing move
		CompanionComp.Detach();
		bAtUser = false;

		StartLocation = Owner.ActorLocation;

		Destination = GetDestination();
		float Distance = Math::Max(Destination.Distance(StartLocation), 1.0);

		StartTangent = Owner.ActorVelocity.GetClampedToMaxSize(Distance * 0.5);

		FVector DestDir = (Destination - Owner.ActorLocation).GetSafeNormal2D();
		EndTangent = (DestDir * 0.7 - CompanionComp.Player.ActorUpVector * 0.3) * Math::Min(Distance * 0.5, 500.0);

		Speed.SnapTo(Owner.ActorVelocity.Size());
		CurrentDistance = 0.0;
		CurveLength = Distance; 

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PredictionOffset.SnapTo(FVector::ZeroVector);

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
		// Crumbed regular movement
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
			ComposeMovement(DeltaTime);
		else
			Movement.ApplyCrumbSyncedAirMovement();

		MoveComp.ApplyMove(Movement);
	}

	void UpdatePredictionOffset(float DeltaTime)
	{
		FVector TargetOffset = FVector::ZeroVector;
		FVector PlayerVel = Trails[CompanionComp.Player].GetAverageVelocity(0.5);
		PlayerVel.Z *= 0.2; // Reduce predicted vertical velocity
		float PlayerSpeed = PlayerVel.Size();
		if (PlayerSpeed > 0.0)
		{
			// Add some prediction, more if player is moving away from camera
			FVector PlayerVelDir = PlayerVel / PlayerSpeed;
			float DirFactor = PlayerVelDir.DotProduct(CompanionComp.Player.ViewRotation.ForwardVector); 
			float PredictionTime = Math::GetMappedRangeValueClamped(FVector2D(-0.5, 1.0), FVector2D(0.0, 1.0), DirFactor);
			TargetOffset = PlayerVel * PredictionTime;
		}
		PredictionOffset.AccelerateTo(TargetOffset, 5.0, DeltaTime);		
	}

	FVector GetDestination() const
	{
		FTransform Transform = CompanionComp.Player.ActorTransform;
		Transform.Rotation = FQuat::MakeFromZX(CompanionComp.Player.ActorUpVector, CompanionComp.Player.ViewRotation.ForwardVector);
		FVector Dest = Transform.TransformPositionNoScale(Settings.FollowOffsetMax);
		return Dest + PredictionOffset.Value;
	}

	bool HasReachedUser()
	{
		if (bAtUser)
			return false; // Already attached
		if (ActiveDuration < 0.2)
			return false;
		if (CurrentDistance < CurveLength - 400.0)
			return false;
		return true;
	}

	void ReachUser()
	{
		bAtUser = true;
		AccWorldLocation.SnapTo(Owner.ActorLocation, Owner.ActorVelocity);
		AccWorldRotation.SnapTo(Owner.ActorRotation);
	}

	void ComposeMovement(float DeltaTime)
	{
		if (HasReachedUser())
			ReachUser();

		Destination = GetDestination();
		FVector OwnLoc = Owner.ActorLocation;

		if (bAtUser)
		{	
			// Move exactly to wanted offset with lag
			UpdatePredictionOffset(DeltaTime);
			AccWorldLocation.AccelerateTo(GetDestination(), Settings.FollowAtUserLag, DeltaTime);
			AccWorldRotation.AccelerateTo(CompanionComp.Player.ActorRotation, Settings.TightFollowTurnDuration, DeltaTime);
			Movement.AddDelta(AccWorldLocation.Value - Owner.ActorLocation);
			Movement.SetRotation(AccWorldRotation.Value);
			return;
		}

		// Move along curve to get near fast
		float TargetSpeed = Settings.FollowTightSpeed;
		if (CurrentDistance > CurveLength - Settings.FollowNearRange)
			TargetSpeed = Settings.FollowNearSpeed;
		Speed.AccelerateTo(TargetSpeed, Settings.FollowTightAccelerationDuration, DeltaTime);
		CurrentDistance += Speed.Value * DeltaTime;
		FVector StartControl = StartLocation + StartTangent;
		FVector EndControl = Destination - EndTangent;
		CurveLength = BezierCurve::GetLength_2CP(StartLocation, StartControl, EndControl, Destination);
		float Alpha = Math::Min(1.0, CurrentDistance / CurveLength);
		FVector NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(StartLocation, StartControl, EndControl, Destination, Alpha);
		FVector Delta = NewLoc - OwnLoc;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Delta / DeltaTime);

		// Align with velocity
		MoveComp.RotateTowardsDirection(Delta, Settings.TightFollowTurnDuration, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			float Interval = 0.02;
			FVector PrevLoc = StartLocation; 
			for (float DbgAlpha = Interval; DbgAlpha < 1.0; DbgAlpha += Interval)
			{
				FVector CurveLoc = BezierCurve::GetLocation_2CP(StartLocation, StartControl, EndControl, Destination, DbgAlpha);
				Debug::DrawDebugLine(PrevLoc, CurveLoc, FLinearColor::Purple, 3.0);
				PrevLoc = CurveLoc;
			} 
		}
#endif
	}
};
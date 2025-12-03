// class UPinballBossBallAvoidDroneCapability : UHazeCapability
// {
// 	default NetworkMode = EHazeCapabilityNetworkMode::Local;

// 	default CapabilityTags.Add(CapabilityTags::GameplayAction);

// 	default TickGroup = EHazeTickGroup::BeforeMovement;
// 	default TickGroupOrder = 100;

// 	APinballBossBall BossBall;
// 	UPinballBallComponent BallComp;
// 	UHazeMovementComponent MoveComp;

// 	float ConstraintDistance;
// 	float AvoidanceDistance;

// 	const bool bApplyConstraint = true;
// 	const bool bApplyAvoidance = false;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		BossBall = Cast<APinballBossBall>(Owner);
// 		BallComp = UPinballBallComponent::Get(Owner);
// 		MoveComp = UHazeMovementComponent::Get(Owner);

// 		float DroneRadius = UPinballBallComponent::Get(Pinball::GetBallPlayer()).GetRadius();
// 		float BossRadius = BallComp.GetRadius();

// 		ConstraintDistance = DroneRadius + BossRadius;
// 		AvoidanceDistance = ConstraintDistance + 20;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		// if(!HasControl())
// 		// 	return false;
		
// 		// const FVector Delta = GetDeltaFromPlayer();
// 		// if(Delta.Size() > AvoidanceDistance)
// 		// 	return false;

// 		// return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		const FVector Delta = GetDeltaFromPlayer();
// 		if(Delta.Size() > AvoidanceDistance)
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		FVector DeltaFromPlayer = GetDeltaFromPlayer();
// 		const float DistanceToPlayer = DeltaFromPlayer.Size();
// 		const FVector DirFromPlayer = DeltaFromPlayer.GetSafeNormal();

// 		if(bApplyConstraint && DistanceToPlayer < ConstraintDistance)
// 		{
// 			Constraint(DistanceToPlayer, DirFromPlayer);
// 			DeltaFromPlayer = GetDeltaFromPlayer();
// 		}

// 		if(bApplyAvoidance)
// 		{
// 			Avoidance(DeltaFromPlayer);
// 		}
// 	}

// 	void Constraint(float DistanceToPlayer, FVector DirFromPlayer)
// 	{
// 		FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MoveComp);
// 		Trace.IgnorePlayers();
// 		const float TraceDistance = ConstraintDistance - DistanceToPlayer;
// 		if(TraceDistance <= KINDA_SMALL_NUMBER)
// 			return;

// 		const FVector TargetDelta = DirFromPlayer * TraceDistance;
// 		const FVector End = Owner.ActorLocation + TargetDelta;
// 		FHitResult Hit = Trace.QueryTraceSingle(Owner.ActorLocation, End);

// 		if(Hit.bBlockingHit)
// 		{
// 			if(!Hit.bStartPenetrating)
// 				Owner.SetActorLocation(Hit.Location);
// 		}
// 		else
// 		{
// 			Owner.SetActorLocation(End);
// 		}
// 	}

// 	void Avoidance(FVector DeltaFromPlayer)
// 	{
// 		const float DistanceToPlayer = DeltaFromPlayer.Size();
// 		const float Alpha = Math::NormalizeToRange(DistanceToPlayer, ConstraintDistance, AvoidanceDistance);
// 		const float Force = Math::Lerp(50, 10, Alpha);
// 		Owner.AddMovementImpulse((DeltaFromPlayer / DistanceToPlayer) * Force);
// 	}

// 	FVector GetDeltaFromPlayer() const
// 	{
// 		FVector DroneLocation = Pinball::GetBallPlayer().ActorLocation;
// 		FVector Delta = Owner.ActorLocation - DroneLocation;
// 		return Delta.VectorPlaneProject(FVector::ForwardVector);
// 	}
// };
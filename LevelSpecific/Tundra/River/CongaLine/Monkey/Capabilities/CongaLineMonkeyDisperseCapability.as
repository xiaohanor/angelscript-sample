struct FCongaLineMonkeyWallAvoidanceResult
{
	FVector RunAwayDirection;
	float InterpSpeed;
	bool bTurnAround = false;

#if EDITOR
	void LogToTemporalLog(FTemporalLog& TemporalLog, FVector ActorCenterLocation) const
	{
		TemporalLog.DirectionalArrow("3. WallAvoidanceResult;RunAwayDirection", ActorCenterLocation, RunAwayDirection * 500);
		TemporalLog.Value("3. WallAvoidanceResult;InterpSpeed", InterpSpeed);
		TemporalLog.Value("3. WallAvoidanceResult;bTurnAround", bTurnAround);
	}
#endif
}

struct FCongaLineMonkeyDisperseActivateParams
{
	FVector RunAwayDirection;
	float RunAwayDuration;
}

/**
 * Run away in a semi-random direction and avoid walls
 */
class UCongaLineMonkeyDisperseCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	ACongaLineMonkey Monkey;
	UCongaLineDancerComponent DancerComp;

	UHazeMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	float RunAwayDuration;
	FVector RunAwayDirection;

	bool bTurnAround = false;

	float Radius;

	const float DefaultInterpSpeed = 5.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ACongaLineMonkey>(Owner);
		DancerComp = UCongaLineDancerComponent::Get(Owner);

		MoveComp = UHazeMovementComponent::Get(Monkey);
		MoveData = MoveComp.SetupTeleportingMovementData();

		Radius = Monkey.CollisionComp.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCongaLineMonkeyDisperseActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(DancerComp.bShouldDisperse)
		{
			Params.RunAwayDirection = Owner.ActorLocation - DancerComp.CurrentLeader.Player.ActorLocation;
			Params.RunAwayDirection = Params.RunAwayDirection.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			Params.RunAwayDuration = Math::RandRange(CongaLine::DancersDisperseDuration.Min, CongaLine::DancersDisperseDuration.Max);
			return true;
		}

		if(!DancerComp.IsInCongaLine())
			return false;

		if(CongaLine::IsCongaLineActive())
			return false;

		Params.RunAwayDirection = Owner.ActorLocation - DancerComp.CurrentLeader.Player.ActorLocation;
		Params.RunAwayDirection = Params.RunAwayDirection.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		Params.RunAwayDuration = Math::RandRange(CongaLine::DancersDisperseDuration.Min, CongaLine::DancersDisperseDuration.Max);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > RunAwayDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCongaLineMonkeyDisperseActivateParams Params)
	{
		RunAwayDirection = Params.RunAwayDirection;
		RunAwayDuration = Params.RunAwayDuration;
		
		DancerComp.CurrentState = ECongaLineDancerState::Dispersing;
		UCongaLineMonkeyEventHandler::Trigger_OnDisperse(Monkey);
		DancerComp.bHasDispersed = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(HasControl())
			DancerComp.bShouldDisperse = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			if(bTurnAround)
				TickTurnAround(DeltaTime);
			else
				TickRunAway(DeltaTime);
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	private void TickTurnAround(float DeltaTime)
	{
#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		LogCurrentState(TemporalLog, "1. Turn Around Initial", FVector::ZeroVector);
#endif
		// When turning around, simply interp towards the corner normal
		FQuat Rotation = Math::QInterpConstantTo(Owner.ActorQuat, FQuat::MakeFromZX(FVector::UpVector, RunAwayDirection), DeltaTime, 15);

		if(Rotation.ForwardVector.GetAngleDegreesTo(RunAwayDirection) < 25)
		{
			// We have finished turning around
			bTurnAround = false;
		}

		MoveData.SetRotation(Rotation);

#if EDITOR
		LogCurrentState(TemporalLog, "4. Turn Around Final", FVector::ZeroVector);
#endif
	}

	private void TickRunAway(float DeltaTime)
	{
#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
#endif

		// Random jitter to not run in a straight line
		float Noise = Math::PerlinNoise1D((ActiveDuration + RunAwayDuration) * CongaLine::DancersDisperseRandomTurnFrequency);
		float RandomAngle = Noise * CongaLine::DancersDisperseRandomTurnRate;
		RunAwayDirection = FQuat(FVector::UpVector, Math::DegreesToRadians(RandomAngle) * DeltaTime) * RunAwayDirection;

#if EDITOR
		LogCurrentState(TemporalLog, "1. Run Away Initial", FVector::ZeroVector);
#endif

		float InterpSpeed = DefaultInterpSpeed;
		FCongaLineMonkeyWallAvoidanceResult WallAvoidanceResult;
		const bool bHitWall = WallAvoidance(DeltaTime, WallAvoidanceResult);

#if EDITOR
		WallAvoidanceResult.LogToTemporalLog(TemporalLog, Monkey.ActorCenterLocation);
#endif

		if(bHitWall)
		{
			RunAwayDirection = WallAvoidanceResult.RunAwayDirection;
			InterpSpeed = WallAvoidanceResult.InterpSpeed;

			if(WallAvoidanceResult.bTurnAround)
			{
				// We hit a corner and need to turn around
				bTurnAround = true;
				RunAwayDirection = WallAvoidanceResult.RunAwayDirection;
				TickTurnAround(DeltaTime);	// Tick it immediately instead of allowing further movement
				return;
			}
		}

		FQuat Rotation = Math::QInterpConstantTo(Owner.ActorQuat, FQuat::MakeFromZX(FVector::UpVector, RunAwayDirection), DeltaTime, InterpSpeed);

		MoveData.SetRotation(Rotation);

		FVector Velocity = Rotation.ForwardVector * CongaLine::DancersDisperseSpeed;

#if EDITOR
		LogCurrentState(TemporalLog, "4. Run Away Final", Velocity);
#endif

		MoveData.AddVelocity(Velocity);
	}

	private bool WallAvoidance(float DeltaTime, FCongaLineMonkeyWallAvoidanceResult&out OutResult) const
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Pawn);
		TraceSettings.UseLine();

		const FVector Start = GetTraceStart();
		const float ForwardSpeed = Math::Max(MoveComp.HorizontalVelocity.DotProduct(RunAwayDirection), 0);
		const float TraceDistance = (ForwardSpeed * DeltaTime) + 300;	// Always trace 300 units further than our move delta
		const FVector End = Start + Owner.ActorForwardVector * TraceDistance;
		FHitResult ForwardHit = TraceSettings.QueryTraceSingle(Start, End);

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.HitResults("2. Wall Avoidance;Forward Hit", ForwardHit, TraceSettings.Shape);
#endif

		if(!ForwardHit.IsValidBlockingHit())
			return false;

		if(ForwardHit.Distance < Radius)
		{
			// The hit wall is inside our collision capsule, flip rotation
			OutResult.RunAwayDirection = -Owner.ActorForwardVector;
			OutResult.bTurnAround = true;

			return true;
		}
		else
		{
			// The hit wall is quite far away, interp towards it
			OutResult.RunAwayDirection = Owner.ActorForwardVector.GetReflectionVector(ForwardHit.Normal.VectorPlaneProject(FVector::UpVector));
			OutResult.InterpSpeed = 10;

			// Do another trace from the wall impact along a reflection ray
			const FVector Start2 = ForwardHit.ImpactPoint + ForwardHit.ImpactNormal;
			const FVector End2 = Start2 + OutResult.RunAwayDirection * 200;
			FHitResult CornerHit = TraceSettings.QueryTraceSingle(Start2, End2);

#if EDITOR
			TemporalLog.HitResults("2. Wall Avoidance;Corner Hit", CornerHit, TraceSettings.Shape);
#endif

			if(CornerHit.IsValidBlockingHit())
			{
				// If we hit again, we have found a corner, immediately start turning towards the corner normal
				const FVector CornerNormal = ((ForwardHit.ImpactNormal + CornerHit.ImpactNormal) / 2.0).GetSafeNormal();
				OutResult.RunAwayDirection = CornerNormal;
				OutResult.bTurnAround = true;
			}

			return true;
		}
	}

	private FVector GetTraceStart() const
	{
		return Owner.ActorLocation + FVector(0, 0, 20);
	}

#if EDITOR
	private void LogCurrentState(FTemporalLog& TemporalLog, FString Category, FVector Velocity) const
	{
		TemporalLog.DirectionalArrow(f"{Category};Actor Forward", Monkey.ActorCenterLocation, Owner.ActorForwardVector * 500);
		TemporalLog.Value(f"{Category};bTurnAround", bTurnAround);
		TemporalLog.DirectionalArrow(f"{Category};Run Away Direction", Monkey.ActorCenterLocation, RunAwayDirection * 500);
		TemporalLog.DirectionalArrow(f"{Category};Velocity", Monkey.ActorCenterLocation, Velocity);
	}
#endif
};
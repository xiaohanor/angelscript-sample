class UGravityBikeSplineFlyingEnemyMovementResolver : USimpleMovementResolver
{
	default RequiredDataType = UGravityBikeSplineFlyingEnemyMovementData;

	private const UGravityBikeSplineFlyingEnemyMovementData MoveData;

	private TArray<FGravityBikeSplineImpactResponseComponentAndData> Impacts;

	bool bHitFlyingEnemy = false;
	FVector HitImpulse;
	FVector HitImpactPoint;
	AGravityBikeSplineFlyingEnemy HitFlyingEnemy;

	bool bExplode = false;

	bool bReflectedOffWall = false;
	FVector ReflectionImpulse;
	FVector WallImpactPoint;
	FVector WallImpactNormal;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveData = Cast<UGravityBikeSplineFlyingEnemyMovementData>(Movement);

		Impacts.Reset();

		bHitFlyingEnemy = false;
		HitImpulse = FVector::ZeroVector;
		HitImpactPoint = FVector::ZeroVector;
		HitFlyingEnemy = nullptr;

		bExplode = false;

		bReflectedOffWall = false;
		ReflectionImpulse = FVector::ZeroVector;
		WallImpactPoint = FVector::ZeroVector;
		WallImpactNormal = FVector::ZeroVector;
	}

	FMovementHitResult QueryShapeTrace(
		FHazeMovementTraceSettings TraceSettings,
		FVector TraceFromLocation,
		FVector DeltaToTrace,
		FVector WorldUp,
		FHazeTraceTag TraceTag) const override
	{
		if(MoveData.bNoCollision)
			return FMovementHitResult();

		return Super::QueryShapeTrace(TraceSettings, TraceFromLocation, DeltaToTrace, WorldUp, TraceTag);
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		FGravityBikeSplineImpactResponseComponentAndData ResponseCompAndData;
		if(CollisionWithResponseComp(Hit, ResponseCompAndData))
		{
			Impacts.Add(ResponseCompAndData);

			if(ResponseCompAndData.ResponseComp.bIgnoreAfterImpact)
			{
				IterationTraceSettings.AddPermanentIgnoredActor(ResponseCompAndData.ResponseComp.Owner);
				return EMovementResolverHandleMovementImpactResult::Skip;
			}
		}

		if(HandleHitFlyingEnemy(IterationState, Hit, ImpactType, HitImpulse))
		{
			bHitFlyingEnemy = true;
			HitImpactPoint = Hit.ImpactPoint;
			HitFlyingEnemy = Cast<AGravityBikeSplineFlyingEnemy>(Hit.Actor);
			IterationTraceSettings.AddTransientIgnoredActor(Hit.Actor);

			if(MoveData.bExplodeOnImpact)
			{
				bExplode = true;
				IterationState.CurrentLocation = Hit.Location;
				return EMovementResolverHandleMovementImpactResult::Finish;
			}
			else
			{
				return EMovementResolverHandleMovementImpactResult::Skip;
			}
		}

		if(DeathFromWall(IterationState, Hit, ImpactType))
		{
			bExplode = true;
			return EMovementResolverHandleMovementImpactResult::Finish;
		}

		if(ReflectOffWall(IterationState, Hit, ImpactType, ReflectionImpulse))
		{
			bReflectedOffWall = true;
			WallImpactPoint = Hit.ImpactPoint;
			WallImpactNormal = Hit.ImpactPoint;
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool CollisionWithResponseComp(FMovementHitResult Hit, FGravityBikeSplineImpactResponseComponentAndData&out OutResponseCompAndData) const
	{
		if(!MoveData.bTriggerResponseComponent)
			return false;

		auto ResponseComp = UGravityBikeSplineImpactResponseComponent::Get(Hit.Actor);
		if(ResponseComp == nullptr)
			return false;

		OutResponseCompAndData.ResponseComp = ResponseComp;

		const FHitResult HitResult = Hit.ConvertToHitResult();
		const FVector ImpactVelocity = IterationState.DeltaToTrace / IterationTime;
		OutResponseCompAndData.ImpactData = FGravityBikeSplineOnImpactData(ImpactVelocity, HitResult);

		return true;
	}

	bool HandleHitFlyingEnemy(FMovementResolverState& State, FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType, FVector&out OutReflectionImpulse)
	{
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		if(!Hit.Actor.IsA(AGravityBikeSplineFlyingEnemy))
			return false;

		const FVector AwayFromCar = (State.CurrentLocation - Hit.Actor.ActorLocation).GetSafeNormal();
		OutReflectionImpulse = AwayFromCar * GravityBikeSpline::CarEnemy::HitOtherCarImpulse;

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta.Delta += OutReflectionImpulse * IterationTime;
			MovementDelta.Velocity += OutReflectionImpulse;

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		return true;
	}

	bool DeathFromWall(FMovementResolverState& State, FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) const
	{
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		if(MoveData.bExplodeOnImpact)
		{
			State.CurrentLocation = Hit.Location;
			return true;
		}

		if(Hit.ImpactNormal.DotProduct(MoveData.SplineForward) > GravityBikeSpline::CarEnemy::DeathFromWallDotThreshold)
			return false;

		State.CurrentLocation = Hit.Location;
		return true;
	}

	bool ReflectOffWall(
		FMovementResolverState& State,
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType,
		FVector&out OutReflectionImpulse) const
	{
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		const FVector Velocity = State.GetDelta().Velocity;
		OutReflectionImpulse = Velocity.ProjectOnToNormal(-Hit.Normal);

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = MovementDelta.Bounce(Hit.Normal, 1);

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);
		
		auto FlyingEnemy = Cast<AGravityBikeSplineFlyingEnemy>(MovementComponent.Owner);

		for(auto ResponseCompAndData : Impacts)
		{
			FlyingEnemy.HitImpactResponseComponent(ResponseCompAndData.ResponseComp, ResponseCompAndData.ImpactData);
		}

		if(bHitFlyingEnemy)
			FlyingEnemy.ApplyHitFlyingEnemy(HitImpulse, HitImpactPoint, HitFlyingEnemy);

		if(bExplode)
			FlyingEnemy.ExplodeFromImpact();

		if(bReflectedOffWall)
			FlyingEnemy.ApplyReflectOffWall(ReflectionImpulse, WallImpactPoint, WallImpactNormal);
	}
};
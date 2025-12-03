struct FSkylineFlyingCarEnemyImpactDataAndResponseComponent
{
	UPROPERTY()
	USkylineFlyingCarImpactResponseComponent ResponseComp;

	UPROPERTY()
	FHitResult HitResult;

	UPROPERTY()
	FVector Velocity;
};

class USkylineFlyingCarEnemyMovementResolver : USimpleMovementResolver
{
	default RequiredDataType = USkylineFlyingCarEnemyMovementData;

	private const USkylineFlyingCarEnemyMovementData MoveData;

	TArray<FSkylineFlyingCarEnemyImpactDataAndResponseComponent> Impacts;

	bool bHitOtherCar = false;
	FVector HitOtherCarImpulse;
	FVector HitOtherCarImpactPoint;
	ASkylineFlyingCarEnemy OtherCar;

	bool bExplode = false;

	bool bReflectedOffWall = false;
	FVector ReflectionImpulse;
	FVector WallImpactPoint;
	FVector WallImpactNormal;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveData = Cast<USkylineFlyingCarEnemyMovementData>(Movement);

		Impacts.Reset();

		bHitOtherCar = false;
		HitOtherCarImpulse = FVector::ZeroVector;
		HitOtherCarImpactPoint = FVector::ZeroVector;
		OtherCar = nullptr;

		bExplode = false;

		bReflectedOffWall = false;
		ReflectionImpulse = FVector::ZeroVector;
		WallImpactPoint = FVector::ZeroVector;
		WallImpactNormal = FVector::ZeroVector;
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		FSkylineFlyingCarEnemyImpactDataAndResponseComponent ImpactDataAndResponseComp;
		if(CollideWithResponseComponent(Hit, ImpactDataAndResponseComp))
		{
			Impacts.Add(ImpactDataAndResponseComp);
			
			if(ImpactDataAndResponseComp.ResponseComp.bIgnoreAfterImpact)
			{
				IterationTraceSettings.AddPermanentIgnoredActor(ImpactDataAndResponseComp.ResponseComp.Owner);

				if(ImpactDataAndResponseComp.ResponseComp.VelocityLostOnImpact > KINDA_SMALL_NUMBER)
					LoseVelocity(IterationState, Hit.Normal, ImpactDataAndResponseComp.ResponseComp.VelocityLostOnImpact);

				return EMovementResolverHandleMovementImpactResult::Skip;
			}
		}

		if(HitOtherCar(IterationState, Hit, ImpactType, HitOtherCarImpulse))
		{
			bHitOtherCar = true;
			HitOtherCarImpactPoint = Hit.ImpactPoint;
			OtherCar = Cast<ASkylineFlyingCarEnemy>(Hit.Actor);
			IterationTraceSettings.AddTransientIgnoredActor(OtherCar);
			return EMovementResolverHandleMovementImpactResult::Skip;
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

	bool CollideWithResponseComponent(FMovementHitResult Hit, FSkylineFlyingCarEnemyImpactDataAndResponseComponent&out OutResult) const
	{
		if(!Hit.IsValidBlockingHit())
			return false;

		auto ResponseComp = USkylineFlyingCarImpactResponseComponent::Get(Hit.Actor);
		if(ResponseComp == nullptr)
			return false;

		OutResult.ResponseComp = ResponseComp;
		OutResult.HitResult = Hit.ConvertToHitResult();
		OutResult.Velocity = IterationState.GetDelta().Velocity;

		return true;
	}

	/**
	 * Remove a percentage of our current velocity on impact.
	 */
	void LoseVelocity(FMovementResolverState& State, FVector Normal, float VelocityLostOnImpact) const
	{
		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			// Lose half of the velocity
			FMovementDelta DeltaIntoImpact = MovementDelta.ProjectOntoNormal(Normal);
			FMovementDelta OtherDelta = MovementDelta - DeltaIntoImpact;

			// Lose half of our velocity going into the sign
			DeltaIntoImpact *= (1.0 - VelocityLostOnImpact);

			MovementDelta = DeltaIntoImpact + OtherDelta;

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}
	}

	bool HitOtherCar(
		FMovementResolverState& State,
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType,
		FVector&out OutReflectionImpulse)
	{
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		if(!Hit.Actor.IsA(ASkylineFlyingCarEnemy))
			return false;

		// Bump us away from the car we hit
		const FVector AwayFromCar = (State.CurrentLocation - Hit.Actor.ActorLocation).GetSafeNormal();
		OutReflectionImpulse = AwayFromCar * SkylineFlyingCarEnemy::HitOtherCarImpulse;

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

	bool DeathFromWall(
		FMovementResolverState& State,
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType) const
	{
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		// Explode car if colliding with wall (might need extra checks)
		if(State.CurrentRotation.ForwardVector.DotProduct(Hit.ImpactNormal) > SkylineFlyingCarEnemy::DeathFromWallDotThreshold)
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

			MovementDelta = MovementDelta.Bounce(Hit.Normal, SkylineFlyingCarEnemy::ReflectOffWallRestitution);

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);
		
		auto CarEnemy = Cast<ASkylineFlyingCarEnemy>(MovementComponent.Owner);

		if(CarEnemy.HasControl())
		{
			if(bHitOtherCar)
				CarEnemy.OnHitOtherCar(HitOtherCarImpulse, HitOtherCarImpactPoint, OtherCar);

			if(bExplode)
				CarEnemy.OnExplodeFromWallImpact();

			if(bReflectedOffWall)
				CarEnemy.OnReflectOffWall(ReflectionImpulse, WallImpactPoint, WallImpactNormal);
		}
	}
};
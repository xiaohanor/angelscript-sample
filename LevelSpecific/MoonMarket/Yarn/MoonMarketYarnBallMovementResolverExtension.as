//An extension runs before the HandleMovementImpact step of the resolver
class UMoonMarketYarnBallMovementResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USteppingMovementResolver);
	default SupportedResolverClasses.Add(USweepingMovementResolver);

	UBaseMovementResolver Resolver;

	AMoonMarketYarnBall YarnBall;
	UHazeMovementComponent MoveComp;
	TOptional<FMoonMarketYarnBallLaunchData> LaunchData;

	FVector VelocityOnHit;
	bool bApplyVelocity = false;

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<UMoonMarketYarnBallMovementResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		YarnBall = Other.YarnBall;
		LaunchData = Other.LaunchData;
	}

#endif
	void OnAdded(UHazeMovementComponent MovementComponent) override
	{
		Super::OnAdded(MovementComponent);
		MoveComp = MovementComponent;
	}

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);
		
		Resolver = InResolver;

		//All data must be reset manually between iterations
		YarnBall = nullptr;
		LaunchData.Reset();
	}

	EMovementResolverHandleMovementImpactResult PreHandleMovementImpact(
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		if(bApplyVelocity)
		{
			bApplyVelocity = false;
			auto Delta = Resolver.IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
			Delta.Velocity = VelocityOnHit;
			VelocityOnHit = FVector::ZeroVector;
			Resolver.IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, Delta);
			return EMovementResolverHandleMovementImpactResult::Finish;
		}

		//If the ball is in contact with player, recalculate this iterations movement data without applying the old data
		if(PushBall(Hit, ImpactType) && MoveComp.HasGroundContact())
		{
			auto Delta = Resolver.IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
			bApplyVelocity = true;
			VelocityOnHit = Delta.Velocity;
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool PushBall(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType)
	{
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		if(YarnBall != nullptr)
			return false;

		YarnBall = Cast<AMoonMarketYarnBall>(Hit.Actor);
		if(YarnBall == nullptr)
			return false;

		if(LaunchData.IsSet())
			return false;

		//Do not do anything if player is standing on top of the ball
		if(Hit.IsAnyGroundContact() && YarnBall.Collision.ScaledSphereRadius > 30)
			return false;

		const float HorizontalImpulseSpeed = 1;

		FVector VerticalImpactDirection = (FVector::UpVector * (YarnBall.ActorLocation.Z - Resolver.IterationState.CurrentLocation.Z)).GetSafeNormal();
		const float VerticalImpulseSpeed = 10;

		FVector HorizontalImpulse = Resolver.IterationState.GetDelta().Velocity * HorizontalImpulseSpeed;
		FVector VerticalImpulse = VerticalImpactDirection * VerticalImpulseSpeed;

		LaunchData.Set(FMoonMarketYarnBallLaunchData());
		LaunchData.Value.NewControlSide = Resolver.Owner;
		LaunchData.Value.Impulse = HorizontalImpulse + VerticalImpulse;

		//Resolver.IterationTraceSettings.AddTransientIgnoredActor(YarnBall);
		//Resolver.IterationState.CurrentLocation = Hit.Location;

		return true;
	}

	void PreApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::PreApplyResolvedData(MovementComponent);
	
		if(YarnBall != nullptr && LaunchData.IsSet())
			YarnBall.ApplyLaunchData(LaunchData.Value);
	}
}
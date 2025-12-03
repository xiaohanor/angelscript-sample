class UDentistToothDashMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = UDentistToothDashMovementData;

	private const UDentistToothDashMovementData MovementData;

	private TArray<FHitResult> BounceImpacts;
	private bool bBackflipFromImpact = false;
	private float BackflipDuration = 0;

	private TArray<TSubclassOf<AActor>> DashBackflipIgnoredActors;
	default DashBackflipIgnoredActors.Add(ADentistLaunchedBall);
	default DashBackflipIgnoredActors.Add(ADentistBouncyObstacle);
	default DashBackflipIgnoredActors.Add(ADentistRotatingRollingObstacle);
	default DashBackflipIgnoredActors.Add(ADentistBouncyCherry);

	bool bPerformedStepUp = false;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		
		MovementData = Cast<UDentistToothDashMovementData>(Movement);

		BounceImpacts.Reset();
		bBackflipFromImpact = false;
		BackflipDuration = 0;

		bPerformedStepUp = false;
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		UDentistToothMovementResponseComponent HitMovementResponseComponent;
		if(BounceFromImpact(Hit, IterationState, HitMovementResponseComponent))
		{
			BounceImpacts.Add(Hit.ConvertToHitResult());
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		if(BackflipFromImpactWithResponseComponent(Hit, IterationState, BackflipDuration))
		{
			bBackflipFromImpact = true;
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		if(ImpactType == EMovementResolverAnyShapeTraceImpactType::Iteration)
		{
			if(StepUpOntoWallImpact(Hit))
			{
				bPerformedStepUp = true;
				return EMovementResolverHandleMovementImpactResult::Finish;
			}

			if(BackflipFromWallImpact(Hit, IterationState, BackflipDuration))
			{
				bBackflipFromImpact = true;
				return EMovementResolverHandleMovementImpactResult::Skip;
			}
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool BounceFromImpact(FMovementHitResult Hit, FMovementResolverState& State, UDentistToothMovementResponseComponent&out HitBounceResponseComponent) const
	{
		if(MovementData.GroundHitRestitution <= 0)
			return false;

		auto MovementResponseComp = UDentistToothMovementResponseComponent::Get(Hit.Actor);
		if(MovementResponseComp == nullptr)
			return false;

		if(!MovementResponseComp.ShouldBounceFromImpact(EDentistToothBounceResponseType::Dash))
			return false;

		const FVector BounceNormal = MovementResponseComp.GetBounceNormalForImpactType(Hit.ConvertToHitResult(), EDentistToothBounceResponseType::Dash);

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			const FMovementDelta HorizontalDelta = MovementDelta.PlaneProject(BounceNormal);

			const FVector VerticalImpulse = BounceNormal * MovementResponseComp.DashBounceVerticalImpulse;
			const FMovementDelta VerticalDelta = FMovementDelta(VerticalImpulse * IterationTime, VerticalImpulse);

			MovementDelta = HorizontalDelta + VerticalDelta;

			State.OverrideDelta(It.Key, MovementDelta);
		}

		State.CurrentLocation = Hit.Location;

		HitBounceResponseComponent = MovementResponseComp;

		return true;
	}

	bool StepUpOntoWallImpact(FMovementHitResult WallImpact)
	{
		const float StepUpSize = MovementData.ShapeSizeForMovement;

		if(StepUpSize < KINDA_SMALL_NUMBER)
			return false;

		const FMovementHitResult& GroundContact = IterationState.PhysicsState.GroundContact;
		FVector GroundLocation = WallImpact.Location;
		if(GroundContact.IsAnyGroundContact())
			GroundLocation = GroundContact.Location;

		// Use bottom of shape
		GroundLocation = IterationState.ConvertLocationToShapeBottomLocation(GroundLocation, IterationTraceSettings);

		const FVector TraceDirection = WallImpact.TraceDirection;
		const FVector ImpactNormal = WallImpact.ImpactNormal;

		// We should only trigger a step up if we are moving towards the surface horizontally.
		if (ImpactNormal.DotProduct(TraceDirection) > 0.0)
			return false;

		const FVector ImpactPoint = WallImpact.ImpactPoint;
		const FVector ImpactPointDelta = ImpactPoint - GroundLocation;
		float StepHeight = ImpactPointDelta.DotProduct(IterationState.WorldUp);

		if(StepHeight >= StepUpSize - KINDA_SMALL_NUMBER)
			return false;
		
		FVector InwardsDirection = TraceDirection.VectorPlaneProject(IterationState.WorldUp).GetSafeNormal();
		if(InwardsDirection.IsNearlyZero())
			return false;

		// Validate the ground where we want to stepup so we can actually step up here
		{
			FVector TraceFrom = ImpactPoint;
			TraceFrom += InwardsDirection * MovementData.SafetyDistance.X;
			TraceFrom += IterationState.WorldUp * (MovementData.ShapeSizeForMovement + MovementData.SafetyDistance.Y);

			FVector TraceDownDelta = -IterationState.WorldUp * (MovementData.ShapeSizeForMovement * 2);

			auto OutStepUpHit = QueryShapeTrace(TraceFrom, TraceDownDelta, FHazeTraceTag(n"StepUpHit"));

			if(!OutStepUpHit.IsAnyGroundContact())
				return false;

			IterationState.ApplyMovement(WallImpact.Time, OutStepUpHit.Location + OutStepUpHit.Normal);
			ChangeGroundedState(OutStepUpHit);
		}

		return true;
	}

	bool BackflipFromWallImpact(FMovementHitResult Hit, FMovementResolverState& State, float&out OutBackflipDuration) const
	{
		if(bBackflipFromImpact)
			return false;

		if(!Hit.IsWallImpact())
			return false;

		for(auto IgnoredActor : DashBackflipIgnoredActors)
		{
			if(Hit.Actor.Class.IsChildOf(IgnoredActor))
				return false;
		}

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			FVector BounceImpulse = FVector::ZeroVector;
			FVector BackflipLaunchHorizontalDirection = Hit.Normal.GetSafeNormal2D(FVector::UpVector);

			BounceImpulse += BackflipLaunchHorizontalDirection * 1000;

			BounceImpulse += FVector::UpVector * 1000;
			
			MovementDelta = FMovementDelta(BounceImpulse * IterationTime, BounceImpulse);

			State.OverrideDelta(It.Key, MovementDelta);
		}

		State.CurrentLocation = Hit.Location;
		State.CurrentRotation = FQuat::MakeFromZX(FVector::UpVector, -Hit.Normal.GetSafeNormal2D(FVector::UpVector));
		OutBackflipDuration = MovementData.BackflipDurationMultiplier;

		return true;

		// for(auto It : State.DeltaStates)
		// {
		// 	FMovementDelta MovementDelta = It.Value.ConvertToDelta();
		// 	if(MovementDelta.IsNearlyZero())
		// 		continue;

		// 	FVector ReflectionNormal = Hit.Normal.GetSafeNormal();

		// 	MovementDelta = MovementDelta.Bounce(ReflectionNormal, MovementData.WallHitRestitution);

		// 	State.OverrideDelta(It.Key, MovementDelta);
		// }

		// State.CurrentLocation = Hit.Location;

		// return true;
	}

	bool BackflipFromImpactWithResponseComponent(FMovementHitResult Hit, FMovementResolverState& State, float&out OutBackflipDuration) const
	{
		if(bBackflipFromImpact)
			return false;

		auto MovementResponseComp = UDentistToothMovementResponseComponent::Get(Hit.Actor);
		if(MovementResponseComp == nullptr)
			return false;

		if(MovementResponseComp.OnDashImpact != EDentistToothDashImpactResponse::Backflip)
			return false;

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			FVector BounceImpulse = FVector::ZeroVector;
			FVector BackflipLaunchHorizontalDirection = -MovementDelta.Velocity.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

			BounceImpulse += BackflipLaunchHorizontalDirection * MovementResponseComp.BackflipHorizontalImpulse;

			BounceImpulse += FVector::UpVector * MovementResponseComp.BackflipHorizontalImpulse;
			
			MovementDelta = FMovementDelta(BounceImpulse * IterationTime, BounceImpulse);

			State.OverrideDelta(It.Key, MovementDelta);
		}

		State.CurrentLocation = Hit.Location;
		OutBackflipDuration = MovementResponseComp.BackflipDuration * MovementData.BackflipDurationMultiplier;

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MovementComponent.Owner);

		if(bPerformedStepUp)
		{
			FVector Offset = Player.ActorLocation - IterationState.CurrentLocation;
			Player.MeshOffsetComponent.AddWorldOffset(Offset);
			Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 1);
		}

		Super::ApplyResolvedData(MovementComponent);
		
		auto DashComp = UDentistToothDashComponent::Get(Player);

		if(!BounceImpacts.IsEmpty())
		{
			for(auto Impact : BounceImpacts)
			{
				auto HitBounceResponseComponent = UDentistToothMovementResponseComponent::Get(Impact.Actor);
				if(HitBounceResponseComponent == nullptr)
					continue;

				HitBounceResponseComponent.OnBouncedOn.Broadcast(Player, EDentistToothBounceResponseType::Dash, Impact);
			}

			DashComp.ResetDashDuration();
		}

		if(bBackflipFromImpact)
			DashComp.SetBackflip(BackflipDuration);
	}
};
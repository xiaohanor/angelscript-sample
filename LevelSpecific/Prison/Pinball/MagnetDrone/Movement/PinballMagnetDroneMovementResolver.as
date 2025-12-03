class UPinballMagnetDroneMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = UPinballMagnetDroneMovementData;
	default MutableDataClass = UPinballMagnetDroneMovementResolverMutableData;

	private const UPinballMagnetDroneMovementData PinballSweepingData;
	private UPinballMagnetDroneMovementResolverMutableData PinballMutableData;

	private FPinballBallLaunchData LaunchData;
	
	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		PinballSweepingData = Cast<UPinballMagnetDroneMovementData>(Movement);
		PinballMutableData = Cast<UPinballMagnetDroneMovementResolverMutableData>(MutableData);
		LaunchData = FPinballBallLaunchData();
	}

	bool PrepareNextIteration() override
	{
		if (LaunchData.IsValid())
			return false;

		return Super::PrepareNextIteration();
	}

#if EDITOR
	FMovementHitResult QueryShapeTrace(FHazeMovementTraceSettings TraceSettings,
									   FVector TraceFromLocation, FVector DeltaToTrace, FVector WorldUp,
									   FHazeTraceTag TraceTag) const override
	{
		FMovementHitResult Hit = Super::QueryShapeTrace(TraceSettings, TraceFromLocation, DeltaToTrace, WorldUp, TraceTag);
		PinballMutableData.DebugMovementSweeps.Add(Hit);
		return Hit;
	}
#endif

	FMovementDelta GenerateIterationDelta() const override
	{
		FMovementDelta IterationDelta = Super::GenerateIterationDelta();
		return IterationDelta.PlaneProject(FVector::ForwardVector);
	}

	FMovementDelta ProjectMovementUponImpact(FMovementDelta DeltaState, FMovementHitResult Impact,
											 FMovementHitResult GroundedState) const override
	{
		FMovementDelta PlaneDeltaState = DeltaState.PlaneProject(FVector::ForwardVector);
		return Super::ProjectMovementUponImpact(PlaneDeltaState, Impact, GroundedState);
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		// if(Network::IsGameNetworked() && Pinball::GetBallPlayer().HasControl())
		// {
		// 	// Impacts are handled from the paddle side
		// 	return EMovementResolverHandleMovementImpactResult::Continue;
		// }

		if(HitBouncePad(Hit))
			return EMovementResolverHandleMovementImpactResult::Finish;

		if(HitBreakableLock(Hit))
			return EMovementResolverHandleMovementImpactResult::Finish;

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	private bool HitBouncePad(const FMovementHitResult& MovementHit)
	{
		auto BouncePad = Cast<APinballBouncePad>(MovementHit.Actor);
		if(BouncePad == nullptr)
			return false;

		FPinballBouncePadHitResult BouncePadHitResult;
		if(!BouncePad.CalculateBouncePadHitResult(BouncePadHitResult))
			return false;

		FVector LaunchVelocity = BouncePadHitResult.GetImpulseVector();

		LaunchData = FPinballBallLaunchData(
			BouncePadHitResult.LaunchLocation,
			IterationState.CurrentLocation,
			LaunchVelocity,
			BouncePad.LauncherComp,
			PinballSweepingData.bIsProxy
		);

		IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, FMovementDelta());
		IterationState.CurrentLocation = MovementHit.Location;
		return true;
	}

	private bool HitBreakableLock(const FMovementHitResult& MovementHit)
	{
		auto BreakableLock = Cast<APinballBreakableLock>(MovementHit.Actor);
		if(BreakableLock == nullptr)
			return false;

		if(BreakableLock.bBroken)
			return false;

		const FVector DirFromLock = (IterationState.CurrentLocation - BreakableLock.ActorLocation);
		const FVector Normal = DirFromLock.VectorPlaneProject(FVector::ForwardVector);
		const FVector LaunchDir = IterationState.GetDelta().Velocity.GetReflectionVector(Normal).GetSafeNormal();

		const FVector LaunchVelocity = LaunchDir * BreakableLock.LaunchPower;
		const FVector LaunchDelta = LaunchVelocity * IterationTime;

		IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, FMovementDelta(LaunchDelta, LaunchVelocity));
		IterationState.CurrentLocation = MovementHit.Location;

		LaunchData = FPinballBallLaunchData(
			MovementHit.Location,
			IterationState.CurrentLocation,
			LaunchVelocity,
			BreakableLock.LauncherComp,
			PinballSweepingData.bIsProxy
		);

		IterationTraceSettings.AddPermanentIgnoredActor(BreakableLock);

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		if(LaunchData.IsValid())
		{
			// No contacts if we were launched
			IterationState.PhysicsState = FMovementContacts();
		}

		Super::ApplyResolvedData(MovementComponent);

		if(PinballSweepingData.bIsProxy)
			ApplyResolvedData_Proxy(MovementComponent);
		else
			ApplyResolvedData_Player(MovementComponent);
	}

	private void ApplyResolvedData_Player(UHazeMovementComponent MovementComponent)
	{
		check(!PinballSweepingData.bIsProxy);

		auto BallComp = UPinballBallComponent::Get(Owner);
		if(BallComp == nullptr)
			return;

		if(LaunchData.IsValid())
		{
			BallComp.Launch(LaunchData);
		}
	}

	private void ApplyResolvedData_Proxy(UHazeMovementComponent MovementComponent)
	{
		check(PinballSweepingData.bIsProxy);

		auto ProxyMovementComponent = Cast<UPinballProxyMovementComponent>(MovementComponent);

#if EDITOR
		ProxyMovementComponent.DebugMovementSweeps.Append(PinballMutableData.DebugMovementSweeps);
#endif

		if(LaunchData.IsValid())
		{
			FPinballMagnetDroneProxyMovementIterationResult Result;
			Result.Subframe = ProxyMovementComponent.Proxy.SubframeNumber;
			Result.OtherSideTime = ProxyMovementComponent.Proxy.TickGameTime;
			Result.LaunchData = LaunchData;

			ProxyMovementComponent.IterationResults.Add(Result);
		}
	}

	void GetResolvedVelocityToApply(FVector& OutHorizontal, FVector& OutVertical) const override
	{
		Super::GetResolvedVelocityToApply(OutHorizontal, OutVertical);
		
		OutHorizontal.X = 0;
		OutVertical.X = 0;
	}

	void Resolve() override
	{
		Super::Resolve();

		IterationState.CurrentLocation.X = 0;
		
		// Make sure to constrain to the plane
		// for (auto& It : IterationState.DeltaStates)
		// {
		// 	FMovementDelta MovementDelta = It.Value.ConvertToDelta();
		// 	if(MovementDelta.IsNearlyZero())
		// 		continue;

		// 	MovementDelta.PlaneProject(FVector::ForwardVector, false);
		// 	IterationState.OverrideDelta(It.Key, MovementDelta);
		// }
	}
}
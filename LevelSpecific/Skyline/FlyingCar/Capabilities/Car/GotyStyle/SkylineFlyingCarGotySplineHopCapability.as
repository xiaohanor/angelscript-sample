class USkylineFlyingCarGotySplineHopCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarMovement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;

	default DebugCategory = n"FlyingCar";

	ASkylineFlyingCar CarOwner;

	UFlyingCarOfficeAssistedJumpComponent AssistedJumpComponent;

	UHazeMovementComponent MovementComponent;
	USkylineFlyingCarMovementData MoveData;

	USkylineFlyingCarGotySettings Settings;

	FVector ExitSplineVector;

	FSkylineFlyingCarSplineParams InitialSplineParams;
	FVector2D InitialInput;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarOwner = Cast<ASkylineFlyingCar>(Owner);
		AssistedJumpComponent = UFlyingCarOfficeAssistedJumpComponent::Get(Owner);
		MovementComponent = CarOwner.MovementComponent;
		MoveData = MovementComponent.SetupMovementData(USkylineFlyingCarMovementData);
		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CarOwner.bWasJumpActionStarted)
			return false;

		if (AssistedJumpComponent.bWaitingForInput)
			return false;

		if (!CarOwner.CanManeuver())
			return false;

		if (CarOwner.IsSplineDashing())
			return false;

		if (!CarOwner.CanLeaveHighway())
			return false;

		FSkylineFlyingCarSplineParams SplineParams;
		CarOwner.GetSplineDataAtPosition(CarOwner.ActorLocation, SplineParams);

		if (CarOwner.ActiveHighway == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= Settings.SplineHoppingAccelerationDuration)
			return true;

		if (!CarOwner.CanManeuver())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
		{
			// Store exit spline
			CarOwner.GetSplineDataAtPosition(CarOwner.ActorLocation, InitialSplineParams);
			// ExitSplineVector = InitialSplineParams.SplinePosition.WorldForwardVector;

			// FVector Input = MakePlayerInput(InitialSplineParams.SplinePosition);

			// FVector ExitVeloctiy = Math::Lerp(Input, MovementComponent.Velocity.GetSafeNormal(), 0.5) * MovementComponent.Velocity.Size() * Settings.SplineBoostSpeedMultiplier;
			// CarOwner.SetActorVelocity(ExitVeloctiy);

			InitialInput = FVector2D(CarOwner.YawInput, CarOwner.PitchInput);
			if (InitialInput.IsNearlyZero(0.02))
				InitialInput = FVector2D(0.0, 1.0);

			CarOwner.bIsSplineHopping = true;
			CarOwner.SetActiveHighway(nullptr);

			// Clear vertical velocity
			FVector StrippedVelocity = CarOwner.ActorVelocity.ConstrainToDirection(InitialSplineParams.SplinePosition.WorldForwardVector)
				+ CarOwner.ActorRightVector * CarOwner.YawInput * Settings.SplineHoppingInitialHorizontalImpulse * Settings.FreeFlySteeringMultiplier;
			CarOwner.SetActorVelocity(StrippedVelocity);

			StartLocation = CarOwner.ActorLocation;
		}

		// Fire event
		USkylineFlyingCarEventHandler::Trigger_OnSplineHopStart(CarOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CarOwner.bIsSplineHopping = false;
		CarOwner.bJustSplineHopped = true;

		SpeedEffect::ClearSpeedEffect(CarOwner.Pilot, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			// float TunnelFraction = Math::Max(0, (InitialSplineParams.DirToSpline.DotProduct(CarOwner.MovementWorldUp) + 1.0) * 0.5);
			float DurationFraction = Math::Saturate(ActiveDuration / Settings.SplineHoppingAccelerationDuration);

			FVector TargetHeight = InitialSplineParams.SplinePosition.WorldLocation + CarOwner.MovementWorldUp * (Settings.SplineHoppingHeight + InitialSplineParams.HighWay.CorridorHeight);
			FVector CarToTargetHeight = (TargetHeight - CarOwner.ActorLocation).ConstrainToDirection(CarOwner.MovementWorldUp);

			// Debug::DrawDebugSphere(CarOwner.ActorLocation + CarToTargetHeight, 100, 12, FLinearColor::Green);

			FVector HorizontalImpulse = InitialSplineParams.SplinePosition.WorldRightVector * InitialInput.X * Settings.YawRotationSpeed * Settings.FreeFlySteeringMultiplier * 10;

			// float VerticalImpulseMultiplier = 1.0 - Math::Pow(Math::Saturate(ActiveDuration / 0.5), 2);
			// VerticalImpulseMultiplier *= Math::Lerp(0.5, 1., Math::Abs(CarOwner.PitchInput));
			// FVector VerticalImpulse = CarOwner.MovementWorldUp * 26000.0 * VerticalImpulseMultiplier; // Eman TODO: Expose setting

			// How fast we go out of the tunnel
			const float HopSpeed = 15.0;

			// Add vertical impulse if we are still below mark
			const float ImpulseMultiplier = Math::Max(0.0, HopSpeed - Math::Pow(DurationFraction * HopSpeed * 1.2, 2));

			float Magic = 60; // hmmmmm
			FVector VerticalImpulse = CarToTargetHeight.GetSafeNormal().DotProduct(CarOwner.MovementWorldUp) > 0 ?
				(CarToTargetHeight * ((Magic * ImpulseMultiplier) / (Math::Sqrt(CarToTargetHeight.Size())))) : FVector::ZeroVector;

			FVector Impulse = VerticalImpulse + HorizontalImpulse;
			CarOwner.AddMovementImpulse(Impulse * DeltaTime, n"SplineHopCapability");
		}

		// Add some speed shimmer for shits and giggles
		float EffectFraction = 1.0 - Math::Abs((Math::Saturate(ActiveDuration / Settings.SplineHoppingAccelerationDuration) - 0.5) * 2.0);
		EffectFraction = 1.0 - Math::Square(Math::Saturate(ActiveDuration / Settings.SplineHoppingAccelerationDuration));
		SpeedEffect::RequestSpeedEffect(CarOwner.Pilot, EffectFraction, this, EInstigatePriority::Normal);
	}

	FVector MakePlayerInput(FSplinePosition SplinePosition)
	{
		return (SplinePosition.WorldRightVector * CarOwner.YawInput + SplinePosition.WorldUpVector * CarOwner.PitchInput).GetSafeNormal();
	}
}
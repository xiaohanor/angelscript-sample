asset JetskiWaterMovementSettings of UJetskiMovementSettings
{
    MaxSpeed = 4000;
    MaxSpeedWhileTurning = 1500;
    Acceleration = 3000;
    Deceleration = 2000;
};

struct FJetskiWaterMovementActivateParams
{
	EJetskiMovementState PreviousMovementState;
};

class UJetskiWaterMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 120;

	AJetski Jetski;
	UJetskiMovementComponent MoveComp;
	UJetskiMovementData MoveData;

	FQuat PreviousWaveFollowingRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		MoveComp = Jetski.MoveComp;
		MoveData = MoveComp.SetupJetskiMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FJetskiWaterMovementActivateParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!Jetski.IsInWater())
			return false;

		if(Jetski.bIsJumpingFromUnderwater)
			return false;

		Params.PreviousMovementState = Jetski.GetMovementState();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!Jetski.IsInWater())
			return true;

		const FVector FrontWaterDir = Jetski.GetFrontWaterSampleComponent().SampleWaveNormal().VectorPlaneProject(FVector::UpVector);
		const FVector WaterUpDir = Jetski.GetUpVector(EJetskiUp::WaveNormal).VectorPlaneProject(FVector::UpVector);
		const bool bIsOnTopOfWave = FrontWaterDir.DotProduct(WaterUpDir) < -0.2;

		if(MoveComp.VerticalSpeed > 0 && bIsOnTopOfWave)
		{
			// The front is further down than the average, consider this an edge!
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FJetskiWaterMovementActivateParams Params)
	{
		FJetskiOnLandOnWaterEventData EventData;
		EventData.Location = Jetski.GetWaveLocation();
		EventData.Velocity = MoveComp.Velocity;
		EventData.WaveNormal = Jetski.GetUpVector(EJetskiUp::WaveNormal);

#if !RELEASE
		const FVector InitialVelocity = MoveComp.Velocity;
#endif

		Jetski.SetMovementState(EJetskiMovementState::Water);

		float VerticalSpeed = MoveComp.Velocity.DotProduct(Jetski.GetUpVector(EJetskiUp::WaveNormal));
		FVector VerticalVelocity = Jetski.GetVerticalVelocity(EJetskiUp::WaveNormal);
		FVector HorizontalVelocity = MoveComp.Velocity - VerticalVelocity;

		if(VerticalSpeed < 0)
		{
			float VelocityKeptMultiplier = MoveComp.MovementSettings.WaterLandVelocityKeptMultiplier;
			if(Params.PreviousMovementState == EJetskiMovementState::Ground)
				VelocityKeptMultiplier = MoveComp.MovementSettings.WaterEnterFromGroundVelocityKeptMultiplier;

			VerticalVelocity *= VelocityKeptMultiplier;
		}

		Jetski.SetActorVelocity(HorizontalVelocity + VerticalVelocity);

		PreviousWaveFollowingRotation = FQuat::MakeFromZX(Jetski.GetUpVector(EJetskiUp::WaveNormal), Jetski.ActorForwardVector);

		UJetskiEventHandler::Trigger_OnLandOnWater(Jetski, EventData);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("OnActivated;Initial Velocity", InitialVelocity);
		TemporalLog.Value("OnActivated;Vertical Speed", VerticalSpeed);
		TemporalLog.Value("OnActivated;Vertical Velocity", VerticalVelocity);
		TemporalLog.Value("OnActivated;Horizontal Velocity", HorizontalVelocity);
		TemporalLog.Value("OnActivated;Horizontal Velocity", HorizontalVelocity);
		TemporalLog.Value("OnActivated;Velocity", MoveComp.Velocity);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData, Jetski.ActorUpVector))
			return;

		if (HasControl())
		{
#if !RELEASE
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
#endif

			const FVector WaveNormal = Jetski.GetUpVector(EJetskiUp::WaveNormal);
			Jetski.AccelerateUpTowards(FQuat::MakeFromZX(WaveNormal, Jetski.ActorForwardVector), 1, DeltaTime, this);

			const bool bIsGoingUpWave = IsGoingUpWave();

			const FQuat CurrentWaveFollowRotation = FQuat::MakeFromZX(WaveNormal, Jetski.ActorForwardVector);
			FVector Velocity = MoveComp.Velocity;

			if(bIsGoingUpWave)
			{
				// If we are traveling up a wave, rotate the velocity to follow the wave up
				// This helps prevent going straight through waves
				const FQuat DeltaWaveFollowRotation = CurrentWaveFollowRotation * PreviousWaveFollowingRotation.Inverse();
				Velocity = DeltaWaveFollowRotation * Velocity;
			}

			Velocity = Jetski.SetNewForwardVelocity(Velocity, EJetskiUp::Global, DeltaTime);

			FVector HorizontalVelocity = Velocity.VectorPlaneProject(Jetski.GetUpVector(EJetskiUp::Global));

			MoveData.AddVelocity(HorizontalVelocity);

			float VerticalSpeed = Velocity.DotProduct(Jetski.GetUpVector(EJetskiUp::Global));

			const float WaveHeight = Jetski.GetWaveHeight();
			float WaterLineHeight = Jetski.GetWaterLineHeight();

			// Substep the buoyancy
			const float DesiredTimeStep = 1.0 / 60.0;
			float BuoyancyTimeLeft = DeltaTime;
			while(BuoyancyTimeLeft > 0)
			{
				const float TimeStep = Math::Min(DesiredTimeStep, BuoyancyTimeLeft);

				RunBuoyancyStep(TimeStep, WaveHeight, bIsGoingUpWave, WaterLineHeight, VerticalSpeed);

				// Apply this step delta to the waterline height
				WaterLineHeight += VerticalSpeed * TimeStep;
				BuoyancyTimeLeft -= DesiredTimeStep;
			}

			MoveData.AddVelocity(FVector::UpVector * VerticalSpeed);

			Jetski.SteerJetski(MoveData, DeltaTime);

			MoveData.AddPendingImpulses();

			PreviousWaveFollowingRotation = CurrentWaveFollowRotation;

#if !RELEASE
			TemporalLog.Value("Water Height", WaveHeight);
			TemporalLog.Value("Water Line Height", WaterLineHeight);
			TemporalLog.Value("Is Going Up Wave", bIsGoingUpWave);
			TemporalLog.DirectionalArrow("Water Normal", Jetski.ActorLocation, WaveNormal * 500, 20);
#endif
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	/**
	 * The buoyancy is inherently framerate dependent since it relies on how much of the sphere is underwater
	 * Substep it!
	 */
	void RunBuoyancyStep(float DeltaTime, float WaveHeight, bool bIsGoingUpWave, float& WaterLineHeight, float& VerticalSpeed) const
	{
		if(WaveHeight > WaterLineHeight)
		{
			const float Diff = WaveHeight - WaterLineHeight;

			float BuoyancyFactor = Math::GetMappedRangeValueClamped(FVector2D(0, Jetski.GetSphereRadius()), FVector2D(0, 1), Diff);

			float BuoyancyAcceleration = BuoyancyFactor * 5;
			if(bIsGoingUpWave)
				BuoyancyAcceleration *= 5;

			const float BuoyancySpeed = Math::Lerp(100, 1000, BuoyancyFactor);

			// Yes this it framerate dependent, partly the reason for the substeps 😉
			VerticalSpeed = Math::FInterpTo(VerticalSpeed, BuoyancySpeed, DeltaTime, BuoyancyAcceleration);
		}
		else
		{
			VerticalSpeed -= 1000 * DeltaTime;
		}
	}

	bool IsGoingUpWave(float AngleThreshold = 0) const
	{
		const float ForwardSpeedAlongWave = Jetski.GetForwardSpeed(EJetskiUp::WaveNormal);

		if(ForwardSpeedAlongWave < 500)
			return false;	// Going too slow

		const FVector WaveNormal = Jetski.GetUpVector(EJetskiUp::WaveNormal);
		const FVector HorizontalVelocityDirection = Jetski.GetHorizontalVelocity(EJetskiUp::Global).GetSafeNormal();
		const float WaveAngle = WaveNormal.GetAngleDegreesTo(HorizontalVelocityDirection);

		// If the wave normal is pointing in the direction of travel, we are not going up a wave
		if(WaveAngle < 90 + AngleThreshold)
			return false;

		return true;
	}

	bool IsGoingDownWave(float AngleThreshold = 0) const
	{
		const float ForwardSpeedAlongWave = Jetski.GetForwardSpeed(EJetskiUp::WaveNormal);

		if(ForwardSpeedAlongWave < 500)
			return false;	// Going too slow

		const FVector WaveNormal = Jetski.GetUpVector(EJetskiUp::WaveNormal);
		const FVector HorizontalVelocityDirection = Jetski.GetHorizontalVelocity(EJetskiUp::Global).GetSafeNormal();
		const float WaveAngle = WaveNormal.GetAngleDegreesTo(HorizontalVelocityDirection);

		// If the wave normal is pointing away from the direction of travel, we are not going up a wave
		if(WaveAngle > 90 - AngleThreshold)
			return false;

		return true;
	}
};
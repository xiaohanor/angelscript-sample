class UJetskiBobbingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;
	
	AJetski Jetski;
	UJetskiBobbingComponent BobbingComp;
	UJetskiMovementComponent MoveComp;

	EJetskiMovementState PreviousMovementState;
	float PreviousForwardSpeed = 0;

	FHazeAcceleratedFloat AccActualYawVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		BobbingComp = Jetski.BobbingComponent;
		MoveComp = Jetski.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BobbingComp.AccRoll.SnapTo(Jetski.MeshPivot.RelativeRotation.Roll);
		BobbingComp.AccPitch.SnapTo(Jetski.MeshPivot.RelativeRotation.Pitch);

		PreviousMovementState = Jetski.GetMovementState();
		PreviousForwardSpeed = Jetski.GetForwardSpeed(EJetskiUp::ActorUp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BobbingComp.AccPitch.SnapTo(0);
		BobbingComp.AccRoll.SnapTo(0);
		BobbingComp.RelativeOffsetFromImpact = FRotator::ZeroRotator;
		BobbingComp.ApplyLocationAndRotation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleImpacts(DeltaTime);

		Roll(DeltaTime);
		Pitch(DeltaTime);

		BobbingComp.RelativeOffsetFromImpact = Math::RInterpShortestPathTo(
			BobbingComp.RelativeOffsetFromImpact,
			FRotator::ZeroRotator,
			DeltaTime,
			Jetski.Settings.BobbingReflectRotationOffsetDecreaseFactor
		);


		BobbingComp.ApplyLocationAndRotation();
	}

	void HandleImpacts(float DeltaTime)
	{
		EJetskiMovementState NewMovementState = Jetski.GetMovementState();

		if(NewMovementState != PreviousMovementState)
		{
			const bool bIsInWater = NewMovementState == EJetskiMovementState::Water || NewMovementState == EJetskiMovementState::Underwater;
			const bool bWasInWater = PreviousMovementState == EJetskiMovementState::Water || PreviousMovementState == EJetskiMovementState::Underwater;
			
			if(bIsInWater && !bWasInWater)
			{
				const FVector WaveNormal = Jetski.GetUpVector(EJetskiUp::WaveNormal);
				const float FrontImpactFactor = MoveComp.Velocity.VectorPlaneProject(WaveNormal).GetSafeNormal().DotProduct(Jetski.ActorForwardVector.VectorPlaneProject(WaveNormal).GetSafeNormal());
				const float ForwardSpeed = MoveComp.Velocity.DotProduct(Jetski.ActorForwardVector);
				const float SideSpeed = MoveComp.Velocity.DotProduct(Jetski.ActorRightVector);
				const float VerticalSpeed = MoveComp.Velocity.DotProduct(WaveNormal);
				const float ImpactStrength = Math::Abs(VerticalSpeed);

#if !RELEASE
					FTemporalLog TemporalLog = TEMPORAL_LOG(BobbingComp);
					TemporalLog
						.Event(f"Water impact!")
						.DirectionalArrow("Water Impact;WaveNormal", Jetski.ActorLocation, WaveNormal * 100)
						.Value("Water Impact;FrontImpactFactor", FrontImpactFactor)
						.Value("Water Impact;ForwardSpeed", ForwardSpeed)
						.Value("Water Impact;SideSpeed", SideSpeed)
						.Value("Water Impact;VerticalSpeed", VerticalSpeed)
						.Value("Water Impact;ImpactStrength", ImpactStrength)
					;
#endif
				
				if(ImpactStrength > Jetski.Settings.BobbingMinimumVerticalSpeedForImpactImpulse)
				{
					float PitchVelocity = ImpactStrength * ForwardSpeed * FrontImpactFactor * Jetski.Settings.BobbingWaterImpactPitch;
					PitchVelocity += ImpactStrength * VerticalSpeed * Jetski.Settings.BobbingWaterImpactPitch;
					PitchVelocity = BobbingComp.GetClampedPitchVelocity(PitchVelocity);
					BobbingComp.AccPitch.Velocity = -PitchVelocity;

					float RollVelocity = ImpactStrength * SideSpeed * (1.0 - FrontImpactFactor) * Jetski.Settings.BobbingWaterImpactRoll;
					RollVelocity = BobbingComp.GetClampedRollVelocity(RollVelocity);
					BobbingComp.AccRoll.Velocity = -RollVelocity;

#if !RELEASE
					TemporalLog
						.Value("Water Impact;PitchVelocity", PitchVelocity)
						.Value("Water Impact;RollVelocity", RollVelocity)
					;
#endif
				}
			}
		}
		
		PreviousMovementState = NewMovementState;
	}

	void Roll(float DeltaTime)
	{
		float TargetRoll = 0;

		const float Steering = Jetski.Input.GetSteering();

		if(Math::Abs(Steering) > 0.2)
		{
			AccActualYawVelocity.AccelerateTo(0, 2, DeltaTime);
			TargetRoll = BobbingComp.GetClampedRoll(-Jetski.AngularSpeed * Jetski.Settings.BobbingWaterSteeringRoll);
		}
		else
		{
			AccActualYawVelocity.AccelerateTo(Jetski.ActualAngularVelocity.Yaw, 2, DeltaTime);
			TargetRoll = Math::Clamp(BobbingComp.GetClampedRoll(AccActualYawVelocity.Value * -10 * Jetski.Settings.BobbingWaterSteeringRoll), -15, 15);
		}

		BobbingComp.AccRoll.SpringTo(TargetRoll, Jetski.Settings.BobbingWaterSteeringRollStiffness, Jetski.Settings.BobbingWaterSteeringRollDamping, DeltaTime);
	}

	void Pitch(float DeltaTime)
	{
		auto CurrentMovementState = Jetski.GetMovementState();

		switch(CurrentMovementState)
		{
			case EJetskiMovementState::Underwater:
			{
				if(MoveComp.Velocity.Size() < 100)
				{
					BobbingComp.AccPitch.AccelerateTo(0, Jetski.Settings.BobbingWaterDivingPitchDuration, DeltaTime);
				}
				else
				{
					FVector DivingDirection = MoveComp.Velocity.GetSafeNormal();
					DivingDirection.Z = Math::Clamp(DivingDirection.Z, -0.5, 0.5);
					DivingDirection = DivingDirection.GetSafeNormal();
					
					FRotator TargetRotation = FRotator::MakeFromXY(DivingDirection, Jetski.ActorRightVector);
					FRotator TargetRelativeRotation = Jetski.ActorTransform.InverseTransformRotation(TargetRotation);
					float TargetPitch = BobbingComp.GetClampedPitch(TargetRelativeRotation.Pitch * Jetski.Settings.BobbingWaterDivingPitch);
					BobbingComp.AccPitch.AccelerateTo(TargetPitch, Jetski.Settings.BobbingWaterDivingPitchDuration, DeltaTime);
				}
				break;
			}

			case EJetskiMovementState::Air:
			{
				BobbingComp.AccPitch.AccelerateTo(0, Jetski.Settings.BobbingWaterPitchAirDuration, DeltaTime);
				break;
			}

			default:
			{
				float ForwardJerk = Jetski.GetForwardSpeed(EJetskiUp::ActorUp) - PreviousForwardSpeed;
				float TargetPitch = BobbingComp.GetClampedPitch(ForwardJerk * Jetski.Settings.BobbingWaterPitchJerk);
				BobbingComp.AccPitch.SpringTo(TargetPitch, Jetski.Settings.BobbingWaterPitchJerkStiffness, Jetski.Settings.BobbingWaterPitchJerkDamping, DeltaTime);
				break;
			}
		}
	}
};
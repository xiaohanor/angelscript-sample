// NOT CURRENTLY USED, WE USE SIDEWAY SWING MOVEMENT INSTEAD

class USanctuaryCompanionAviationToAttackMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	FVector StrafeDirection;
	FVector PitchDirection;
	FHazeAcceleratedFloat AccPitch;
	FHazeAcceleratedFloat AccStrafe;

	FHazeAcceleratedRotator AccRotator;
	FVector SafeDirection;

	FVector InitialTowardsDestination;
	FVector InitialRightOfDestination;
	FVector SplineDirection;

	FHazeAcceleratedVector AccBarrelRollUp;
	FHazeAcceleratedVector AccForwardDirection;
	FHazeAcceleratedFloat AccSpeed;

	FHazeAcceleratedFloat AccRollSpeed;
	FHazeAcceleratedFloat AccRoll;
	float AccumulatedRoll = 0.0;
	float AccumulatedPitch = 0.0;

	float OriginalDistance;

	bool bDebug = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!AviationComp.HasDestination())
			return false;

		if (AviationComp.AviationState == EAviationState::Attacking)
			return false;

		if (AviationComp.AviationState != EAviationState::ToAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!AviationComp.HasDestination())
			return true;

		if (AviationComp.AviationState == EAviationState::Attacking)
			return true;

		if (AviationComp.AviationState != EAviationState::ToAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		SafeDirection = Owner.ActorForwardVector;
		// SafeDirection = Direction;
		AccForwardDirection.SnapTo(Owner.ActorForwardVector);
		AccRotator.SnapTo(Owner.ActorRotation);
		InitialTowardsDestination = GetToTarget().GetSafeNormal();
		InitialRightOfDestination = FVector::UpVector.CrossProduct(InitialTowardsDestination).GetSafeNormal();
		SpeedEffect::RequestSpeedEffect(Player, AviationComp.Settings.SpeedEffectIntensity, this, EInstigatePriority::Normal);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
		AccBarrelRollUp.SnapTo(Player.ActorUpVector);
		AccSpeed.SnapTo(GetCurrentSpeed());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		AviationComp.ResetEndOfMovementSpline();
		SpeedEffect::ClearSpeedEffect(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				bDebug = AviationDevToggles::DrawPath.IsEnabled();
				FVector SafeBlendedDirection = GetBlendedSafeDirection(DeltaTime);
				AccForwardDirection.AccelerateTo(SafeBlendedDirection, GetAccelerationDuration(), DeltaTime);
				FVector NewForwardVelocity = AccForwardDirection.Value;

				if (MoveComp.Velocity.Size() > KINDA_SMALL_NUMBER) // Take old velocity into account as well
					NewForwardVelocity = NewForwardVelocity * MoveComp.Velocity.Size() + MoveComp.Velocity;

				AccSpeed.AccelerateTo(GetCurrentSpeed(), 0.2, DeltaTime);
				NewForwardVelocity = NewForwardVelocity.GetClampedToSize(AccSpeed.Value - 1.0, AccSpeed.Value);
				Movement.AddVelocity(NewForwardVelocity);

				// Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + NewForwardVelocity, FLinearColor::LucBlue, 5.0, 0.0, true);
				AccRotator.AccelerateTo(GetNewRotation(NewForwardVelocity.GetSafeNormal(), DeltaTime), GetRotationAccelerationDuration(), DeltaTime);
				Movement.SetRotation(AccRotator.Value);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	// -------------------

	private FVector GetToTarget()
	{
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		FVector ToTarget;
		AviationComp.ResetEndOfMovementSpline();
		SplineDirection = FVector::ZeroVector;
		if (DestinationData.HasRuntimeSpline())
		{
			// DestinationData.Spline.GetClosestSplineDistanceToWorldLocation
			if (bDebug)
				DestinationData.RuntimeSpline.DrawDebugSpline();

			FVector StartLocation = DestinationData.RuntimeSpline.GetLocationAtDistance(0.0);
			FVector EndLocation = DestinationData.RuntimeSpline.GetLocationAtDistance(DestinationData.RuntimeSpline.Length);

			FVector ClosestPoint = Math::ClosestPointOnLine(StartLocation, EndLocation, Player.ActorLocation);
			float MaxDistance = (EndLocation - StartLocation).Size();
			float DistanceInFuture = (ClosestPoint - StartLocation).Size() + 500.0;
			if (DistanceInFuture >= MaxDistance)
			{
				AviationComp.SetEndOfMovementSpline();
				DistanceInFuture = Math::Clamp(DistanceInFuture, 0.0, MaxDistance);
			}
			SplineDirection = (EndLocation - StartLocation).GetSafeNormal();
			FVector FuturePos = StartLocation + SplineDirection * DistanceInFuture;
			ToTarget = FuturePos - Owner.ActorLocation;

			if (bDebug)
			{
				Debug::DrawDebugLine(Player.ActorLocation, ClosestPoint, FLinearColor::DPink, 5.0, 0.0, true);
				Debug::DrawDebugLine(Player.ActorLocation, FuturePos, FLinearColor::LucBlue, 5.0, 0.0, true);
			}
		}
		if (bDebug)
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + SplineDirection * 400.0, FLinearColor::Purple, 10.0, 0.0, true);

		return ToTarget;
	}

	FVector GetMovementInputDirection(float DeltaTime)
	{
		FVector MoveInput = MoveComp.MovementInput.GetSafeNormal();

		float NormalizedPitchInput = (MoveInput.X * 0.5) + 0.5;
		float PitchTarget = Math::Lerp(-AviationComp.Settings.ToAttackMovementPitchMaxAngle, AviationComp.Settings.ToAttackMovementPitchMaxAngle, NormalizedPitchInput);
		AccPitch.SpringTo(PitchTarget, AviationComp.Settings.ToAttackMovementPitchSpringStiffness, AviationComp.Settings.ToAttackMovementPitchSpringDampening, DeltaTime);
		
		float NormalizedStrafeInput = (MoveInput.Y * 0.5) + 0.5; //Math::EaseIn(0.0, 1.0, , 3.0);
		// Debug::DrawDebugString(Player.ActorLocation, "\nStrafe " + NormalizedStrafeInput, ColorDebug::Vermillion);
		AccStrafe.AccelerateTo(Math::Lerp(-AviationComp.Settings.ToAttackMovementStrafeMaxAngle, AviationComp.Settings.ToAttackMovementStrafeMaxAngle, NormalizedStrafeInput), AviationComp.Settings.ToAttackMovementStrafeInterpolationDuration, DeltaTime);

		FRotator FinalOrientationRot = SplineDirection.ToOrientationRotator() + FRotator::MakeFromEuler(FVector(0, 0.0, AccStrafe.Value)) + FRotator::MakeFromEuler(FVector(0.0, AccPitch.Value, 0.0));
		if (bDebug)
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + FinalOrientationRot.ForwardVector * 400.0, FLinearColor(0.60, 0.18, 0.18), 7.0, 0.0, true);

		if (bDebug)
			Debug::DrawDebugString(Player.ActorLocation, "Strafe " + AccStrafe.Value + " Pitch " + AccPitch.Value);

		// FVector StrafeDirection = Math::VInterpNormalRotationTo(Direction, BlendedDirection.GetSafeNormal(), DeltaTime, AviationComp.Settings.ToAttackMovementStrafeSpeed);
		// FVector PitchDirection = Math::VInterpNormalRotationTo(Direction, BlendedDirection.GetSafeNormal(), DeltaTime, AviationComp.Settings.ToAttackMovementPitchSpeed);
		return FinalOrientationRot.ForwardVector;
	}

	private float GetCurrentSpeed()
	{
		return AviationComp.Settings.ToAttackForwardSpeed; // 
	}

	private FRotator GetNewRotation(FVector ForwardDirection, float DeltaTime)
	{
		FVector SupposedInput = MoveComp.MovementInput.GetSafeNormal();

		FVector FakeInput = FVector(1.0, SupposedInput.Y, SupposedInput.X * -1.0);
		FakeInput = Owner.ActorRotation.ForwardVector.ToOrientationRotator().RotateVector(FakeInput);

		// Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + FakeInput * 300.0, FLinearColor::Yellow, 5.0, 0.0, true);

		float DesiredRollIncrease = SupposedInput.Y;
		bool bUnroll = DesiredRollIncrease < KINDA_SMALL_NUMBER && DesiredRollIncrease > -KINDA_SMALL_NUMBER && !Math::IsNearlyEqual(AccumulatedRoll, 0.0, 0.1);
		if (bUnroll)
		{
			float TowardsZero = AccumulatedRoll > 0.0 ? -1.0 : 1.0;
			AccRollSpeed.AccelerateTo(AviationComp.Settings.ToAttackRotationUnrollSpeed * TowardsZero, AviationComp.Settings.ToAttackRotationUnrollAccelerationDuration, DeltaTime);
			float PreviousRoll = AccumulatedRoll;
			AccumulatedRoll += AccRollSpeed.Value * DeltaTime;
			if (Math::Sign(PreviousRoll) != Math::Sign(AccumulatedRoll)) // overshoot
			{
				AccRollSpeed.SnapTo(0.0);
				AccumulatedRoll = 0.0;
			}
		}
		else
		{
			AccRollSpeed.AccelerateTo(AviationComp.Settings.ToAttackRotationRollSpeed * DesiredRollIncrease, AviationComp.Settings.ToAttackRotationRollAccelerationDuration, DeltaTime);
			AccumulatedRoll += AccRollSpeed.Value * DeltaTime;
		}

		if (AviationComp.Settings.bToAttackClampRollRotation)
			AccumulatedRoll = Math::Clamp(AccumulatedRoll, -AviationComp.Settings.ToAttackClampRollRotationMax, AviationComp.Settings.ToAttackClampRollRotationMax);
		AccRoll.SpringTo(AccumulatedRoll, 20, 0.5, DeltaTime);
		// Debug::DrawDebugString(Player.ActorLocation, "Roll " + AccRoll.Value);

		float OrientationPitch = ForwardDirection.ToOrientationRotator().Pitch;
		// Debug::DrawDebugString(Player.ActorLocation, "OPitch " + OrientationPitch);

		//ForwardDirection
		FRotator NewRotation = SplineDirection.ToOrientationRotator() + FRotator::MakeFromEuler(FVector(AccRoll.Value, 0.0, 0.0)) + FRotator::MakeFromEuler(FVector(0.0, OrientationPitch, 0.0 ));
		if (bDebug)
		{
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ForwardDirection * 400.0, FLinearColor::Yellow, 10.0, 0.0, true);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + NewRotation.ForwardVector * 400.0, FLinearColor::LucBlue, 10.0, 0.0, true);
		}
		return NewRotation; //ForwardDirection.ToOrientationRotator();
	}

	private FVector ClampYawToDegreesAngle(FVector InVector, float AngleDegrees)
	{
		FVector ClampedYaw;
		FVector2D MaxYawDelta = Math::AngleDegreesToDirection(AngleDegrees);
		ClampedYaw.X = Math::Clamp(InVector.X, -MaxYawDelta.X, MaxYawDelta.X);
		ClampedYaw.Y = Math::Clamp(InVector.Y, -MaxYawDelta.Y, MaxYawDelta.Y);
		return ClampedYaw;
	}

	private FVector ClampPitchToDegreesAngle(FVector InVector, float AngleDegrees)
	{
		FVector ClampedYaw;
		FVector2D MaxYawDelta = Math::AngleDegreesToDirection(AngleDegrees);
		ClampedYaw.X = Math::Clamp(InVector.X, -MaxYawDelta.X, MaxYawDelta.X);
		ClampedYaw.Z = Math::Clamp(InVector.Z, -MaxYawDelta.Y, MaxYawDelta.Y);
		return ClampedYaw;
	}

	private FVector GetBlendedSafeDirection(float DeltaTime)
	{
		FVector ToTarget = GetToTarget();
		FVector MovementInputDirection = GetMovementInputDirection(DeltaTime);

		float InputAlpha = AviationComp.AviationAllowedInputAlpha;
		float ReverseInputAlpha = 1.0 - InputAlpha;
		FVector AutoSteerDirection = Math::Lerp(ToTarget.GetSafeNormal(), SplineDirection, AviationComp.AviationUseSplineParallelAlpha);
		FVector InputDirection = MovementInputDirection.GetSafeNormal();
		// Blend input and auto steering. No allowed input equals full auto steer
		FVector BlendedDirection = (InputDirection * InputAlpha) + (AutoSteerDirection * ReverseInputAlpha);

		if (BlendedDirection.Size() < KINDA_SMALL_NUMBER * 2.0)
			BlendedDirection = SafeDirection;

		// Get last direction before input reaches almost 0
		if (BlendedDirection.Size() > KINDA_SMALL_NUMBER * 2.0)
			SafeDirection = BlendedDirection.GetSafeNormal();
		return SafeDirection;
	}

	private float GetRotationAccelerationDuration()
	{
		const float Multiplier = 1.0;
		float SoftLerp = Math::Clamp(ActiveDuration * Multiplier, 0.0, 1.0);
		return Math::Lerp(1.0, 0.01, SoftLerp);
	}

	private float GetAccelerationDuration()
	{
		return AviationComp.Settings.NormalAviationInterpolateDirectionDuration;
	}
}
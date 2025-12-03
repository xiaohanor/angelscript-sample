namespace Pinball::GroundMoveSimulation
{
	void Tick(FVector& Delta, FVector& Velocity, float MoveInput, bool bIsOnWalkableGround, FVector GroundNormal, FVector WorldUp, UPinballMovementSettings Settings, float DeltaTime)
	{
		Delta = Velocity * DeltaTime;
		
		check(GroundNormal.IsUnit());
		check(WorldUp.IsUnit());
		FVector GroundNormal2D = GroundNormal;
		GroundNormal2D.X = 0;
		GroundNormal2D.Normalize();

		const FVector WorldRight = Pinball::GetWorldRight(WorldUp);
		const FVector MovementInput = WorldRight * MoveInput;

		FVector VerticalVelocity = Velocity.ProjectOnToNormal(WorldUp);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;
		HorizontalVelocity.X = 0;

		// Input
		const bool bIsInputting = Math::Abs(MoveInput) > KINDA_SMALL_NUMBER;

		const float SlopeAngleDeg = GroundNormal2D.GetAngleDegreesTo(WorldUp);
		const bool bIsOnSlope = SlopeAngleDeg > Settings.MinSlopeAngle;

		if(bIsInputting)
		{
			const bool bIsAccelerating = HorizontalVelocity.DotProduct(MovementInput) > 0;
			if(!IsOverHorizontalMaxSpeedVector(HorizontalVelocity, Settings) || !bIsAccelerating)
			{
				const bool bIsRebound = HorizontalVelocity.DotProduct(MovementInput) < 0;

				float Multiplier = 1;
				if(bIsRebound)
					Multiplier *= Math::Lerp(1, Settings.ReboundMultiplier, Math::Abs(MoveInput));

				if(bIsOnSlope)
				{
					const bool bIsInputtingUpSlope = Math::Sign(GroundNormal2D.Y) != Math::Sign(MoveInput);

					if(bIsInputtingUpSlope)
					{
						float SlopeFactor = Math::Saturate(Math::NormalizeToRange(SlopeAngleDeg, Settings.MinSlopeAngle, Settings.MaxInputSlopeAngle));
						SlopeFactor = Math::Pow(SlopeFactor, Settings.UpSlopeExponent);
						Multiplier *= Math::Lerp(1, Settings.UpSlopeMultiplier, SlopeFactor);
					}
				}

				const FVector Acceleration = MovementInput * Settings.MoveForce * Multiplier;
				Acceleration::ApplyAccelerationToVelocity(HorizontalVelocity, Acceleration, DeltaTime, Delta);

				// If we accelerated past the max, clamp
				if(IsOverHorizontalMaxSpeedVector(HorizontalVelocity, Settings))
					HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(Settings.MaxSpeed);
			}
		}

		if(HorizontalVelocity.Size() > Settings.MinimumSpeedToDecelerate)
		{
			if(bIsOnSlope && Settings.bDecelerateOnSlopes)
			{
				HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, FVector::ZeroVector, DeltaTime, Settings.SlopeDecelerateSpeed, Delta);
			}
			else
			{
				HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, FVector::ZeroVector, DeltaTime, Settings.DecelerateSpeed, Delta);
			}
		}

		if(IsOverHorizontalMaxSpeedVector(HorizontalVelocity, Settings))
		{
			// Decelerate if over max speed
			HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, HorizontalVelocity.GetClampedToMaxSize(Settings.MaxSpeed), DeltaTime, Settings.MaxSpeedDeceleration, Delta);
		}
		
		// Gravity
		const FVector GravityDirection = Pinball::GetGravityDirection(WorldUp);
		Acceleration::ApplyAccelerationToVelocity(VerticalVelocity, GravityDirection * Settings.Gravity, DeltaTime, Delta);

		Velocity = VerticalVelocity + HorizontalVelocity;

		// Try to mitigate sliding on very slightly sloping surfaces by putting the delta straight into the ground, instead of global down, and remove horizontal delta
		if(bIsOnWalkableGround && !bIsOnSlope && HorizontalVelocity.IsNearlyZero() && !Delta.VectorPlaneProject(WorldUp).IsZero())
		{
			Delta = GroundNormal2D * Delta.DotProduct(WorldUp);
		}

#if EDITOR
		if(Velocity.Size() > Pinball::MaximumAllowedMoveSpeed)
			PrintToScreen(f"Moving too fast! Speed of {Math::RoundToFloat(Velocity.Size())} when only {Pinball::MaximumAllowedMoveSpeed} is allowed!", Color = FLinearColor::Yellow);
#endif
	}

	bool IsOverHorizontalMaxSpeedVector(FVector HorizontalVelocity, UPinballMovementSettings Settings)
	{
		return HorizontalVelocity.Size() > Settings.MaxSpeed;
	}
};
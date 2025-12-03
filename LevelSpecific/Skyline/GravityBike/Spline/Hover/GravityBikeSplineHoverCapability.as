class UGravityBikeSplineHoverCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSplineHover);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineHoverComponent HoverComp;
	UGravityBikeSplineMovementComponent MoveComp;

	TOptional<FMovementHitResult> PreviousGround;
	TOptional<FVector> PreviousVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		HoverComp = UGravityBikeSplineHoverComponent::Get(GravityBike);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);

		GravityBike.OnHitImpactResponseComponent.AddUFunction(this, n"OnHitImpactResponseComponent");
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		Pitch(DeltaTime);
		Yaw(DeltaTime);
		Roll(DeltaTime);

		HoverComp.RelativeOffsetFromImpact = Math::RInterpShortestPathTo(
			HoverComp.RelativeOffsetFromImpact,
			FRotator::ZeroRotator,
			DeltaTime,
			5
		);

		HoverComp.ApplyLocationAndRotation();
	}

	void TickRemote(float DeltaTime)
	{
		HoverComp.ApplyCrumbSyncedLocationAndRotation();
	}

	void Pitch(float DeltaTime)
	{
		if(GravityBike.IsAirborne.Get())
		{
			// When airborne, just accelerate to 0 pitch
			HoverComp.AccPitch.SpringTo(0, 10, 0.5, DeltaTime);
		}
		else
		{
			if(Math::Abs(HoverComp.AccPitch.Value) > KINDA_SMALL_NUMBER || Math::Abs(HoverComp.AccPitch.Velocity) > 10)
			{
				HoverComp.AccPitch.Velocity += (HoverComp.Settings.PitchAcceleration * DeltaTime) * -Math::Sign(HoverComp.AccPitch.Value);
				HoverComp.AccPitch.Value += HoverComp.AccPitch.Velocity * DeltaTime;
			}
			else
			{
				HoverComp.AccPitch.SnapTo(0, 0);
			}
			//HoverComp.AccPitch.SpringTo(0, HoverComp.Settings.PitchStiffness, HoverComp.Settings.PitchDamping, DeltaTime);

			if(HoverComp.Settings.bBounceWhenGrounded)
			{
				if(HoverComp.AccPitch.Value < 0)
				{
					if(Math::Abs(HoverComp.AccPitch.Velocity) < HoverComp.Settings.PitchMinVelocityToBounce || HoverComp.PitchBounceCount >= (HoverComp.Settings.MaxBounces - 1))
					{
						// Stop bouncing
						HoverComp.AccPitch.SnapTo(0);
					}
					else
					{
						// Bounce
						HoverComp.AccPitch.SnapTo(0, HoverComp.AccPitch.Velocity * -(HoverComp.Settings.PitchBonceRestitution));
						HoverComp.PitchBounceCount++;
					}
				}
			}
		}
	}

	void Yaw(float DeltaTime)
	{
		HoverComp.AccYaw.AccelerateTo(0, 0.5, DeltaTime);
	}

	void Roll(float DeltaTime)
	{
		if(GravityBike.IsAirborne.Get())
		{
			const float TargetRoll = GravityBike.Input.GetSteering() * -HoverComp.Settings.AirRollAmount;
			HoverComp.AccRoll.SpringTo(TargetRoll, HoverComp.Settings.RollStiffness, HoverComp.Settings.RollDamping, DeltaTime);
		}
		else if(MoveComp.GetSteeringWallHit().IsValidBlockingHit())
		{
			HoverComp.AccRoll.AccelerateTo(0, 0.1, DeltaTime);
		}
		else
		{
			float TargetRoll = -GravityBike.SteeringComp.GetSteerAlpha(GravityBike.GetForwardSpeed(), false) * HoverComp.Settings.MaxRoll;

			if(GravityBike.IsTurnReferenceDelayBlocked() && Math::IsNearlyZero(TargetRoll))
			{
				const float AngularSpeed = GravityBike.AngularVelocity.DotProduct(GravityBike.AccGlobalUp.Value.UpVector);
				const float MaxTurnSpeed = Math::DegreesToRadians(GravityBike.SteeringComp.GetMaxSteerAngleDeg(GravityBike.GetForwardSpeed()));
				float AngularAlpha = AngularSpeed / MaxTurnSpeed;
				AngularAlpha = Math::Clamp(AngularAlpha, -1, 1);
				TargetRoll -= AngularAlpha * HoverComp.Settings.MaxRoll;
			}

			TargetRoll = Math::Clamp(TargetRoll, -HoverComp.Settings.MaxRoll, HoverComp.Settings.MaxRoll);

			HoverComp.AccRoll.SpringTo(TargetRoll, HoverComp.Settings.RollStiffness, HoverComp.Settings.RollDamping, DeltaTime);
		}
	}

	UFUNCTION()
	private void OnHitImpactResponseComponent(UGravityBikeSplineImpactResponseComponent ResponseComp, FGravityBikeSplineOnImpactData ImpactData)
	{
		if(ResponseComp.PitchImpulseMultiplier < KINDA_SMALL_NUMBER)
			return;

		FVector ImpactVelocity = ImpactData.Velocity.ProjectOnToNormal(-ImpactData.Normal);
		ImpactVelocity *= HoverComp.Settings.ImpactPitchMultiplier * ResponseComp.PitchImpulseMultiplier;

		HoverComp.AddRotationalImpulse(ImpactVelocity);
	}
}
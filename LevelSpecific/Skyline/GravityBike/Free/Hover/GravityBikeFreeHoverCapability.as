class UGravityBikeFreeHoverCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeHover);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeHoverComponent HoverComp;
	UGravityBikeFreeMovementComponent MoveComp;

	FQuat PreviousRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		HoverComp = UGravityBikeFreeHoverComponent::Get(GravityBike);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);

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
		HoverComp.Reset();
		
		if(HasControl())
			GravityBike.OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(HasControl())
			GravityBike.OnTeleported.Unbind(this, n"OnTeleported");
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
			GravityBikeFree::WallImpact::WallImpactRotationOffsetDecreaseFactor
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
		auto KartDriftComp = UGravityBikeFreeKartDriftComponent::Get(GravityBike);

		if(KartDriftComp.IsDriftJumping())
		{
			const float TargetRoll = KartDriftComp.GetSteerIntoDriftFactor(false) * KartDriftComp.Settings.JumpYawOffset;
			HoverComp.AccYaw.AccelerateTo(TargetRoll, 0.5, DeltaTime);
		}
		else if(KartDriftComp.IsDrifting())
		{
			const float TargetRoll = KartDriftComp.GetSteerIntoDriftFactor(false) * KartDriftComp.Settings.DriftYawOffset;
			HoverComp.AccYaw.AccelerateTo(TargetRoll, KartDriftComp.Settings.DriftYawAccelerateDuration, DeltaTime);
		}
		else
		{
			HoverComp.AccYaw.AccelerateTo(0, 0.5, DeltaTime);
		}
	}

	void Roll(float DeltaTime)
	{
		if(GravityBike.IsKartDrifting())
		{
			// When kart drifting, only roll into the turn, never out
			auto KartDriftComp = UGravityBikeFreeKartDriftComponent::Get(GravityBike);
			const float TargetRoll = KartDriftComp.GetSteerIntoDriftFactor(false) * -GravityBikeFree::KartDrift::MaxTilt;
			HoverComp.AccRoll.SpringTo(TargetRoll, GravityBikeFree::KartDrift::TiltStiffness, GravityBikeFree::KartDrift::TiltDamping, DeltaTime);
		}
		else if(GravityBike.IsAirborne.Get())
		{
			const float TargetRoll = GravityBike.Input.Steering * -HoverComp.Settings.AirRollAmount;
			HoverComp.AccRoll.SpringTo(TargetRoll, HoverComp.Settings.RollStiffness, HoverComp.Settings.RollDamping, DeltaTime);
		}
		else
		{
			const float TargetRoll = -GravityBike.GetSteerAlpha(MoveComp.GetForwardSpeed(), false) * HoverComp.Settings.MaxRoll;
			HoverComp.AccRoll.SpringTo(TargetRoll, HoverComp.Settings.RollStiffness, HoverComp.Settings.RollDamping, DeltaTime);
		}
	}

	UFUNCTION()
	private void OnHitImpactResponseComponent(UGravityBikeFreeImpactResponseComponent ResponseComp, FGravityBikeFreeOnImpactData ImpactData)
	{
		if(ResponseComp.PitchImpulseMultiplier < KINDA_SMALL_NUMBER)
			return;

		FVector ImpactVelocity = ImpactData.Velocity.ProjectOnToNormal(-ImpactData.Normal);
		ImpactVelocity *= HoverComp.Settings.ImpactPitchMultiplier * ResponseComp.PitchImpulseMultiplier;

		HoverComp.AddRotationalImpulse(-ImpactVelocity);
	}

	UFUNCTION()
	private void OnTeleported()
	{
		check(HasControl());

		HoverComp.AccPitch.SnapTo(0);
		HoverComp.AccYaw.SnapTo(0);
		HoverComp.AccRoll.SnapTo(0);

		HoverComp.SyncedHoverDataComp.SnapRemote();
	}
}
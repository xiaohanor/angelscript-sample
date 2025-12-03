class UTundraPlayerFairyLeapingMovementCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLeap);
	default CapabilityTags.Add(PlayerMovementTags::AirJump);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::Fairy);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	UTundraPlayerFairyComponent FairyComp;
	UTundraPlayerFairySettings Settings;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	bool bStartedFalling = false;
	float TimeOfStartFalling = -100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!FairyComp.bIsLeaping)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!FairyComp.bIsLeaping)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bStartedFalling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			float CurrentHeightLossSpeed = FairyComp.GetCurrentHeightLossSpeed();
			FairyComp.HeightOfLeapSession -= CurrentHeightLossSpeed * DeltaTime;
	
			FairyComp.TemporalLogLeapStuff();

			if(HasControl())
			{
				if(!Settings.bInheritVelocityWhenStartingLeap)
					Movement.AddOwnerVerticalVelocity();

				float CurrentLeapSpeed = Settings.LeapHorizontalSpeed;
				if(Settings.bEnableLeapPrecisionMode)
				{
					FVector NormalizedLeapDirection = FairyComp.LeapDirection.GetSafeNormal();
					FRotator ViewRotation = Player.GetViewRotation();
					ViewRotation.Pitch = 0.0;
					CurrentLeapSpeed = Settings.LeapHorizontalSpeed * Math::Max(Settings.LeapPrecisionLowestMultiplier, ViewRotation.ForwardVector.DotProduct(NormalizedLeapDirection));

					FairyComp.LeapAirControlVelocity += MoveComp.MovementInput * FairyComp.GetAccelerationWithDrag(DeltaTime, Settings.LeapPrecisionHorizontalAirFriction, Settings.LeapPrecisionHorizontalAirControlMaxSpeed) * DeltaTime;
					float Dot = NormalizedLeapDirection.DotProduct(FairyComp.LeapAirControlVelocity);
					float MaxAirControlSpeedInLeapDirection = Settings.LeapHorizontalSpeed - CurrentLeapSpeed;
					if(Dot > MaxAirControlSpeedInLeapDirection)
						FairyComp.LeapAirControlVelocity -= FairyComp.LeapDirection * (Dot - MaxAirControlSpeedInLeapDirection);
				}
				ApplyAirControlFriction(DeltaTime);

				Movement.AddHorizontalVelocity(FairyComp.LeapDirection * CurrentLeapSpeed);
				Movement.AddHorizontalVelocity(FairyComp.LeapAirControlVelocity);

				if(Settings.bInheritVelocityWhenStartingLeap)
				{
					FairyComp.LeapAdditionalVelocity += MoveComp.GetPendingImpulse();
					ApplyAdditionalVelocityFriction(DeltaTime);
					Movement.AddVelocity(FairyComp.LeapAdditionalVelocity);
				}

				float CurrentGravity = MoveComp.GravityForce;

				const float VerticalSpeed = Settings.bInheritVelocityWhenStartingLeap ? FairyComp.LeapVerticalVelocity.DotProduct(MoveComp.WorldUp) : MoveComp.VerticalSpeed;
				if(!bStartedFalling && VerticalSpeed < 0.0)
				{
					bStartedFalling = true;
					TimeOfStartFalling = Time::GetGameTimeSeconds();
				}

				if(bStartedFalling)
					CurrentGravity *= Settings.LeapHangTimeCurve.GetFloatValue(Math::Clamp((Time::GetGameTimeSeconds() - TimeOfStartFalling) / Settings.HangTimeTransitionDuration, 0.0, 1.0));

				if(Settings.bInheritVelocityWhenStartingLeap)
				{
					FairyComp.LeapVerticalVelocity -= MoveComp.WorldUp * (CurrentGravity * DeltaTime);
					Movement.AddVerticalVelocity(FairyComp.LeapVerticalVelocity);
				}
				else
					Movement.AddVerticalVelocity(MoveComp.WorldUp * (-CurrentGravity * DeltaTime));

				RotateMesh();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");

			if(Player.ActorLocation.Z < FairyComp.HeightOfLeapSession - Settings.LowHeightBeforeLosingHeight)
			{
				FairyComp.HeightOfLeapSession = Player.ActorLocation.Z + Settings.LowHeightBeforeLosingHeight;
			}
		}
	}

	void ApplyAirControlFriction(float DeltaTime)
    {
        FVector AirDragVelocityDelta = FairyComp.GetFrameRateIndependentDrag(FairyComp.LeapAirControlVelocity, Settings.LeapPrecisionHorizontalAirFriction, DeltaTime);
        FairyComp.LeapAirControlVelocity += AirDragVelocityDelta;
    }

	void RotateMesh()
	{
		if(!MoveComp.HorizontalVelocity.IsNearlyZero())
			Movement.InterpRotationTo(MoveComp.HorizontalVelocity.ToOrientationQuat(), Settings.LeapingFairyInterpSpeed);
	}

	void ApplyAdditionalVelocityFriction(float DeltaTime)
	{
		FVector HorizontalAdditional = FairyComp.LeapAdditionalVelocity.VectorPlaneProject(MoveComp.WorldUp);
		float VerticalSpeed = FairyComp.LeapAdditionalVelocity.DotProduct(MoveComp.WorldUp);

		FVector AdditionalVelocityDelta = FairyComp.GetFrameRateIndependentDrag(HorizontalAdditional, FairyComp.GetAirFrictionValue(), DeltaTime);
		FairyComp.LeapAdditionalVelocity += AdditionalVelocityDelta;

		if(VerticalSpeed > 0.0)
		{
			float GravityDelta = MoveComp.GravityForce * DeltaTime;
			if(GravityDelta > VerticalSpeed)
				GravityDelta = VerticalSpeed;

			FairyComp.LeapAdditionalVelocity -= MoveComp.WorldUp * GravityDelta;
		}

		FairyComp.HeightOfLeapSession += FairyComp.LeapAdditionalVelocity.DotProduct(MoveComp.WorldUp) * DeltaTime;
	}
}
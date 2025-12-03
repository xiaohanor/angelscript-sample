class UTundraPlayerFairyLeapCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 3;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerMovementTags::AirJump);
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLeap);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::Fairy);
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UTundraPlayerFairySettings Settings;
	UTundraPlayerFairyComponent FairyComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!FairyComp.bIsActive)
			return false;

		if(MoveComp.HasGroundContact())
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, Settings.JumpInputQueuingDuration) && !FairyComp.bFairyLeapAfterShapeshifting)
			return false;

		if(Settings.MaxAmountOfLeaps >= 0 && FairyComp.AmountOfLeaps >= Settings.MaxAmountOfLeaps)
			return false;

		if(Time::GetGameTimeSeconds() - FairyComp.TimeOfLastLeap < Settings.LeapCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
		FairyComp.HeightOfLastLeap = Player.ActorLocation.Z;
		FairyComp.bFairyLeapAfterShapeshifting = false;
		FairyComp.FrameOfLeap = Time::FrameNumber;

		if(!FairyComp.bIsLeaping)
		{
			FairyComp.bIsLeaping = true;
			FairyComp.HeightOfLeapSession = Player.ActorLocation.Z;
			FairyComp.SnapFairyLeapHeightLossSpeed();

			// If we don't do this the player can gain an infinite amount of height by spam shapeshifting to fairy (since it jumps when shapeshifting to fairy)
			if(!FairyComp.bResetLeapSession && FairyComp.HeightOfLeapSession > FairyComp.LastLeapSessionHeight)
				FairyComp.HeightOfLeapSession = FairyComp.LastLeapSessionHeight;

			FairyComp.HighestHeightOfLeapSession = FairyComp.HeightOfLeapSession;

			if(FairyComp.bResetLeapSession)
				FairyComp.LeapSessionDuration = 0.0;

			if(Settings.bInheritVelocityWhenStartingLeap)
			{
				FVector AdditionalVelocity = MoveComp.GetPendingImpulse() + MoveComp.Velocity;

				FVector AdditionalHorizontalVelocity = AdditionalVelocity.ConstrainToPlane(MoveComp.WorldUp);
				FVector AdditionalVerticalVelocity = AdditionalVelocity.ProjectOnToNormal(MoveComp.WorldUp);

				float HorizontalVelocitySize = AdditionalHorizontalVelocity.Size();
				float HorizontalSizeLeft = HorizontalVelocitySize - Settings.LeapHorizontalSpeed;
				FairyComp.LeapAdditionalVelocity = FVector::ZeroVector;

				if(AdditionalVerticalVelocity.DotProduct(MoveComp.WorldUp) > 0.0)
					FairyComp.LeapAdditionalVelocity = AdditionalVerticalVelocity;

				if(HorizontalSizeLeft > 0.0)
				{
					FairyComp.LeapAdditionalVelocity += AdditionalHorizontalVelocity.GetSafeNormal() * HorizontalSizeLeft;
				}
			}
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			FairyComp.TimeOfLastLeap = Time::GetGameTimeSeconds();
			++FairyComp.AmountOfLeaps;

			float CurrentHeightLossSpeed = FairyComp.GetCurrentHeightLossSpeed();
			FairyComp.HeightOfLeapSession -= CurrentHeightLossSpeed * DeltaTime;

			FairyComp.TemporalLogLeapStuff();

			if(HasControl())
			{
				Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

				if(!Settings.bInheritVelocityWhenStartingLeap)
					Movement.AddOwnerVerticalVelocity();

				FairyComp.LeapDirection = MoveComp.MovementInput;
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
				
				HandleLeapVerticalVelocity(DeltaTime);

				if(!Settings.bInheritVelocityWhenStartingLeap)
					Movement.AddGravityAcceleration();
				
				RotateMesh();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
			FTundraPlayerFairyLeapParams Params;
			Params.bLeapToRight = FairyComp.AmountOfLeaps % 2 == 0;
			UTundraPlayerFairyEffectHandler::Trigger_OnLeaped(FairyComp.FairyActor, Params);
		}
	}

	void HandleLeapVerticalVelocity(float DeltaTime)
	{
		float DeltaToMaxHeightGain = (FairyComp.HeightOfLeapSession + Settings.MaxHeightGain) - Player.ActorLocation.Z;

		if(DeltaToMaxHeightGain < 0.0)
		{
			const float Multiplier = (1.0 - Math::Min(-DeltaToMaxHeightGain / Settings.MaxHeightGain, 1.0));
			if(Settings.bInheritVelocityWhenStartingLeap)
			{
				float VerticalSpeed = FairyComp.LeapVerticalVelocity.DotProduct(MoveComp.WorldUp);
				FairyComp.LeapVerticalVelocity += MoveComp.WorldUp * -VerticalSpeed * Multiplier;
				FairyComp.LeapVerticalVelocity -= MoveComp.WorldUp * (MoveComp.GravityForce * DeltaTime);
				Movement.AddVerticalVelocity(FairyComp.LeapVerticalVelocity);
			}
			else
				Movement.AddVerticalVelocity(MoveComp.WorldUp * -MoveComp.VerticalSpeed * Multiplier);
			
			return;
		}

		// Based on calculate maximum height formula: h=v²/(2g), rearranged to solve for upwards speed based on max height and gravity: v=sqrt(h*2g)
		float TargetSpeed = Math::Sqrt(DeltaToMaxHeightGain * MoveComp.GetGravityForce() * 2);

		// This math is not 100 % accurate but it is a good enough approximation
		float SecsToReachHeight = DeltaToMaxHeightGain / TargetSpeed;
		float CurrentHeightLossSpeed = FairyComp.GetCurrentHeightLossSpeed();
		float HeightLossOverSecs = CurrentHeightLossSpeed * SecsToReachHeight;

		if(DeltaToMaxHeightGain - HeightLossOverSecs < 0.0)
		{
			const float Multiplier = (1.0 - Math::Min(-DeltaToMaxHeightGain / Settings.MaxHeightGain, 1.0));
			if(Settings.bInheritVelocityWhenStartingLeap)
			{
				float VerticalSpeed = FairyComp.LeapVerticalVelocity.DotProduct(MoveComp.WorldUp);
				FairyComp.LeapVerticalVelocity += MoveComp.WorldUp * -VerticalSpeed * Multiplier;
				FairyComp.LeapVerticalVelocity -= MoveComp.WorldUp * (MoveComp.GravityForce * DeltaTime);
				Movement.AddVerticalVelocity(FairyComp.LeapVerticalVelocity);
			}
			else
				Movement.AddVerticalVelocity(MoveComp.WorldUp * -MoveComp.VerticalSpeed * Multiplier);
			
			return;
		}
		
		TargetSpeed = Math::Sqrt((DeltaToMaxHeightGain - HeightLossOverSecs) * MoveComp.GetGravityForce() * 2);

		if(Settings.bInheritVelocityWhenStartingLeap)
		{
			float VerticalSpeed = FairyComp.LeapVerticalVelocity.DotProduct(MoveComp.WorldUp);
			FairyComp.LeapVerticalVelocity += MoveComp.WorldUp * (TargetSpeed - VerticalSpeed);
			FairyComp.LeapVerticalVelocity -= MoveComp.WorldUp * (MoveComp.GravityForce * DeltaTime);
			Movement.AddVerticalVelocity(FairyComp.LeapVerticalVelocity);
		}
		else
			Movement.AddVerticalVelocity(MoveComp.WorldUp * (TargetSpeed - MoveComp.VerticalSpeed));
	}

	void RotateMesh()
	{
		if(!MoveComp.HorizontalVelocity.IsNearlyZero())
			Movement.InterpRotationTo(MoveComp.HorizontalVelocity.ToOrientationQuat(), Settings.LeapingFairyInterpSpeed);
	}

	void ApplyAirControlFriction(float DeltaTime)
    {
        FVector AirDragVelocityDelta = FairyComp.GetFrameRateIndependentDrag(FairyComp.LeapAirControlVelocity, Settings.LeapPrecisionHorizontalAirFriction, DeltaTime);
       	FairyComp.LeapAirControlVelocity += AirDragVelocityDelta;
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
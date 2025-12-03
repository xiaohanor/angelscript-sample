

// Internal settings for the point of interest
struct FApplyClampPointOfInterestSettings
{
	/** How fast we wan't to face the clamps. 
	 * If < 0, the blend time will be used.
	 */ 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	float TurnTime = 0;

	// How fast we near the desired view rotation.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	ECameraPointOfInterestAccelerationType BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Fast;

	// If true, look in the same direction as the focus target forward instead of looking 'at' focus target
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	bool bMatchFocusDirection = false;

	// Point of interest turn scaling, in case we don't want to apply turn around some axes as fast as others. Values should be 0..1.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	FRotator TurnScaling = FRotator(1, 1, 1);

	// For how long the point of interest should be active. -1 it will remain until manually cleared.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings")
	float Duration = -1;

	// If true, we will remove point of interest if we're looking close to POI and player starts giving input.	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	UCameraPointOfInterestClearOnInputSettings ClearOnInput = nullptr;

	/**
	 * Multiplier to the turn rate sensitivity while in this POI.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	float InputTurnRateMultiplier = 1.0;

	/**
	 * Strength of the counter force that is always pulling the camera back to the middle of the clamp
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	float InputCounterForce = 0.0;

	/** 
	 * How long until we start turning towards the target.
	 * Only used if >= 0
	 */ 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", meta=(ClampMax=2), AdvancedDisplay)
	float DelayTime = 0.0;

	// if true, the forward direction for the clamps will be the target components forward, else the forward will be the direction towards the target
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "PointOfInterest", AdvancedDisplay)
	bool bUseFocusTargetComponentForClamps = true;

	// Force camera to turn towards given point, then allow player to turn away from it within clamps
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "PointOfInterest")
	bool bForceDuringBlendIn = false;

	// If true, the 'Find other player' input is blocked while the poi is active
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", AdvancedDisplay)
	bool bBlockFindAtOtherPlayer = true;

	/** 
	 * Within this percentage of the clamps, the camera is allowed to move fully freely.
	 * Once we go above this percentage of the clamps, the camera will reset back to the middle after
	 * not giving input for the DelayTime.
	 */ 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", meta=(ClampMin=0, ClampMax=1), AdvancedDisplay)
	float ClampFullFreedomAnglePercentage = 0;
}

/**
 * A clamped point of interest.
 * Will look at the target.
 * Can be set to be cleared if input is give.
 * Can be set to pause when input is given
 */
class UCameraPointOfInterestClamped : UHazePointOfInterestBase
{
	FHazePointOfInterestFocusTargetInfo FocusTarget;
	FApplyClampPointOfInterestSettings Settings;
	FHazeCameraClampSettings Clamps;
	USceneComponent FocusComponent;

	protected float TimeSinceLastInput = 0;
	protected FHazeAcceleratedFloat LocalOffsetFromYawInput;
	protected FHazeAcceleratedFloat LocalOffsetFromPitchInput;

	protected FPointOfInterestClearOnInput ClearOnInput;
	protected float DurationTimeLeft = 0;
	protected float BlendTime = 0;
	protected float ActiveDuration = 0;

	protected bool bTriggeredBackToCenter = false;

	protected FHazeAcceleratedFloat TurnSpeed;
	protected FRotator FocusTargetRotation;

	protected FHazeActiveCameraClampSettings ActiveClamps;

	UFUNCTION(BlueprintOverride)
	protected void OnActivated(UHazeCameraUserComponent HazeUser, FInstigator Instigator, float Blend)
	{
		auto User = Cast<UCameraUserComponent>(HazeUser);
		ClearOnInput = FPointOfInterestClearOnInput(Settings.ClearOnInput, User.PlayerOwner);

		// Override the clamps center component with the focus target component
		FocusComponent = nullptr;
		if(Settings.bUseFocusTargetComponentForClamps)
		{
			FocusComponent = FocusTarget.GetFocusComponent(User.PlayerOwner);
			if(FocusComponent != nullptr)
				Clamps.ApplyComponentBasedCenterOffset(FocusComponent);
		}

		BlendTime = Math::Max(Blend, 0);
		DurationTimeLeft = Settings.Duration + BlendTime; 	// Also include the blend in, in the duration
		ActiveDuration = 0;
		FocusTargetRotation = User.ViewRotation;
		TurnSpeed.SnapTo(BlendTime);
		ActiveClamps = Clamps.GetSettings(User);
		LocalOffsetFromYawInput.SnapTo(0);
		LocalOffsetFromPitchInput.SnapTo(0);

		if(Settings.bBlockFindAtOtherPlayer)
		{
			User.PlayerOwner.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	protected void OnDeactivated(UHazeCameraUserComponent HazeUser, FInstigator Instigator)
	{
		auto User = Cast<UCameraUserComponent>(HazeUser);

		if(Settings.bBlockFindAtOtherPlayer)
		{
			User.PlayerOwner.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	protected FRotator GetTargetRotation(FHazeCameraTransform CameraTransform) const
	{
		FRotator HerculePOIrot = CameraTransform.WorldToLocalRotation(FocusTargetRotation);
		FRotator CurDesiredRot = CameraTransform.LocalDesiredRotation;
		FRotator TargetDeltaRotation = CurDesiredRot;

		TargetDeltaRotation.Yaw = GetYawByTurnDirection(HerculePOIrot.Yaw, CurDesiredRot.Yaw);
		TargetDeltaRotation.Pitch = CurDesiredRot.Pitch + FRotator::NormalizeAxis(HerculePOIrot.Pitch - CurDesiredRot.Pitch);
		TargetDeltaRotation = GetTurnScaledToRotation(TargetDeltaRotation - CurDesiredRot);

		const FRotator TargetRotation = CameraTransform.LocalToWorldRotation(CurDesiredRot + TargetDeltaRotation);
		return TargetRotation;
	}

	UFUNCTION(BlueprintOverride)
	protected FRotator GetLocalRotationOffset(FHazeCameraTransform CameraTransform) const
	{
		return FRotator(LocalOffsetFromPitchInput.Value, LocalOffsetFromYawInput.Value, 0);
	}

	UFUNCTION(BlueprintOverride)
	protected void TickActive(UHazeCameraUserComponent HazeUser, float DeltaTime)
	{
		auto User = Cast<UCameraUserComponent>(HazeUser);

		const float CameraDeltaTime = Time::CameraDeltaSeconds;
		ActiveDuration += CameraDeltaTime;
		const FVector2D AxisInput = User.PlayerOwner.GetCameraInput();

		if(Settings.Duration >= 0)
			DurationTimeLeft -= CameraDeltaTime;
		
		const FRotator NewTargetRotation = FocusTarget.GetFocusRotation(User.PlayerOwner, Settings.bMatchFocusDirection);

		// Update the clamps to be around the direction to the focus point
		if(FocusComponent == nullptr)
		{
			FVector FocusLocation = FocusTarget.GetFocusLocation(User.PlayerOwner);
			FVector Forward = (FocusLocation - User.PlayerOwner.ActorLocation).VectorPlaneProject(User.ActiveCameraYawAxis);
			Clamps.ApplyWorldSpaceCenterOffset(FRotator::MakeFromZX(User.ActiveCameraYawAxis, Forward));
		}

		ActiveClamps = Clamps.GetSettings(User);

		// How fast should we be turning towards the poi
		FocusTargetRotation = NewTargetRotation;

		// Record how long since we've had input
		if (AxisInput.Size() > 0.05)
			TimeSinceLastInput = 0.0;
		else
			TimeSinceLastInput += DeltaTime;

		// We force the focus rotation during activation
		if(!(Settings.bForceDuringBlendIn && ActiveDuration <= BlendTime && BlendTime > 0))
		{
			// Should we stop the poi when giving input
			ClearOnInput.Update(NewTargetRotation, AxisInput, User);

			float Duration = TurnSpeed.AccelerateTo(TargetTurnSpeed, BlendTime, CameraDeltaTime);

			FRotator TurnRate = User.GetCameraTurnRate() * Settings.InputTurnRateMultiplier;

			FRotator DeltaRotation = User.CalculateAndUpdateInputDeltaRotation(AxisInput, TurnRate, false);

			// As we approach the edges of the clamp, lower the turn rate of the camera
			if (DeltaRotation.Yaw < 0 && LocalOffsetFromYawInput.Value < 0)
			{
				DeltaRotation.Yaw *= Math::GetMappedRangeValueClamped(
					FVector2D(-ActiveClamps.YawLeft.Value, -0.5 * ActiveClamps.YawLeft.Value),
					FVector2D(0, 1),
					LocalOffsetFromYawInput.Value
				);
			}
			else if (DeltaRotation.Yaw > 0 && LocalOffsetFromYawInput.Value > 0)
			{
				DeltaRotation.Yaw *= Math::GetMappedRangeValueClamped(
					FVector2D(ActiveClamps.YawRight.Value, 0.5 * ActiveClamps.YawRight.Value),
					FVector2D(0, 1),
					LocalOffsetFromYawInput.Value
				);
			}

			if (DeltaRotation.Pitch < 0 && LocalOffsetFromPitchInput.Value < 0)
			{
				DeltaRotation.Pitch *= Math::GetMappedRangeValueClamped(
					FVector2D(-ActiveClamps.PitchUp.Value, -0.5 * ActiveClamps.PitchUp.Value),
					FVector2D(0, 1),
					LocalOffsetFromPitchInput.Value
				);
			}
			else if (DeltaRotation.Pitch > 0 && LocalOffsetFromPitchInput.Value > 0)
			{
				DeltaRotation.Pitch *= Math::GetMappedRangeValueClamped(
					FVector2D(ActiveClamps.PitchDown.Value, 0.5 * ActiveClamps.PitchDown.Value),
					FVector2D(0, 1),
					LocalOffsetFromPitchInput.Value
				);
			}

			// Yaw offset
			if (Math::Abs(AxisInput.X) > SMALL_NUMBER)
			{
				LocalOffsetFromYawInput.SnapTo(Math::Clamp(
					LocalOffsetFromYawInput.Value + DeltaRotation.Yaw,
					-ActiveClamps.YawLeft.Value,
					ActiveClamps.YawRight.Value,
				));
				bTriggeredBackToCenter = false;

				// Apply the counter force
				if (Settings.InputCounterForce > 0)
				{
					LocalOffsetFromYawInput.SnapTo(
						LocalOffsetFromYawInput.Value * Math::Pow(Math::Exp(-Settings.InputCounterForce), DeltaTime)
					);
				}
			}
			else if (TimeSinceLastInput >= Settings.DelayTime)
			{
				if (LocalOffsetFromYawInput.Value < -ActiveClamps.YawLeft.Value * Settings.ClampFullFreedomAnglePercentage)
					bTriggeredBackToCenter = true;
				if (LocalOffsetFromYawInput.Value > ActiveClamps.YawLeft.Value * Settings.ClampFullFreedomAnglePercentage)
					bTriggeredBackToCenter = true;

				if (bTriggeredBackToCenter)
				{
					LocalOffsetFromYawInput.AccelerateTo(0, Duration, CameraDeltaTime);
					if (Math::IsNearlyEqual(LocalOffsetFromYawInput.Value, 0))
						bTriggeredBackToCenter = false;
				}
			}

			// Pitch offset
			if (Math::Abs(AxisInput.Y) > SMALL_NUMBER)
			{
				LocalOffsetFromPitchInput.SnapTo(Math::Clamp(
					LocalOffsetFromPitchInput.Value + DeltaRotation.Pitch,
					-ActiveClamps.PitchUp.Value,
					ActiveClamps.PitchDown.Value,
				));
				bTriggeredBackToCenter = false;

				// Apply the counter force
				if (Settings.InputCounterForce > 0)
				{
					LocalOffsetFromPitchInput.SnapTo(
						LocalOffsetFromPitchInput.Value * Math::Pow(Math::Exp(-Settings.InputCounterForce), DeltaTime)
					);
				}
			}
			else if (TimeSinceLastInput >= Settings.DelayTime)
			{
				if (LocalOffsetFromPitchInput.Value < -ActiveClamps.PitchUp.Value * Settings.ClampFullFreedomAnglePercentage)
					bTriggeredBackToCenter = true;
				if (LocalOffsetFromPitchInput.Value > ActiveClamps.PitchDown.Value * Settings.ClampFullFreedomAnglePercentage)
					bTriggeredBackToCenter = true;

				if (bTriggeredBackToCenter)
				{
					LocalOffsetFromPitchInput.AccelerateTo(0, Duration, CameraDeltaTime);
					if (Math::IsNearlyEqual(LocalOffsetFromPitchInput.Value, 0))
						bTriggeredBackToCenter = false;
				}
			}
		}
		else if (Settings.ClearOnInput.bClearDurationOverridesBlendIn)
		{
			// Check for poi clear through input if override is active
			ClearOnInput.Update(NewTargetRotation, AxisInput, User);
		}
	}

	UFUNCTION(BlueprintOverride)
	protected bool IsValid() const
	{
		if(!FocusTarget.IsValid())
			return false;

		if(Settings.Duration >= 0 && DurationTimeLeft <= 0)
			return false;

		if (ClearOnInput.ShouldClear())
			return false;

		return true;
	}

	protected float GetYawByTurnDirection(float POIYaw, float CurrentYaw) const
	{
		float Delta = (CurrentYaw - POIYaw); // Non-normalized delta
		float ShortestPathYaw = CurrentYaw - FRotator::NormalizeAxis(Delta); 
	
		// Use shortest route if currently within clamps
		if ((ActiveClamps.YawRight.Value > Delta) && (ActiveClamps.YawLeft.Value > -Delta))
			return ShortestPathYaw;

		return ShortestPathYaw;
	}

	protected FRotator GetTurnScaledToRotation(FRotator Rotator) const
	{
		FRotator Result = Rotator.GetNormalized();
		Result.Yaw *= Settings.TurnScaling.Yaw;
		Result.Pitch *= Settings.TurnScaling.Pitch;
		Result.Roll *= Settings.TurnScaling.Roll;
		return Result;
	}

	protected float GetTargetTurnSpeed() const property
	{		
		// Negative values uses the blend time
		if(Settings.TurnTime < KINDA_SMALL_NUMBER)
			return BlendTime;
		
		return Settings.TurnTime;
	}

	UFUNCTION(BlueprintOverride)
	float GetAcceleratorLambertNominator() const
	{
		return PointOfInterest::GetAcceleratorLambertNominatorForType(Settings.BlendInAccelerationType);
	}

	UFUNCTION(BlueprintOverride)
	void GetDebugDescription(bool bIsCurrentValue, FString& Desc)
	{
		if(bIsCurrentValue)
		{
			Desc = "\n" + FocusTarget.ToString();
			if (Settings.bMatchFocusDirection)
				Desc += "\n(Matching rotation)";
		}
	}
}

// Camera will look at given point unless player gives input or if camera is outside given clamps.
mixin UCameraPointOfInterestClamped CreatePointOfInterestClamped(AHazePlayerCharacter Player)
{
	auto Out = NewObject(Player, UCameraPointOfInterestClamped);
	return Out;
}
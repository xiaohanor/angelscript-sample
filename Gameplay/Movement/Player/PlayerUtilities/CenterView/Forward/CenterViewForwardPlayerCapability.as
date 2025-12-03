/**
 * Rotates the camera to face in the player forward direction or movement input direction when LB is pressed.
 */
class UCenterViewForwardPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);

	default CapabilityTags.Add(CapabilityTags::CenterView);
	default CapabilityTags.Add(CameraTags::CenterViewRotation);
	default CapabilityTags.Add(CameraTags::CenterViewForward);

    default DebugCategory = CameraTags::Camera;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;
	default TickGroupSubPlacement = 1; // Before CameraControlCapability, after CenterViewTargetRotate

	UCenterViewPlayerComponent CenterViewComp;
	UCenterViewSettings CenterViewSettings;

	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUserComp;
	UCameraUserSettings CameraUserSettings;

	FRotator TargetRotation;
	float UpdateTargetTime = 0;
	
	FHazeAcceleratedRotator AccRotation;

	float ControlRotationLockTime = -1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
		CenterViewSettings = UCenterViewSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		CameraUserSettings = UCameraUserSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::CenterView))
			return false;

		if(!CenterViewComp.CanApplyCenterView())
			return false;

		if(CenterViewComp.HasAppliedCenterViewThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CenterViewComp.CanApplyCenterView())
			return true;

		if(CenterViewComp.HasAppliedCenterViewThisFrame())
			return true;

		// Finished rotating
		if (Time::GetRealTimeSince(UpdateTargetTime) > CenterViewSettings.TurnDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraControl, this);
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);

		AccRotation.SnapTo(CameraUserComp.GetDesiredRotation());

		TargetRotation = GetWantedRotation();
		TargetRotation = CameraUserComp.GetClampedWorldRotation(TargetRotation);

		UpdateTargetTime = Time::RealTimeSeconds;

		const FVector CurrentForward = AccRotation.Value.ForwardVector.VectorPlaneProject(CameraUserComp.ActiveCameraYawAxis).GetSafeNormal();
		const FVector TargetForward = TargetRotation.ForwardVector.VectorPlaneProject(CameraUserComp.ActiveCameraYawAxis).GetSafeNormal();
		const float RotationDot = CurrentForward.DotProduct(TargetForward);
		if(RotationDot < CenterViewSettings.LockControlRotationDotMinimum)
			LockControlRotation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::CenterView);

		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);

		if(IsControlRotationLocked())
			UnlockControlRotation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// If tap center view, update target
		if(WasActionStarted(ActionNames::CenterView) && Time::GetRealTimeSince(UpdateTargetTime) > CenterViewSettings.AllowResetDelay)
		{
			TargetRotation = GetWantedRotation();
			UpdateTargetTime = Time::RealTimeSeconds;
			LockControlRotation();
		}

		const FRotator Rotation = AccRotation.AccelerateToWithStop(
			TargetRotation,
			CenterViewSettings.TurnDuration,
			Time::GetCameraDeltaSeconds(false),
			0.05
		);

		CameraUserComp.SetDesiredRotation(Rotation, this);

		CenterViewComp.ApplyCenterView(this);

		if(IsControlRotationLocked() && ActiveDuration > CenterViewSettings.LockControlRotationDuration)
			UnlockControlRotation();
	}

	FRotator GetWantedRotation() const
	{
		FRotator Rotation = FRotator::MakeFromXZ(
			GetForwardDirection(),
			CameraUserComp.GetActiveCameraYawAxis()
		);

		switch(CenterViewSettings.PitchHandling)
		{
			case ECenterViewPitch::Zero:
				return Rotation;

			case ECenterViewPitch::SlightDown:
			{
				Rotation.Pitch = CameraUserSettings.SnapOffset.Pitch;
				return Rotation;
			}

			case ECenterViewPitch::KeepPitch:
			{
				Rotation.Pitch = CameraUserComp.GetDesiredRotation().Pitch;

				FHazeRange PitchClamp = CenterViewSettings.PitchClamp;
				PitchClamp.Min += CameraUserSettings.SnapOffset.Pitch;
				PitchClamp.Max += CameraUserSettings.SnapOffset.Pitch;

				switch(CenterViewSettings.PitchClamping)
				{
					case ECenterViewPitchClamp::DontClamp:
						break;

					case ECenterViewPitchClamp::ClampBoth:
					{
						Rotation.Pitch = PitchClamp.Clamp(Rotation.Pitch);
						break;
					}

					case ECenterViewPitchClamp::ClampOnlyUpWhenGrounded:
					{
						if(MoveComp.IsOnAnyGround())
						{
							Rotation.Pitch = PitchClamp.Clamp(Rotation.Pitch);
						}
						else
						{
							Rotation.Pitch = Math::Min(Rotation.Pitch, PitchClamp.Max);
						}
						break;
					}
				}

				return Rotation;
			}
		}
	}

	FVector GetForwardDirection() const
	{
		if(!MoveComp.MovementInput.IsNearlyZero())
			return MoveComp.MovementInput.GetSafeNormal();
		else
			return Player.ActorForwardVector;
	}

	bool IsControlRotationLocked() const
	{
		return ControlRotationLockTime > 0;
	}
	
	/**
	 * Make sure that the input goes the same world direction as where it started, because otherwise it becomes a bit weird
	 */
	void LockControlRotation()
	{
		UControlRotationSettings::SetOverrideControlRotation(Player, true, this);
		UControlRotationSettings::SetControlRotationOverride(Player, Player.ViewRotation, this);
		MoveComp.ApplyMovementInput(MoveComp.MovementInput, this, EInstigatePriority::High);

		ControlRotationLockTime = Time::RealTimeSeconds;
	}

	void UnlockControlRotation()
	{
		if(!ensure(IsControlRotationLocked()))
			return;

		UControlRotationSettings::ClearOverrideControlRotation(Player, this);
		UControlRotationSettings::ClearControlRotationOverride(Player, this);
		MoveComp.ClearMovementInput(this);
		ControlRotationLockTime = -1;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Rotation("Target Rotation", TargetRotation, Player.ActorLocation);
		TemporalLog.Value("Start Time", UpdateTargetTime);
		TemporalLog.Rotation("AccRotation", AccRotation.Value, Player.ActorLocation);
	}
#endif
};
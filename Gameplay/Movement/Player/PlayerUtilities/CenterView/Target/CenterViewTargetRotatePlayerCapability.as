/**
 * Handles rotating towards a Center View Target found by CenterViewFindTargetPlayerCapability.
 */
class UCenterViewTargetRotatePlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);

	default CapabilityTags.Add(CapabilityTags::CenterView);
	default CapabilityTags.Add(CameraTags::CenterViewRotation);
	default CapabilityTags.Add(CameraTags::CenterViewTarget);

    default DebugCategory = CameraTags::Camera;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;
	default TickGroupSubPlacement = 0; // Before CameraControlCapability

	UCenterViewPlayerComponent CenterViewComp;
	UCenterViewSettings CenterViewSettings;

	UCameraUserComponent CameraUserComp;
	UCameraUserSettings CameraUserSettings;

	FRotator TargetRotation;
	float UpdateTargetTime = 0;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
		CenterViewSettings = UCenterViewSettings::GetSettings(Player);

		CameraUserComp = UCameraUserComponent::Get(Player);
		CameraUserSettings = UCameraUserSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CenterViewComp.CanApplyCenterView())
			return false;

		if(CenterViewComp.HasAppliedCenterViewThisFrame())
			return false;

		if(!CenterViewComp.HasViewTarget())
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

		if(!CenterViewComp.HasViewTarget())
		{
			// Wait until we should have finished rotating at least once, to prevent stopping the rotation mid turn
			if (Time::GetRealTimeSince(ActiveDuration) > CenterViewSettings.TurnDuration)
				return true;
		}

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

		CenterViewComp.bIsCenteringTarget = true;
		CenterViewComp.StartCenteringTargetRealTime = Time::RealTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);

		CenterViewComp.bIsCenteringTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CenterViewComp.HasViewTarget())
		{
			switch(CenterViewSettings.LockViewTarget)
			{
				case ECenterViewLockViewTarget::NoLock:
				{
					bool bUpdateTargetRotation = false;
					if(CenterViewSettings.MinimumLockOnDuration > KINDA_SMALL_NUMBER)
						bUpdateTargetRotation = true;
					else if(WasActionStarted(ActionNames::CenterView) && Time::GetRealTimeSince(UpdateTargetTime) > CenterViewSettings.AllowResetDelay)
						bUpdateTargetRotation = true;

					if(bUpdateTargetRotation)
					{
						TargetRotation = GetWantedRotation();
						UpdateTargetTime = Time::RealTimeSeconds;
					}

					break;
				}

				case ECenterViewLockViewTarget::Hold:
				{
					bool bUpdateTargetRotation = false;
					if(CenterViewSettings.MinimumLockOnDuration > KINDA_SMALL_NUMBER)
						bUpdateTargetRotation = true;
					else if(IsActioning(ActionNames::CenterView))
						bUpdateTargetRotation = true;

					if(bUpdateTargetRotation)
					{
						// While holding, keep target centered
						TargetRotation = GetWantedRotation();
						UpdateTargetTime = Time::RealTimeSeconds;
					}
					break;
				}

				case ECenterViewLockViewTarget::Toggle:
				{
					// Keep target centered until we give input or tap again
					TargetRotation = GetWantedRotation();
					UpdateTargetTime = Time::RealTimeSeconds;
					break;
				}
			}
		}

		const FRotator Rotation = AccRotation.AccelerateToWithStop(
			TargetRotation,
			CenterViewSettings.TurnDuration,
			Time::GetCameraDeltaSeconds(false),
			0.05
		);

		CameraUserComp.SetDesiredRotation(Rotation, this);

		CenterViewComp.ApplyCenterView(this);
	}

	FRotator GetWantedRotation() const
	{
		const FVector LookTarget = CenterViewComp.CurrentCenterViewTarget.Value.Target.WorldLocation;

		FRotator Rotation = FRotator::MakeFromXZ(
			LookTarget - Player.ActorCenterLocation,
			CameraUserComp.GetActiveCameraYawAxis()
		);

		if(CenterViewSettings.bApplyPitchOffset)
			Rotation.Pitch += CameraUserSettings.SnapOffset.Pitch;
		
		return CameraUserComp.GetClampedWorldRotation(Rotation);
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
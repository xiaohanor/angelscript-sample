class UFindOtherPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);
	default CapabilityTags.Add(CapabilityTags::FindOtherPlayer);

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	const float TurnDuration = 0.45;
	const float SettingsDuration = 0.5;

	FHazeAcceleratedRotator Rotation;
	FTimerHandle IndicatorTimer;

	bool bReachedTargetRotation = false;
	bool bAffectPitch = false;

	UPlayerAimingComponent AimComp;
	UCameraUserComponent CameraUserComp;
	UOtherPlayerIndicatorComponent IndicatorComp;
	UOtherPlayerIndicatorComponent IndicatorComp_OtherPlayer;
	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		IndicatorComp = UOtherPlayerIndicatorComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::FindOtherPlayer))
			return false;
		if (Player.OtherPlayer.IsPlayerDead())
			return false;
		if (!CameraUserComp.CanControlCamera())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.OtherPlayer.IsPlayerDead())
			return true;
		if (!CameraUserComp.CanControlCamera())
			return true;

		if (!IsActioning(ActionNames::FindOtherPlayer))
		{
			if (ActiveDuration > TurnDuration * 2 || bReachedTargetRotation)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bReachedTargetRotation = false;
		IndicatorComp_OtherPlayer = UOtherPlayerIndicatorComponent::Get(Player.OtherPlayer);
		Player.BlockCapabilities(CameraTags::CameraControl, this);

		IndicatorTimer.ClearTimerAndInvalidateHandle();
		IndicatorComp.IndicatorMode.Apply(EOtherPlayerIndicatorMode::AlwaysVisible, this, EInstigatePriority::Low);

		UPlayerOutlineSettings::SetPlayerOutlineVisible(Player.OtherPlayer, true, this);

		float DistanceBetweenPlayers = Player.ActorLocation.Distance(GetWantedTargetLocation());
		bAffectPitch = DistanceBetweenPlayers > 800.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		IndicatorTimer = Timer::SetTimer(this, n"HideOtherPlayerIndicator", 5.0);
	}

	UFUNCTION()
	private void HideOtherPlayerIndicator()
	{
		if (!IsActive())
			IndicatorComp.IndicatorMode.Clear(this);
		UPlayerOutlineSettings::ClearPlayerOutlineVisible(Player.OtherPlayer, this);
	}

	FVector GetWantedTargetLocation() const
	{
		return Player.OtherPlayer.ActorLocation + IndicatorComp_OtherPlayer.IndicatorWorldOffset.Get();
	}

	FRotator GetWantedRotation() const
	{
		FVector DirectionToTarget = GetWantedTargetLocation() - Player.ViewLocation;
		if (!bAffectPitch)
		{
			DirectionToTarget = DirectionToTarget.ConstrainToPlane(CameraUserComp.GetActiveCameraYawAxis());
			if (DirectionToTarget.IsNearlyZero())
				DirectionToTarget = CameraUserComp.GetDesiredRotation().ForwardVector;
		}

		FRotator OutRotation = FRotator::MakeFromXZ(
			DirectionToTarget,
			CameraUserComp.GetActiveCameraYawAxis()
		);

		return OutRotation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Rotation.Value = CameraUserComp.GetDesiredRotation();
		
		FRotator TargetRotation = GetWantedRotation();
		FRotator ClampedTargetRotation = CameraUserComp.GetClampedWorldRotation(TargetRotation);

		// If the target rotation is clamped, (Straight above or below)
		// we can't look there at all, so we need to break out of this
		FRotator AppliedRotation = Rotation.AccelerateToWithStop(
			TargetRotation,
			Math::Saturate(TurnDuration - ActiveDuration),
			DeltaTime / Math::Max(Owner.ActorTimeDilation, 0.01),
			1.0);

		CameraUserComp.SetDesiredRotation(AppliedRotation, this);

		if (AppliedRotation.Equals(ClampedTargetRotation))
			bReachedTargetRotation = true;
	}

};
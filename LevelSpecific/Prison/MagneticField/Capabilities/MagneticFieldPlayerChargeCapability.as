struct FMagneticFieldPlayerChargeDeactivateParams
{
	bool bTransitionedToBurst = false;
};

/**
 * Handles initializing the charge up state, and then deactivates when charging has finished and activates Burst
 */
class UMagneticFieldPlayerChargeCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(PrisonTags::ExoSuit);
	default CapabilityTags.Add(ExoSuitTags::MagneticField);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UMagneticFieldPlayerComponent PlayerComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.GetChargeState() != EMagneticFieldChargeState::None)
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		// if (!ForceFeedback::IsTriggerEffectActioning(Player, EHazeGamepadTrigger::RightTrigger))
			// return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMagneticFieldPlayerChargeDeactivateParams& Params) const
	{
		if(PlayerComp.GetChargeState() == EMagneticFieldChargeState::Burst)
		{
			Params.bTransitionedToBurst = true;
			return true;
		}

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.SetChargeState(EMagneticFieldChargeState::Charging);
		UMagneticFieldEventHandler::Trigger_StartedCharging(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMagneticFieldPlayerChargeDeactivateParams Params)
	{
		if(!Params.bTransitionedToBurst)
		{
			// If we did not successfully charge, reset.
			PlayerComp.ResetCharge();
		}

		Player.ClearCameraSettingsByInstigator(this, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float ChargeDuration = PlayerComp.GetChargeDuration();

		if (Player.IsMovementCameraBehaviorEnabled())
		{
			float FoV = Math::Lerp(0.0, -5.0, ActiveDuration / Math::Max(ChargeDuration, MagneticField::ChargeDurationAirborne));
			UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(FoV, this);
		}

		if (ActiveDuration > ChargeDuration/3.0)
			Player.SetFrameForceFeedback(0.1, 0.0, 0.1, 0.0);
		else
			Player.SetFrameForceFeedback(0.0, 0.1, 0.0, 0.1);
	}
}
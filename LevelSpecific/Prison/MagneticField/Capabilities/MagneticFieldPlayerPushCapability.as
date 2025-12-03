/**
 * Charges magnetic field, and then releases a burst impulse.
 * If PrimaryLevelAbility is held, a force is applied to magnetic objects in proximity.
 */
class UMagneticFieldPlayerPushCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(PrisonTags::ExoSuit);
	default CapabilityTags.Add(ExoSuitTags::MagneticField);
	default CapabilityTags.Add(n"MagneticFieldPush");

	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 80;

	UMagneticFieldPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if (PlayerComp.GetChargeState() != EMagneticFieldChargeState::Burst)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.SetChargeState(EMagneticFieldChargeState::Pushing);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.ResetCharge();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PlayerComp.PushMagnetizeNearbyActors();

		float LeftFF = Math::Sin(ActiveDuration * MagneticField::ForceFeedbackFrequency) * MagneticField::ForceFeedbackIntensity;
		float RightFF = Math::Sin(-ActiveDuration * MagneticField::ForceFeedbackFrequency) * MagneticField::ForceFeedbackIntensity;
		float TriggerFF = Math::Sin((ActiveDuration + 0.8) * MagneticField::ForceFeedbackFrequency) * MagneticField::ForceFeedbackIntensity;
		Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, TriggerFF);
	}
}
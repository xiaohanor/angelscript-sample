
struct FMedallionPlayerDashCapabilityActivationParams
{
	bool bRightDash = true;
}
class UMedallionPlayerFlyingDashCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::AirDash);
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);

	default TickGroup = EHazeTickGroup::Gameplay;
	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;
	UPlayerAirDashComponent AirDashComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Owner);
		AirDashComp = UPlayerAirDashComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionPlayerDashCapabilityActivationParams & ActivationParams) const
	{
		if (!Player.IsAnyCapabilityActive(MedallionTags::MedallionCoopFlyingActive))
			return false;
		if (DeactiveDuration < MedallionConstants::Flying::DashCooldown)
			return false;
		bool bYouAreDashingToday = WasActionStartedDuringTime(ActionNames::MovementDash, AirDashComp.Settings.InputBufferWindow);
#if !RELEASE
		if (DevTogglesMovement::Dash::AutoAlwaysDash.IsEnabled(Player))
			bYouAreDashingToday = true;
#endif
		if (bYouAreDashingToday)
		{
			const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			ActivationParams.bRightDash = RawStick.Y < 0.0;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionPlayerDashCapabilityActivationParams ActivationParams)
	{
		AirMoveDataComp.AccDashAlpha.SnapTo(1.0);
		AirMoveDataComp.BarrelRollAlpha = 1.0;
		AirMoveDataComp.bBarrelRollClockwise = ActivationParams.bRightDash;
	}
};
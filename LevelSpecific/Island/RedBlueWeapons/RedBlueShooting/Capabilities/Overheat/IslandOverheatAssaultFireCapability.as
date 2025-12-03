class UIslandRedBlueOverheatAssaultFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueWeapon);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueBlockedWhileInAnimation);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::AirJump);
	default CapabilityTags.Add(BlockedWhileIn::Dash);
	default CapabilityTags.Add(BlockedWhileIn::DashRollState);
	default CapabilityTags.Add(BlockedWhileIn::RollDashJumpStart);
	default CapabilityTags.Add(BlockedWhileIn::HighSpeedLanding);
	default CapabilityTags.Add(BlockedWhileIn::ApexDive);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 120;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UIslandRedBlueOverheatAssaultUserComponent OverheatUserComponent;
	UIslandRedBlueWeaponSettings Settings;
	UIslandRedBlueOverheatAssaultSettings OverheatAssaultSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		OverheatUserComponent = UIslandRedBlueOverheatAssaultUserComponent::GetOrCreate(Player);
		Settings = UIslandRedBlueWeaponSettings::GetSettings(Player);
		OverheatAssaultSettings = UIslandRedBlueOverheatAssaultSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return false;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return false;

		if(OverheatUserComponent.bIsOverheated)
			return false;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if(WeaponUserComponent.GetAimTarget().AimDirection.Equals(FVector::ZeroVector))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return true;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		if(OverheatUserComponent.bIsOverheated)
			return true;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if(WeaponUserComponent.GetAimTarget().AimDirection.Equals(FVector::ZeroVector))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WeaponUserComponent.FireWeaponsInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WeaponUserComponent.FireWeaponsInstigators.RemoveSingleSwap(this);
		WeaponUserComponent.TimeOfStartShooting = -1.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(OverheatUserComponent.bIsOverheated)
			return;

		FHazeFrameForceFeedback ForceFeedback;
		ForceFeedback.RightTrigger = Math::Lerp(0.2, OverheatAssaultSettings.RumbleAmount, OverheatUserComponent.OverheatAlpha);
		ForceFeedback.RightMotor = Math::Lerp(0.2, OverheatAssaultSettings.RumbleAmount, OverheatUserComponent.OverheatAlpha);
		Player.SetFrameForceFeedback(ForceFeedback);
	}
}
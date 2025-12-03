class UIslandRedBlueSidescrollerAssaultForceAimCapability : UHazePlayerCapability
{
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

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UHazeInputComponent InputComp;
	UPlayerAimingComponent AimComponent;
	UIslandRedBlueSidescrollerAssaultSettings SidescrollerAssaultSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		InputComp = UHazeInputComponent::Get(Player);
		AimComponent = UPlayerAimingComponent::Get(Player);
		SidescrollerAssaultSettings = UIslandRedBlueSidescrollerAssaultSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::SidescrollerAssault)
			return false;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return false;

		if(!CanEverShowSpotlight())
			return false;

		if(!ShouldAim())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::SidescrollerAssault)
			return true;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		if(!CanEverShowSpotlight())
			return true;

		if(!ShouldAim())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WeaponUserComponent.AimInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WeaponUserComponent.AimInstigators.RemoveSingleSwap(this);
	}

	bool ShouldAim() const
	{
		if(InputComp.IsUsingGamePad())
		{
			if(!GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
				return true;
		}

		if(InputComp.GetControllerType() == EHazePlayerControllerType::Keyboard)
			return true;

		return false;
	}

	bool CanEverShowSpotlight() const
	{
		EAimingConstraintType2D ConstraintType = AimComponent.GetCurrentAimingConstraintType();
		switch(ConstraintType)
		{
			case EAimingConstraintType2D::Plane:
			{
				if(!SidescrollerAssaultSettings.bShowSpotlightInTopDown)
					return false;
				break;
			}
			case EAimingConstraintType2D::Spline:
			{
				if(!SidescrollerAssaultSettings.bShowSpotlightInSidescroller)
					return false;
				break;
			}
			case EAimingConstraintType2D::None:
			{
				if(!SidescrollerAssaultSettings.bShowSpotlightIn3D)
					return false;
				break;
			}
			default:
		}

		return true;
	}
}
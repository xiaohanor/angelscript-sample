class UIslandRedBlueOverheatAssaultCooldownCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

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

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UIslandRedBlueOverheatAssaultUserComponent OverheatUserComponent;
	UIslandRedBlueOverheatAssaultSettings OverheatAssaultSettings;

	const float OverheatAnimationDuration = 1.33;
	
	bool bHasLetGoOfShoot = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		OverheatUserComponent = UIslandRedBlueOverheatAssaultUserComponent::GetOrCreate(Player);
		OverheatAssaultSettings = UIslandRedBlueOverheatAssaultSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return false;

		if(WeaponUserComponent.WantsToFireWeapon() && !OverheatUserComponent.bIsOverheated)
			return false;

		if(OverheatUserComponent.OverheatAlpha == 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return true;

		if(WeaponUserComponent.WantsToFireWeapon() && !OverheatUserComponent.bIsOverheated)
			return true;

		if(OverheatUserComponent.bIsOverheated && Time::GetGameTimeSince(OverheatUserComponent.TimeOfOverheat) < OverheatAnimationDuration)
			return false;

		if(OverheatUserComponent.OverheatAlpha == 0.0 && bHasLetGoOfShoot)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasLetGoOfShoot = false;

		for(AIslandRedBlueWeapon Weapon : WeaponUserComponent.Weapons)
		{
			UIslandRedBlueWeaponEffectHandler::Trigger_OnReloadStarted(Weapon);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// OverheatUserComponent.OverheatAlpha = 0.0;
		OverheatUserComponent.SetIsOverheated(false);
		WeaponUserComponent.AttachWeaponToThigh(this);
		WeaponUserComponent.RemoveBlockCameraAssistanceInstigator(this);

		for(AIslandRedBlueWeapon Weapon : WeaponUserComponent.Weapons)
		{
			UIslandRedBlueWeaponEffectHandler::Trigger_OnReloadFinished(Weapon);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!OverheatUserComponent.bIsOverheated || ActiveDuration > OverheatAssaultSettings.CooldownBeforeCoolingDown)
		{
			OverheatUserComponent.OverheatAlpha -= DeltaTime * OverheatAssaultSettings.OverheatCooldownSpeed;
			OverheatUserComponent.OverheatAlpha = Math::Saturate(OverheatUserComponent.OverheatAlpha);
		}

		if(OverheatUserComponent.bIsOverheated && !bHasLetGoOfShoot && !IsActioning(ActionNames::PrimaryLevelAbility))
		{
			bHasLetGoOfShoot = true;
		}

		if(OverheatUserComponent.bIsOverheated && OverheatUserComponent.OverheatAlpha > 0.0)
		{
			WeaponUserComponent.AttachWeaponToHand(this);
			WeaponUserComponent.AddBlockCameraAssistanceInstigator(this);

			float RumbleAmount = OverheatAssaultSettings.OverheatRumbleAmount * OverheatUserComponent.OverheatAlpha;
			if(ActiveDuration < OverheatAssaultSettings.ImpactOverheatRumbleDuration)
				RumbleAmount = OverheatAssaultSettings.ImpactOverheatRumbleAmount;

			FHazeFrameForceFeedback ForceFeedback;
			//ForceFeedback.LeftMotor = RumbleAmount;
			ForceFeedback.RightTrigger = 0.01 * OverheatUserComponent.OverheatAlpha;
			ForceFeedback.RightMotor = 0.01 * OverheatUserComponent.OverheatAlpha;

			if(ActiveDuration < OverheatAssaultSettings.ImpactOverheatRumbleDuration)
			{
				ForceFeedback.LeftMotor = RumbleAmount;
				ForceFeedback.RightMotor = RumbleAmount;
				ForceFeedback.RightTrigger = RumbleAmount;
			}

			Player.SetFrameForceFeedback(ForceFeedback);
		}

		if(OverheatUserComponent.bIsOverheated && Time::GetGameTimeSince(OverheatUserComponent.TimeOfOverheat) > OverheatAnimationDuration)
		{
			WeaponUserComponent.AttachWeaponToThigh(this);
			WeaponUserComponent.RemoveBlockCameraAssistanceInstigator(this);
		}
	}
}
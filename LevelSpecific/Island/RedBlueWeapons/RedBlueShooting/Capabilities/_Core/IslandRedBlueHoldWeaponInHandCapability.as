class UIslandRedBlueHoldWeaponInHandCapability : UHazePlayerCapability
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
	default TickGroupOrder = 125;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UIslandRedBlueWeaponSettings Settings;
	UIslandSidescrollerComponent SidescrollerComp;
	UPlayerStrafeComponent StrafeComponent;
	UPlayerAimingComponent AimComp;
	float HoldWeaponsInHandTimeLeft = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		Settings = UIslandRedBlueWeaponSettings::GetSettings(Player);
		SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
		StrafeComponent = UPlayerStrafeComponent::GetOrCreate(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WeaponUserComponent.HasEquippedWeapons())
			return false;

		if(ShouldHoldWeaponInHand())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HoldWeaponsInHandTimeLeft <= 0)
			return true;

		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WeaponUserComponent.AttachWeaponToHand(this);
		WeaponUserComponent.AddBlockCameraAssistanceInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(WeaponUserComponent.HasEquippedWeapons())
		{
			WeaponUserComponent.AttachWeaponToThigh(this);
		}

		WeaponUserComponent.RemoveBlockCameraAssistanceInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ShouldHoldWeaponInHand())
		{
			// As long as we are firing, we keep the guns in our hands
			// a some delay before we re attach them to the thighs
			HoldWeaponsInHandTimeLeft = Settings.BlendArmsDownToThighsDuration;
			
			if(Player.Mesh.CanRequestOverrideFeature())
			{
				if(!WeaponUserComponent.IsOverrideFeatureBlocked())
					Player.Mesh.RequestOverrideFeature((AimComp.GetCurrentAimingConstraintType() == EAimingConstraintType2D::Spline) ? n"CopsGunAimOverride2D" : n"CopsGunAimOverride", this);
				WeaponUserComponent.WeaponAnimData.LastFrameWeAimed = Time::FrameNumber;
			}
		}
		else
		{
			HoldWeaponsInHandTimeLeft -= DeltaTime;
		}
	}

	bool ShouldHoldWeaponInHand() const
	{
		if(WeaponUserComponent.WantsToFireWeapon())
			return true;

		if(WeaponUserComponent.IsAiming())
			return true;

		return false;
	}
}
class UAdultDragonAcidChargeProjectileReleaseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAcidFire);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;
	UPlayerAcidAdultDragonComponent DragonComp;
	UAdultDragonAcidChargeProjectileComponent ChargeComp;
	UAdultDragonAcidChargeProjectileSettings ProjectileSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
		ChargeComp = UAdultDragonAcidChargeProjectileComponent::Get(Player);

		ProjectileSettings = UAdultDragonAcidChargeProjectileSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ChargeComp.bHasSuccessfullyShot)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= ProjectileSettings.Cooldown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ChargeComp.bHasSuccessfullyShot = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DragonComp.DragonMesh.CanRequestAdditiveFeature())
			DragonComp.DragonMesh.RequestAdditiveFeature(n"AcidAdultDragonShoot", this);
	}
};
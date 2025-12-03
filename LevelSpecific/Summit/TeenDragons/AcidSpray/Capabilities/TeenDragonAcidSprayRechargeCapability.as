class UTeenDragonAcidSprayRechargeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSpray);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 20;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAimingComponent AimComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAcidSprayComponent SprayComp;
	float RechargeAmount = 0.0;

	UTeenDragonAcidSpraySettings SpraySettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		SprayComp = UTeenDragonAcidSprayComponent::Get(Player);

		SpraySettings = UTeenDragonAcidSpraySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.IsAnyCapabilityActive(TeenDragonCapabilityTags::TeenDragonAcidSprayFire))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Owner.IsAnyCapabilityActive(TeenDragonCapabilityTags::TeenDragonAcidSprayFire))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RechargeAmount = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RechargeAmount = Math::FInterpConstantTo(RechargeAmount, SpraySettings.AcidRechargeSpeed, DeltaTime, SpraySettings.AcidAccelerationRechargeSpeed);
		SprayComp.AlterAcidAlpha(RechargeAmount * DeltaTime);
	}	
}
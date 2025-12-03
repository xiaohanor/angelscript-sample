class UAdultDragonAcidBeamRechargeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(BlockedWhileIn::Dash);	
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"Aim");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 20;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"AdultDragon";

	UPlayerAimingComponent AimComp;
	UPlayerAcidAdultDragonComponent DragonComp;
	float RechargeAmount = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.IsAnyCapabilityActive(n"AcidFire"))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Owner.IsAnyCapabilityActive(n"AcidFire"))
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
		RechargeAmount = Math::FInterpConstantTo(RechargeAmount, AdultDragonAcidBeam::AcidRechargeSpeed, DeltaTime, AdultDragonAcidBeam::AcidAccelerationRechargeSpeed);
		DragonComp.AlterAcidAlpha(RechargeAmount * DeltaTime);
	}	
}
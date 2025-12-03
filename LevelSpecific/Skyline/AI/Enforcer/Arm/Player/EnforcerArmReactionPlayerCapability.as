class UEnforcerArmReactionPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	UEnforcerArmResponseComponent ArmResponseComp;
	UEnforcerArmComponent Arm;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ArmResponseComp = UEnforcerArmResponseComponent::Get(Owner);
		ArmResponseComp.OnHit.AddUFunction(this, n"OnHit");		
	}

	UFUNCTION()
	private void OnHit(UEnforcerArmComponent InArm)
	{
		Arm = InArm;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		if(Arm != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Arm == nullptr)
			return true;

		auto Settings = UEnforcerArmSettings::GetSettings(Cast<AHazeActor>(Arm.Owner));
		if (Settings != nullptr && ActiveDuration > Settings.AttackTargetStunDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Arm.RemoveAttackedActor(Owner);
		Arm = nullptr;
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}
}
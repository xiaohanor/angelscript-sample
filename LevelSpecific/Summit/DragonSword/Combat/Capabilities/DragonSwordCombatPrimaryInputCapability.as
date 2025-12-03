class UDragonSwordCombatPrimaryInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombatPrimaryInput);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 60;

	UPlayerSlideComponent SlideComp;
	UDragonSwordCombatInputComponent InputComp;
	UPlayerMovementComponent MoveComp;
	UDragonSwordCombatUserComponent CombatComp;
	UDragonSwordUserComponent SwordComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlideComp = UPlayerSlideComponent::Get(Owner);
		InputComp = UDragonSwordCombatInputComponent::GetOrCreate(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
		SwordComp = UDragonSwordUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwordComp.IsWeaponEquipped())
			return false;

		if (SlideComp.IsSlideActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwordComp.IsWeaponEquipped())
			return true;
		
		if (SlideComp.IsSlideActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InputComp.PrimaryReleaseTime = -1;
		InputComp.PrimaryPressTime = -1;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		InputComp.PrimaryReleaseTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
			InputComp.PrimaryPressTime = Time::GameTimeSeconds;
		else if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			InputComp.PrimaryReleaseTime = Time::GameTimeSeconds;

		if (!MoveComp.MovementInput.IsNearlyZero() && MoveComp.MovementInput.ContainsNaN())
		{
			InputComp.LastMovementInput = MoveComp.MovementInput;
		}

		if (Time::GetGameTimeSince(InputComp.PrimaryPressTime) > 1.5 && InputComp.LastMovementInput.IsSet())
			InputComp.LastMovementInput.Reset();
	}
}
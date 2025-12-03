class UGravityBladeSheatheCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBladeUserComponent BladeComp;
	UPlayerPerchComponent PerchComp;
	UPlayerSwingComponent SwingComp;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerInteractionsComponent InteractionsComp;
	UPlayerLadderComponent LadderComp;
	UPlayerPoleClimbComponent PoleComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
		SwingComp = UPlayerSwingComponent::Get(Player);
		SwimmingComp = UPlayerSwimmingComponent::Get(Player);
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
		LadderComp = UPlayerLadderComponent::Get(Player);
		PoleComp = UPlayerPoleClimbComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BladeComp.IsBladeSheathed())
			return false;

		// Sheathe the blade when perching
		if (PerchComp.IsCurrentlyPerching())
			return true;

		// Sheathe the blade when swinging
		if (SwingComp.IsCurrentlySwinging())
			return true;

		// Sheathe the blade when swimming
		if (SwimmingComp.IsSwimming())
			return true;

		// Sheathe the blade while in an interaction
		if (InteractionsComp.ActiveInteraction != nullptr)
			return true;

		// Sheathe the blade while climbing ladders
		if (LadderComp.IsClimbing())
			return true;

		// Sheathe the blade while climbing poles
		if (PoleComp.IsClimbing())
			return true;

		// Sheathe when wielding is blocked
		if (Player.IsCapabilityTagBlocked(GravityBladeTags::GravityBladeWield))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Always deactivate immediately. The unsheathing doesn't happen until we do our first gravity blade attack, later
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BladeComp.SheatheBlade();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};
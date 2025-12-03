class USummitSiegeActiveRangeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	USiegeActivationComponent ActivationComp;
	USiegeHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActivationComp = USiegeActivationComponent::Get(Owner);
		HealthComp = USiegeHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HealthComp.bAlive)
			return false;

		if (!PlayersInRange())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HealthComp.bAlive)
			return true;
		
		if (!PlayersInRange())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ActivationComp.bCanBeActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActivationComp.bCanBeActive = false;
	}

	bool PlayersInRange() const
	{
		AHazePlayerCharacter Player = Game::Mio.GetDistanceTo(Owner) < Game::Zoe.GetDistanceTo(Owner) ? Game::Mio : Game::Zoe;
		return Player.GetDistanceTo(Owner) < ActivationComp.Range;
	}
}
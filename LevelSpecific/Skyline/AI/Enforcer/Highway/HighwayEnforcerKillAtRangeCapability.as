class UHighwayEnforcerKillAtRangeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"KillAtRange");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;

		bool bCloseEnough = false;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.GetDistanceTo(Owner) < 30000)
				bCloseEnough = true;
		}
		if(bCloseEnough)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
	}
};
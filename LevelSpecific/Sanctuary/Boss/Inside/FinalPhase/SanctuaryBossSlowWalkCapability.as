class USanctuaryBossSlowWalkCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	ASanctuaryBossFinalPhaseManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<ASanctuaryBossFinalPhaseManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Manager.bSlowWalk)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Manager.bSlowWalk)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
		{
			Player.AddLocomotionFeature(Manager.Feature, this, 1);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : Game::Players)
		{
			Player.RemoveLocomotionFeature(Manager.Feature, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Manager.bShouldSlowWalk)
		{
			for (auto Player : Game::Players)
			{
				if (Player.Mesh.CanRequestLocomotion())
					Player.RequestLocomotion(n"SwordWindWalk", this);
			}
		}
		else
		{
			if (Game::Zoe.Mesh.CanRequestLocomotion())
					Game::Zoe.RequestLocomotion(n"SwordWindWalk", this);
		}
	}
};
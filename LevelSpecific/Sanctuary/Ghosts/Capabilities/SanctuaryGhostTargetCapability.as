class USanctuaryGhostTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryGhost");
	default CapabilityTags.Add(n"SanctuaryGhostTarget");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryGhost Ghost;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ghost = Cast<ASanctuaryGhost>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Ghost.TargetPlayer != nullptr && Ghost.TargetPlayer.IsPlayerDead())
			return true;

		if (ActiveDuration > 2.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Player = Game::GetClosestPlayer(Ghost.ActorLocation);
		if (!Player.IsPlayerDead() || !IsPlayerUnderAttack(Player))
			Ghost.TargetPlayer = Player;
		else
			Ghost.TargetPlayer = Player.OtherPlayer;

//		Ghost.Godray.SetRenderedForPlayer(Ghost.TargetPlayer, true);
//		Ghost.Godray.SetRenderedForPlayer(Ghost.TargetPlayer.OtherPlayer, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool IsPlayerUnderAttack(AHazePlayerCharacter Player) const
	{
		TListedActors<ASanctuaryGhost> ActiveGhosts;
		for (auto ActiveGhost : ActiveGhosts)
		{
			if (ActiveGhost.TargetPlayer == Player)
				return true;
		}

		return false;
	}
};
class UExampleAIRunAwayFromPlayerBehavior : UHazeChildCapability
{
	// Set this child capability to require networking to function
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// If the player is no longer close enough, don't run away
		float MinDistance = Math::Min(
			Game::Mio.GetDistanceTo(Owner),
			Game::Zoe.GetDistanceTo(Owner)
		);

		if (MinDistance < 1000.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Once we are far enough away from the player, we are done running away
		float MinDistance = Math::Min(
			Game::Mio.GetDistanceTo(Owner),
			Game::Zoe.GetDistanceTo(Owner)
		);

		if (MinDistance > 1500.0)
			return true;
		return false;
	}

	// Run away from the nearest player every frame
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter ClosestPlayer = nullptr;
		for (auto Player : Game::Players)
		{
			if (ClosestPlayer == nullptr || ClosestPlayer.GetDistanceTo(Owner) > Player.GetDistanceTo(Owner))
				ClosestPlayer = Player;
		}

		// Wiggle a bit up and down while idle
		FVector Direction = (Owner.ActorLocation - ClosestPlayer.ActorLocation).GetSafeNormal2D();
		Owner.ActorLocation += Direction * 500.0 * DeltaTime;
	}
};
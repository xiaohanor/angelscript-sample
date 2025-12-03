class USummitStoneBeastSlasherFindTargetBehaviour : UBasicBehaviour
{
	USummitStoneBeastSlasherSettings Settings;
	AHazePlayerCharacter LastTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitStoneBeastSlasherSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter BestPlayer = GetBestTarget();
		if (!TargetComp.IsValidTarget(BestPlayer))
			return;
		if (!Owner.ActorLocation.IsWithinDist(BestPlayer.ActorLocation, Settings.AttackRange))
			return;

		// Found target within range!
		LastTarget = BestPlayer;
		Cooldown.Set(Settings.TargetingInterval);
		TargetComp.SetTarget(BestPlayer);
	}

	AHazePlayerCharacter GetBestTarget()
	{
		if (!TargetComp.IsValidTarget(Game::Mio))
			return Game::Zoe;
		if (!TargetComp.IsValidTarget(Game::Zoe))
			return Game::Mio;		
		if ((LastTarget != nullptr) && TargetComp.IsValidTarget(LastTarget.OtherPlayer) && Owner.ActorLocation.IsWithinDist(LastTarget.OtherPlayer.ActorLocation, Settings.AttackRange))
			return LastTarget.OtherPlayer;
		if (Owner.ActorLocation.DistSquared(Game::Mio.ActorLocation) < Owner.ActorLocation.DistSquared(Game::Zoe.ActorLocation))
			return Game::Mio;
		return Game::Zoe;
	}
}

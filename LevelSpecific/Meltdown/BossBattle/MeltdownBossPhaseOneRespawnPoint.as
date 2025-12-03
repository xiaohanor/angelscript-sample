class AMeltdownBossPhaseOneRespawnPoint : ARespawnPoint
{
	bool IsValidToRespawn(AHazePlayerCharacter Player) const override
	{
		FVector RespawnLocation = GetPositionForPlayer(Player).Location;
		for (AMeltdownBossPhaseOneSmashAttack SmashAttack : TListedActors<AMeltdownBossPhaseOneSmashAttack>())
		{
			if (SmashAttack.IsActorDisabled())
				continue;
			float Distance = SmashAttack.TelegraphRoot.WorldLocation.Dist2D(RespawnLocation);
			if (Distance < SmashAttack.Radius + 120)
				return false;
		}
		return true;
	}

	bool ShouldRecalculateOnRespawnTriggered() const override
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Debug::DrawDebugSphere(
		// 	GetPositionForPlayer(Game::Mio).Location,
		// 	100, 
		// 	LineColor = IsValidToRespawn(Game::Mio) ? FLinearColor::Green : FLinearColor::Red
		// );
	}

	UFUNCTION(CallInEditor)
	void SetAllToRespawnVolume(ARespawnPointVolume Volume)
	{
		Volume.EnabledRespawnPoints.Reset();
		for (auto RespawnPoint : TListedActors<ARespawnPoint>())
		{
			if (RespawnPoint.IsA(AMeltdownBossPhaseOneRespawnPoint))
			{
				Volume.EnabledRespawnPoints.Add(RespawnPoint);
			}
		}
	}
}
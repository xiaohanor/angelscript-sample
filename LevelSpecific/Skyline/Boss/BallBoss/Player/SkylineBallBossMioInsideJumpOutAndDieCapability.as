class USkylineBallBossMioInsideJumpOutAndDieCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	ASkylineBallBoss BallBoss;

	const float Radius = 1500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ASkylineBallBoss> BallBosses;
		BallBoss = BallBosses.Single;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;

		if (BallBoss.InsideRespawnPoint == nullptr)
			return false;

		if (!BallBoss.bInsideActivated)
			return false;

		if (!IsInInsidePhase())
			return false;

		if (Player.IsPlayerDead())
			return false;

		return true;
	}

	bool IsInInsidePhase() const
	{
		if (BallBoss.GetPhase() < ESkylineBallBossPhase::TopMioIn)
			return false;
		if (BallBoss.GetPhase() > ESkylineBallBossPhase::TopDeath)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;
		if (!IsInInsidePhase())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.ActorCenterLocation.Distance(BallBoss.FakeRootComp.WorldLocation) > Radius)
			Player.KillPlayer();
	}
};

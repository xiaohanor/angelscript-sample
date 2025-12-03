class UMeltdownBossPhaseThreeStoneBeastActionSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	AMeltdownBossPhaseThreeShootingFlyingStoneBeast StoneBeast;
	AMeltdownBoss Rader;

	const FRotator LeftOffsetRotation(10, 10, 0);
	const FRotator RightOffsetRotation(-10, -10, 0);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBeast = Cast<AMeltdownBossPhaseThreeShootingFlyingStoneBeast>(Owner);
		Rader = Cast<AMeltdownBoss>(Owner.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMeltdownBossPhaseThreeStoneBeastSpawnParams& Params) const
	{
		if (StoneBeast.RemainingAttackCount <= 0)
			return false;
		if (!StoneBeast.ActionQueue.IsEmpty())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StoneBeast.RemainingAttackCount <= 0 && StoneBeast.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMeltdownBossPhaseThreeStoneBeastSpawnParams Params)
	{
		Rader.SetLookTarget(Game::Mio);
		StoneBeast.ActionQueue.Reset();
		Spawn(Game::Mio, LeftOffsetRotation);
		Fire();
		Idle(1.0);

		StoneBeast.RemainingAttackCount -= 1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (StoneBeast.ActionQueue.IsEmpty() && StoneBeast.RemainingAttackCount > 0)
		{
			if (StoneBeast.PlayerToTrack.IsMio())
				Track(Game::Zoe, RightOffsetRotation);
			else
				Track(Game::Mio, LeftOffsetRotation);

			Fire();
			Idle(0.5);

			StoneBeast.RemainingAttackCount -= 1;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StoneBeast.AddActorDisable(StoneBeast);
	}

	void Spawn(AHazePlayerCharacter FacingPlayer, FRotator OffsetRotation)
	{
		FMeltdownBossPhaseThreeStoneBeastSpawnParams Action;
		Action.FacingPlayer = FacingPlayer;
		Action.OffsetRotation = OffsetRotation;
		StoneBeast.ActionQueue.Queue(Action);
	}

	void Track(AHazePlayerCharacter Player, FRotator OffsetRotation)
	{
		FMeltdownBossPhaseThreeStoneBeastTrackParams Action;
		Action.Player = Player;
		Action.OffsetRotation = OffsetRotation;
		StoneBeast.ActionQueue.Queue(Action);
	}

	void Fire()
	{
		FMeltdownBossPhaseThreeStoneBeastFireParams Action;
		StoneBeast.ActionQueue.Queue(Action);
	}

	void Idle(float Duration)
	{
		FMeltdownBossPhaseThreeStoneBeastIdleParams Action;
		Action.Duration = Duration;
		StoneBeast.ActionQueue.Queue(Action);
	}
};
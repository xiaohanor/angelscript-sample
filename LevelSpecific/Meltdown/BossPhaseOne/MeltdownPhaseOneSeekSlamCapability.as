class UMeltdownPhaseOneSeekSlamCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseOne Rader;

	AMeltdownBossPhaseOneSmashAttack ActiveLeftSmasher;
	AMeltdownBossPhaseOneSmashAttack ActiveRightSmasher;
	int AttackCount = 0;

	TArray<AMeltdownBossPhaseOneSmashAttack> PastAttacks;
	bool bStartAnimating;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseOne>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::SeekSlam)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::SeekSlam)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bStartAnimating = false;
		Rader.ActionQueue.NetworkSyncPoint(this);
		Rader.ActionQueue.Event(this, n"StartAnimating");
	}

	UFUNCTION()
	private void StartAnimating()
	{
		bStartAnimating = true;
	}

	UFUNCTION()
	private void MoveArenaToFirstPosition()
	{
		Rader.SeekSlamGridPositioner.AccelerateToPosition(0, 0.6);
	}

	UFUNCTION()
	private void MoveArenaToSecondPosition()
	{
		Rader.SeekSlamGridPositioner.AccelerateToPosition(1, 0.6);
	}

	UFUNCTION()
	private void ResetArena()
	{
		Rader.SeekSlamGridPositioner.AccelerateToPosition(2, 2.5);
	}

	UFUNCTION()
	private void StartSmashing()
	{
		ActiveLeftSmasher = SpawnActor(Rader.SmashAttackClass, Rader.ArenaRoot.ActorLocation);
		ActiveLeftSmasher.bAutoDestroy = true;
		ActiveLeftSmasher.HitDuration = 120;
		ActiveLeftSmasher.HitDisplacement = -600;
		PastAttacks.Add(ActiveLeftSmasher);

		ActiveRightSmasher = SpawnActor(Rader.SmashAttackClass, Rader.ArenaRoot.ActorLocation);
		ActiveRightSmasher.bAutoDestroy = true;
		ActiveRightSmasher.HitDuration = 120;
		ActiveRightSmasher.HitDisplacement = -600;
		PastAttacks.Add(ActiveRightSmasher);

		ActiveLeftSmasher.StartAttack(2.5, Game::Mio, 2.0);
		ActiveRightSmasher.StartAttack(2.5, Game::Zoe, 2.0);

		UMeltdownBossPhaseOneSeekSlamEffectHandler::Trigger_SpawnSmashers(Rader);

		AttackCount += 1;
	}

	UFUNCTION()
	private void TriggerAnticipate()
	{
		Rader.LastSlamAnticipateFrame = GFrameNumber;
	}

	UFUNCTION()
	private void TriggerSmash()
	{
		Rader.LastSlamFrame = GFrameNumber;
		ActiveLeftSmasher.Displacement.LerpDistance = 0.0;
		ActiveRightSmasher.Displacement.LerpDistance = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.ActionQueue.Empty();
		Rader.SeekSlamGridPositioner.ResetToOriginalPosition(1.0);

		for (auto Attack : PastAttacks)
		{
			if (IsValid(Attack))
			{
				if (Attack.bHasHit)
				{
					Attack.HitDuration = 0.0;
					Attack.HitTimer = Attack.RestoreDuration;
				}
				else
				{
					Attack.DestroyActor();
				}
			}
		}

		PastAttacks.Empty();
	}

	UFUNCTION(BlueprintCallable)
	void ResetGrid()
	{

	}

	void QueueSlamSequence()
	{
		Rader.ActionQueue.Event(this, n"StartSmashing");
		Rader.ActionQueue.Idle(2.0);
		Rader.ActionQueue.Event(this, n"TriggerAnticipate");
		Rader.ActionQueue.Idle(0.5);
		Rader.ActionQueue.Event(this, n"TriggerSmash");
		Rader.ActionQueue.Idle(0.35);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion() && bStartAnimating)
			Rader.Mesh.RequestLocomotion(n"SeekSlam", this);

		// If we've run out of queued attacks, queue up a new sequence
		if (Rader.ActionQueue.IsEmpty() && Rader.CurrentAttack == EMeltdownPhaseOneAttack::SeekSlam)
		{
			QueueSlamSequence();
			Rader.ActionQueue.Event(this, n"MoveArenaToFirstPosition");
			Rader.ActionQueue.Idle(1.65);
			Rader.ActionQueue.Event(this, n"ResetArena");

			QueueSlamSequence();
			Rader.ActionQueue.Event(this, n"MoveArenaToSecondPosition");
			Rader.ActionQueue.Idle(1.65);
			Rader.ActionQueue.Event(this, n"ResetArena");
		}

		// Update where Rader is holding his hands
		if (IsValid(ActiveLeftSmasher))
			Rader.LeftHandTrackingValue = Rader.GetPositionWithinArena(ActiveLeftSmasher.ActorLocation).X;
		if (IsValid(ActiveRightSmasher))
			Rader.RightHandTrackingValue = Rader.GetPositionWithinArena(ActiveRightSmasher.ActorLocation).X;
	}
};


UCLASS(Abstract)
class UMeltdownBossPhaseOneSeekSlamEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnSmashers() {}
}
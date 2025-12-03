class UMeltdownPhaseTwoSpaceShipsAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseTwo Rader;
	bool bTriggeredFinish = false;
	bool bHasFinished = false;

	bool bThrowingLeft = false;

	AMeltdownBossPhaseTwoSpaceShip RightShip;
	AMeltdownBossPhaseTwoSpaceShip LeftShip;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseTwo>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::SpaceShips && Rader.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bHasFinished)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LeftShip = SpawnActor(Rader.SpaceShipClass);
		LeftShip.Root.SetAbsolute(false, false, true);
		LeftShip.AttachToComponent(Rader.Mesh, n"LeftAttach");
		LeftShip.SetActorRelativeRotation(FRotator(0, 0, 90));
		LeftShip.RemoveActorDisable(LeftShip);

		RightShip = SpawnActor(Rader.SpaceShipClass);
		RightShip.Root.SetAbsolute(false, false, true);
		RightShip.AttachToComponent(Rader.Mesh, n"RightAttach");
		RightShip.SetActorRelativeRotation(FRotator(0, 0, 90));
		RightShip.RemoveActorDisable(RightShip);

		Rader.ActionQueue.Idle(2.7);
		Rader.ActionQueue.Event(this, n"StartThrowLeft");
		Rader.ActionQueue.Idle(0.6);
		Rader.ActionQueue.Event(this, n"ThrowShip");
		Rader.ActionQueue.Idle(1.5);
		Rader.ActionQueue.Event(this, n"StartThrowRight");
		Rader.ActionQueue.Idle(0.6);
		Rader.ActionQueue.Event(this, n"ThrowShip");
		Rader.ActionQueue.Idle(1.5);
		Rader.ActionQueue.Event(this, n"ChangeAttack");
		Rader.ActionQueue.Idle(1.5);
		Rader.ActionQueue.Event(this, n"FinishAttack");

		bHasFinished = false;
		bTriggeredFinish = false;
		UMeltdownBossPhaseTwoSpaceShipsEffectHandler::Trigger_SpaceShipsPhaseStart(Rader);
	}

	UFUNCTION()
	private void FinishAttack()
	{
		bHasFinished = true;
	}

	UFUNCTION()
	private void ChangeAttack()
	{
		Rader.CurrentAttack = EMeltdownPhaseTwoAttack::SpaceBomber;
	}

	UFUNCTION()
	private void StartThrowLeft()
	{
		Rader.LastLeftAttackFrame = GFrameNumber;
		bThrowingLeft = true;
	}

	UFUNCTION()
	private void StartThrowRight()
	{
		Rader.LastRightAttackFrame = GFrameNumber;
		bThrowingLeft = false;
	}

	UFUNCTION()
	private void ThrowShip()
	{
		if (bThrowingLeft)
		{
			LeftShip.DetachRootComponentFromParent();
			RightShip.TargetPlayer = Game::Mio;
			LeftShip.LaunchSpaceShip();
			LeftShip.bCanfire = true;
		}
		else
		{
			RightShip.DetachRootComponentFromParent();
			RightShip.TargetPlayer = Game::Zoe;
			RightShip.LaunchSpaceShip();
			RightShip.bCanfire = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMeltdownBossPhaseTwoSpaceShipsEffectHandler::Trigger_SpaceShipsPhaseEnd(Rader);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"SpaceShips", this);

		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::None)
		{
			if (!bTriggeredFinish)
			{
				bTriggeredFinish = true;

				if (!LeftShip.bCanfire)
					LeftShip.AddActorDisable(this);
				if (!RightShip.bCanfire)
					RightShip.AddActorDisable(this);

				Rader.ActionQueue.Empty();
				Rader.ActionQueue.Idle(2.0);
				Rader.ActionQueue.Event(this, n"FinishAttack");
			}
		}
	}
};
class UMeltdownBossPhaseThreePunchotronsAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownPhaseThreeBoss Rader;
	int SpawnCount = 0;
	bool bSpawnedLeftHand = false;

	AMeltdownBossPhaseThreePunchotrons Punchotron;
	AMeltdownPileOfPunchotrons Pile;

	int NetworkCounter = 0;
	bool bFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownPhaseThreeBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.IsDead())
			return false;
		if (Rader.bPunchotronAttackActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bFinished)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Always use the fast animation
		Rader.bHasLoopedAttackPattern = true;
		Rader.PortalLocomotionTag = n"MechPortal";
		SpawnCount = 0;
		bFinished = false;
		
		// Idle for enter animation
		Rader.ActionQueue.Idle(2.0);
		Rader.ActionQueue.Event(this, n"SpawnPile");
		Rader.ActionQueue.Idle(1.0);
		Rader.ActionQueue.Event(this, n"HidePortal");
	}

	UFUNCTION()
	private void HidePortal()
	{
		Rader.PortalLocomotionTag = NAME_None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.PunchotronClassIndex = Math::WrapIndex(Rader.PunchotronClassIndex+1, 0, Rader.PunchotronsClasses.Num());
		HidePile();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"MechPortal", this);

		if (Rader.IsDead())
		{
			Rader.ActionQueue.Empty();
			bFinished = true;
			return;
		}
		// Pile.SetActorRelativeRotation(FRotator(90, 0, 180));

		// Queue up new attacks
		if (Rader.ActionQueue.IsEmpty())
		{
			if (SpawnCount >= 6)
			{
				Rader.bPunchotronSpawnLeft = false;
				Rader.bPunchotronSpawnRight = false;

				Rader.StopPunchotronAttack();
				Rader.ActionQueue.Idle(0.9);
				Rader.ActionQueue.Event(this, n"HidePile");
				Rader.ActionQueue.Idle(1.9);
				Rader.ActionQueue.Event(this, n"AttackFinished");
			}
			else
			{
				SpawnCount += 1;
				bSpawnedLeftHand = !bSpawnedLeftHand;

				Rader.bPunchotronSpawnLeft = bSpawnedLeftHand;
				Rader.bPunchotronSpawnRight = !bSpawnedLeftHand;

				Punchotron = SpawnActor(Rader.PunchotronsClasses[Rader.PunchotronClassIndex], bDeferredSpawn = true);
				Punchotron.MakeNetworked(this, NetworkCounter);
				NetworkCounter += 1;
				FinishSpawningActor(Punchotron);

				if (bSpawnedLeftHand)
					Punchotron.PlaySlotAnimation(Animation = Punchotron.LeftMHAnimation);
				else
					Punchotron.PlaySlotAnimation(Animation = Punchotron.RightMHAnimation);

				Punchotron.Rader = Rader;
				Punchotron.RootComponent.SetAbsolute(false, false, true);
				Punchotron.AttachToComponent(Rader.Mesh, n"RightAttach");
				UMeltdownBossPhaseThreePunchotronsEffectHandler::Trigger_Spawn(Punchotron);

				Rader.ActionQueue.Idle(0.9);
				Rader.ActionQueue.Event(this, n"LaunchPunchotron");
				Rader.ActionQueue.Idle(0.5);
			}
		}
	}

	UFUNCTION()
	private void AttackFinished()
	{
		Rader.OnPunchotronAttackFinished.Broadcast();
		Rader.PortalLocomotionTag = NAME_None;
		bFinished = true;
	}

	UFUNCTION()
	private void LaunchPunchotron()
	{
		if (bSpawnedLeftHand)
			Punchotron.Launch(Game::Mio);
		else
			Punchotron.Launch(Game::Zoe);

		Rader.bPunchotronSpawnLeft = false;
		Rader.bPunchotronSpawnRight = false;
		Punchotron.DetachRootComponentFromParent();
	}

	UFUNCTION()
	private void SpawnPile()
	{
		Pile = SpawnActor(Rader.PileOfPunchotronsClasses[Rader.PunchotronClassIndex]);
		Pile.RootComponent.SetAbsolute(false, false, true);
		Pile.AttachToComponent(Rader.Mesh, n"LeftAttach");
		Pile.Show();
	}

	UFUNCTION()
	private void HidePile()
	{
		if (Pile != nullptr)
		{
			Pile.Hide();
			Pile = nullptr;
		}
	}
}
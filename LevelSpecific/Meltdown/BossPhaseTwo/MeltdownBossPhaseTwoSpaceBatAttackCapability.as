class UMeltdownPhaseTwoSpaceBatAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 120; 

	AMeltdownBossPhaseTwo Rader;

	bool bTriggeredFinish = false;
	bool bHasFinished = false;

	const int TotalAttackCount = 4;

	int AttackCount = 0;
	bool bAttackingLeft = false;
	AMeltdownBossPhaseTwoSpaceBatAsteroid Asteroid;

	int SpawnCounter = 0;

	FHazeAcceleratedVector AccRaderPosition;
	FVector RaderStartLocation;
	FVector RaderTargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseTwo>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::SpaceBat && Rader.ActionQueue.IsEmpty() && !Rader.IsDead())
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
		// Phase Start
		Rader.ActionQueue.Idle(2.5);
		bHasFinished = false;
		bAttackingLeft = false;
		bTriggeredFinish = false;
		AttackCount = 0;

		Rader.Bat.Root.SetAbsolute(false, false, true);
		Rader.Bat.AttachToComponent(Rader.Mesh, n"RightAttach");
		Rader.Bat.SetActorRelativeRotation(FRotator(0, 0, 0));
		Rader.Bat.RemoveActorDisable(this);
		Rader.Bat.ObjectFade.FadeIn();

		AccRaderPosition.SnapTo(Rader.ActorLocation);
		RaderStartLocation = Rader.ActorLocation;
		RaderTargetLocation = Rader.ActorLocation;

		UMeltdownBossPhaseTwoSpaceBatEffectHandler::Trigger_SpaceBatPhaseStart(Rader);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.Bat.DetachRootComponentFromParent();
		Rader.Bat.AddActorDisable(this);
		UMeltdownBossPhaseTwoSpaceBatEffectHandler::Trigger_SpaceBatPhaseEnd(Rader);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"SpaceBat", this);

		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::SpaceBat)
		{
			if (Rader.ActionQueue.IsEmpty())
			{
				if (AttackCount >= 4)
				{
					// Move on to the next attack
					Rader.CurrentAttack = EMeltdownPhaseTwoAttack::SpaceBomber;
					Rader.ActionQueue.Duration(1.0, this, n"ResetPosition");
					Rader.ActionQueue.Event(this, n"StartFade");
					Rader.ActionQueue.Idle(1.67);
					Rader.ActionQueue.Event(this, n"FinishAttack");
				}
				else
				{
					AttackCount += 1;

					// Queue up a new asteroid
					Rader.ActionQueue.Event(this, n"StartSwing");
					Rader.ActionQueue.Idle(0.2);
					Rader.ActionQueue.Event(this, n"SpawnAsteroid");
					Rader.ActionQueue.Idle(0.8);
					Rader.ActionQueue.Event(this, n"HitAsteroid");
					Rader.ActionQueue.Idle(1.25);
				}
			}

			AccRaderPosition.AccelerateTo(RaderTargetLocation, 2.0, DeltaTime);
			Rader.ActorLocation = AccRaderPosition.Value;
		}
		else if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::None)
		{
			if (!bTriggeredFinish)
			{
				bTriggeredFinish = true;
				Rader.ActionQueue.Duration(1.0, this, n"ResetPosition");
				Rader.ActionQueue.Event(this, n"FinishAttack");
			}
		}
	}

	UFUNCTION()
	private void SpawnAsteroid()
	{
		Asteroid = SpawnActor(Rader.AsteroidClass, bDeferredSpawn = true);

		if (bAttackingLeft)
		{
			Asteroid.TargetPlayer = Game::Mio;
			Asteroid.SpawnDirection = -Rader.ActorRightVector;
		}
		else
		{
			Asteroid.TargetPlayer = Game::Zoe;
			Asteroid.SpawnDirection = Rader.ActorRightVector;
		}

		Asteroid.SpawnDirection = Asteroid.SpawnDirection;
		Asteroid.Rader = Rader;
		Asteroid.SetActorHiddenInGame(true);

		Asteroid.MakeNetworked(this, SpawnCounter);
		SpawnCounter += 1;
		FinishSpawningActor(Asteroid);
		Asteroid.Spawn();
	}

	UFUNCTION()
	private void FinishAttack()
	{
		bHasFinished = true;
	}

	UFUNCTION()
	private void StartFade()
	{
		Rader.Bat.ObjectFade.FadeOut();
	}

	UFUNCTION()
	private void ResetPosition(float Alpha)
	{
		Rader.ActorLocation = Math::Lerp(
			AccRaderPosition.Value, RaderStartLocation,
			Math::EaseInOut(0, 1, Alpha, 2)
		);
	}

	UFUNCTION()
	private void StartSwing()
	{
		bAttackingLeft = !bAttackingLeft;
		if (bAttackingLeft)
		{
			RaderTargetLocation = RaderStartLocation + FVector(0, -2000, 0);
			Rader.LastLeftAttackFrame = GFrameNumber;

			UMeltdownBossPhaseTwoSpaceBatEffectHandler::Trigger_SpaceBatSwingLeft(Rader);
		}
		else
		{
			RaderTargetLocation = RaderStartLocation + FVector(0, 2000, 0);
			Rader.LastRightAttackFrame = GFrameNumber;

			UMeltdownBossPhaseTwoSpaceBatEffectHandler::Trigger_SpaceBatSwingRight(Rader);
		}
	}

	UFUNCTION()
	private void HitAsteroid()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(Rader.Bat.BatShake,this);
			Player.PlayForceFeedback(Rader.Bat.BatFF,false,false,this);
		}
		Asteroid.BatHit();
		Asteroid = nullptr;
	}
};
class UMeltdownPhaseTwoSpaceBomberAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseTwo Rader;
	bool bHasFinished = false;

	AMeltdownBossPhaseTwoBomber Bomber;

	const int BombCount = 6;
	const float BombInterval = 1.25;
	int FiredCount = 0;
	bool bTriggeredFinish;

	int StrafeShipCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseTwo>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::SpaceBomber && Rader.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bHasFinished)
			return true;
		if(Rader.CurrentAttack == EMeltdownPhaseTwoAttack::None)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasFinished = false;
		bTriggeredFinish = false;
		FiredCount = 0;
		Rader.bIsFiringBombs = false;

		Bomber = SpawnActor(Rader.BomberClass);
		Bomber.Root.SetAbsolute(false, false, true);
		Bomber.AttachToComponent(Rader.Mesh, n"RightAttach");
		Bomber.SetActorRelativeRotation(FRotator(0, 0, 90));
		Bomber.ObjectFade.FadeIn();
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Rader, Bomber);
		UMeltdownBossPhaseTwoBomberEffectHandler::Trigger_SpawnBomber(Bomber);

		LaunchStrafeShip(5.0);
		LaunchStrafeShip(5.5);
//		LaunchStrafeShip(9.0);

		Rader.ActionQueue.Idle(2.17);
		Rader.ActionQueue.Event(this, n"StartFiring");
		for (int i = 0; i < BombCount; ++i)
		{
			Rader.ActionQueue.Event(this, n"ShootBomb");
			Rader.ActionQueue.Idle(BombInterval);
		}
		Rader.ActionQueue.Event(this, n"StopFiring");
		Rader.ActionQueue.Event(this, n"ChangeAttack");
		Rader.ActionQueue.Event(this, n"StartFade");
		Rader.ActionQueue.Idle(1.67);
		Rader.ActionQueue.Event(this, n"FinishAttack");

		UMeltdownBossPhaseTwoSpaceBomberEffectHandler::Trigger_SpaceBomberPhaseStart(Rader);
	}

	UFUNCTION()
	private void LaunchStrafeShip(float LaunchDelay)
	{
		if (!IsActive())
			return;

		FVector LaunchOffset = FVector(0, 0, 10000);
		AHazePlayerCharacter TargetPlayer;
		if (StrafeShipCount % 2 == 0)
		{
			TargetPlayer = Game::Mio;
			LaunchOffset.Y = 4000.0;
		}
		else
		{
			TargetPlayer = Game::Zoe;
			LaunchOffset.Y = -4000.0;
		}

		AMeltdownBossPhaseTwoSpaceShip StrafeShip = SpawnActor(Rader.SpaceShipClass);
		StrafeShip.SetActorLocation(Rader.ActorLocation + LaunchOffset);
		StrafeShip.Rader = Rader;
		StrafeShip.TargetPlayer = TargetPlayer;
		Timer::SetTimer(StrafeShip, n"StartFiring", LaunchDelay+2.0);
		Timer::SetTimer(StrafeShip, n"LaunchSpaceShip", LaunchDelay);

		StrafeShipCount += 1;
	}

	UFUNCTION()
	private void StartFiring()
	{
		Rader.bIsFiringBombs = true;
	}

	UFUNCTION()
	private void StopFiring()
	{
		Rader.bIsFiringBombs = false;
	}

	UFUNCTION()
	private void ChangeAttack()
	{
		Rader.CurrentAttack = EMeltdownPhaseTwoAttack::SpaceBat;
	}

	UFUNCTION()
	private void FinishAttack()
	{
		bHasFinished = true;
	}

	UFUNCTION()
	private void ShootBomb()
	{
		if (!IsActive())
			return;
		if (!IsValid(Bomber))
			return;

		AMeltdownBossPhaseTwoBomb Bomb = SpawnActor(Rader.BombClass);
		Bomb.Rader = Rader;

		FVector StartLocation = Bomber.ActorLocation;

		AHazePlayerCharacter TargetPlayer;
		if (FiredCount % 2 == 0)
			TargetPlayer = Game::Mio;
		else
			TargetPlayer = Game::Zoe;

		FVector ArenaLocation = Rader.SpaceArenaLocation.ActorLocation;

		FVector TargetLocation = TargetPlayer.ActorLocation;
		TargetLocation += TargetPlayer.ActorHorizontalVelocity.GetSafeNormal2D() * 300.0;
		TargetLocation.Z = ArenaLocation.Z;

		// Limit distance of missile target to center of the arena
		TargetLocation = ArenaLocation + (TargetLocation - ArenaLocation).GetClampedToMaxSize(1800);

		Bomb.Launch(StartLocation, TargetLocation);
		FiredCount += 1;

		FMeltdownBossPhaseTwoBomberFireParams FireParams;
		FireParams.BombSpawnLocation = StartLocation;
		UMeltdownBossPhaseTwoBomberEffectHandler::Trigger_FireBomb(Bomber, FireParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMeltdownBossPhaseTwoSpaceBomberEffectHandler::Trigger_SpaceBomberPhaseEnd(Rader);

		UMeltdownBossPhaseTwoBomberEffectHandler::Trigger_DespawnBomber(Bomber);
		Bomber.DestroyActor();
		Bomber = nullptr;
	}

	UFUNCTION()
	private void StartFade()
	{
		if(Bomber == nullptr)
			return;
		
		if(Bomber.ObjectFade == nullptr)
			return;

		Bomber.ObjectFade.FadeOut();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"SpaceBomber", this);

		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::None)
		{
			if (!bTriggeredFinish)
			{
				bTriggeredFinish = true;

				Rader.ActionQueue.Empty();
				Rader.ActionQueue.Event(this, n"StartFade");
				Rader.ActionQueue.Idle(2.0);
				Rader.ActionQueue.Event(this, n"FinishAttack");
			}
		}

		Bomber.SetActorScale3D(FVector(Math::GetMappedRangeValueClamped(
			FVector2D(0.0, 0.5),
			FVector2D(0.01, 1.0),
			ActiveDuration
		)));
	}
};
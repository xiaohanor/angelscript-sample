class UMeltdownPhaseTwoTridentAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110; 

	AMeltdownBossPhaseTwo Rader;
	int ProjectileCount = 0;
	bool bHasFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseTwo>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::Trident)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseTwoAttack::Trident && Rader.CurrentAttack != EMeltdownPhaseTwoAttack::None)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Phase Start
		Rader.ActionQueue.Idle(2.0);
		Rader.ActionQueue.Event(this, n"AttachTrident");
		Rader.ActionQueue.Idle(2.33);
		bHasFinished = false;

		UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_TridentPhaseStart(Rader);
	}

	UFUNCTION()
	private void AttachTrident()
	{
		Rader.Trident.Root.SetAbsolute(false, false, true);
		Rader.Trident.AttachToComponent(Rader.Mesh, n"RightAttach");
		Rader.Trident.SetActorRelativeRotation(FRotator(0, 90, -90));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.Trident.AddActorDisable(this);

		Rader.ActionQueue.Empty();
		if (!bHasFinished)
			UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_TridentPhaseEnd(Rader);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"VortexTrident", this);

		if (Rader.CurrentAttack == EMeltdownPhaseTwoAttack::Trident)
		{
			if (Rader.ActionQueue.IsEmpty())
			{
				// Summoning sharks
				Rader.ActionQueue.Event(this, n"StartSharkAttack");
				Rader.ActionQueue.Idle(0.5);

				Rader.ActionQueue.Event(this, n"LaunchSharks");
				Rader.ActionQueue.Idle(2.0);
				Rader.ActionQueue.Event(this, n"LaunchSharks");
				Rader.ActionQueue.Idle(1.5);
				Rader.ActionQueue.Event(this, n"LaunchSharks");
				Rader.ActionQueue.Idle(1.5);

				Rader.ActionQueue.Event(this, n"FinishSharkAttack");
				Rader.ActionQueue.Idle(2.66);
				Rader.ActionQueue.Event(this, n"StartTridentSlam");
				Rader.ActionQueue.Idle(1.66);

				// Trident smashes
				Rader.ActionQueue.Event(this, n"SlamLeft");
				Rader.ActionQueue.Idle(0.4);
				Rader.ActionQueue.Event(this, n"SlamHit");
				Rader.ActionQueue.Idle(1.1);
				Rader.ActionQueue.Event(this, n"SlamRight");
				Rader.ActionQueue.Idle(0.4);
				Rader.ActionQueue.Event(this, n"SlamHit");
				Rader.ActionQueue.Idle(1.1);
				Rader.ActionQueue.Event(this, n"SlamMiddle");
				Rader.ActionQueue.Idle(0.4);
				Rader.ActionQueue.Event(this, n"SlamHit");
				Rader.ActionQueue.Idle(1.1);

				Rader.ActionQueue.Event(this, n"StopTridentSlam");
				Rader.ActionQueue.Idle(1.0);
			}
		}
		else
		{
			if (!bHasFinished)
			{
				Rader.ActionQueue.Empty();
				bHasFinished = true;
				UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_TridentPhaseEnd(Rader);

				Timer::SetTimer(this, n"HideTridentAfterRaderDeath", 2.0);
			}
		}
	}

	UFUNCTION()
	private void HideTridentAfterRaderDeath()
	{
		Rader.Trident.AddActorDisable(n"RaderDead");
	}

	UFUNCTION()
	private void StartTridentSlam()
	{
		Rader.bIsSlammingTrident = true;
	}

	UFUNCTION()
	private void SlamLeft()
	{
		Rader.TridentHitLocation = EMeltdownPhasTwoTridentHitLocation::Left;
		Rader.LastTridentAttackFrame = GFrameNumber;
		UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_TridentSlamStart(Rader);
	}

	UFUNCTION()
	private void SlamRight()
	{
		Rader.TridentHitLocation = EMeltdownPhasTwoTridentHitLocation::Right;
		Rader.LastTridentAttackFrame = GFrameNumber;
		UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_TridentSlamStart(Rader);
	}

	UFUNCTION()
	private void SlamMiddle()
	{
		Rader.TridentHitLocation = EMeltdownPhasTwoTridentHitLocation::Mid;
		Rader.LastTridentAttackFrame = GFrameNumber;
		UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_TridentSlamStart(Rader);
	}

	UFUNCTION()
	private void SlamHit()
	{
		FTransform AttachTransform = Rader.Trident.ActorTransform;

		FVector SlamLocation = AttachTransform.Location;
		SlamLocation.Z = Rader.TridentBarrageAttack.TargetBox.WorldLocation.Z + 50.0;

		FVector SlamDirection = (AttachTransform.Rotation.ForwardVector).GetSafeNormal2D();
		FVector SlamRight = AttachTransform.Rotation.RightVector.GetSafeNormal2D();

		SpawnActor(Rader.TridentForwardSlamClass, SlamLocation, FRotator::MakeFromX(SlamDirection));

		FMeltdownBossTridentSlamHitParams HitParams;
		HitParams.HitLocation = SlamLocation;
		UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_TridentSlamHit(Rader, HitParams);
	}

	UFUNCTION()
	private void StopTridentSlam()
	{
		Rader.bIsSlammingTrident = false;
	}

	UFUNCTION()
	private void StartSharkAttack()
	{
		Rader.bIsSummoningSharks = true;
		UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_SharkSummonStart(Rader);
	}

	UFUNCTION()
	private void FinishSharkAttack()
	{
		Rader.bIsSummoningSharks = false;
		UMeltdownBossPhaseTwoTridentEffectHandler::Trigger_SharkSummonEnd(Rader);
	}

	UFUNCTION()
	private void LaunchSharks()
	{
		{
			FMeltdownBossPhaseTwoBarrageConfig Config;
			Config.ProjectileCount = 1;
			Config.StartLaunchingDelay = 1.5;
			Config.ProjectileSpeed = 6500.0;
			Config.ProjectileGravity = 2000.0;
			Config.ExplosionRadius = 200.0;
			Config.TargetingType = EMeltdownBossBarrageAttackTargetingType::Zoe; 
			Config.TargetingPredictionDistance = 300.0;
			Rader.TridentBarrageAttack.StartAttack(Config);
		}

		{
			FMeltdownBossPhaseTwoBarrageConfig Config;
			Config.ProjectileCount = 1;
			Config.ProjectileSpeed = 6500.0;
			Config.ProjectileGravity = 2000.0;
			Config.ExplosionRadius = 200.0;
			Config.TargetingType = EMeltdownBossBarrageAttackTargetingType::Mio; 
			Config.TargetingPredictionDistance = 300.0;
			Rader.TridentBarrageAttack.StartAttack(Config);
		}
	}
};
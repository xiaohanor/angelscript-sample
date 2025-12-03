class UMeltdownPhaseOneSlamCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseOne Rader;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseOne>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Rader.ActionQueue.IsEmpty())
			return false;
		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::Slam)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::Slam && Rader.CurrentAttack != EMeltdownPhaseOneAttack::None)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Rader.ActionQueue.Idle(1.13);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.ActionQueue.Empty();
		Rader.SlamGridPositioner.ResetToOriginalPosition(3.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"Slam", this);

		// If we've run out of queued attacks, queue up a new sequence
		if (Rader.ActionQueue.IsEmpty() && Rader.CurrentAttack == EMeltdownPhaseOneAttack::Slam)
		{
			Rader.ActionQueue.Event(this, n"StartSmashRight");
			Rader.ActionQueue.Idle(0.82);
			Rader.ActionQueue.Event(this, n"SmashRight");
			Rader.ActionQueue.Idle(1.18);

			Rader.ActionQueue.Event(this, n"StartSmashLeft");
			Rader.ActionQueue.Idle(0.82);
			Rader.ActionQueue.Event(this, n"SmashLeft");
			Rader.ActionQueue.Idle(1.18);
		}
	}

	void SpawnShockwave(FVector Location)
	{
		AMeltdownBossPhaseOneShockwave Shockwave = AMeltdownBossPhaseOneShockwave::Spawn(Location);
		Shockwave.Speed = 800;
		Shockwave.MaxRadius = 5000;
		Shockwave.InitialRadius = 1000;
		Shockwave.Width = 100;
		Shockwave.Displacement = FVector(0, 0, 200);
		Shockwave.bAutoDestroy = true;
		Shockwave.ActivateShockwave();
	}

	UFUNCTION()
	private void StartSmashLeft()
	{
		UMeltdownPhaseOneSlamEffectHandler::Trigger_StartSlamLeft(Rader);
		StartSmash();
	}

	UFUNCTION()
	private void StartSmashRight()
	{
		UMeltdownPhaseOneSlamEffectHandler::Trigger_StartSlamRight(Rader);
		StartSmash();
	}	

	UFUNCTION()
	private void StartSmash()
	{
		Rader.LastSlamFrame = GFrameNumber;
	}

	UFUNCTION()
	private void SmashRight()
	{
		FVector Location = Rader.Mesh.GetSocketLocation(n"RightHand");
		SpawnShockwave(Location);

		Rader.SlamGridPositioner.AccelerateToPosition(0, 1.0);
		
		// Debug::DrawDebugSphere(Location, 1200, Duration = 10);

		TriggerKillPlayersFistHit(true, Location);
	}

	UFUNCTION()
	private void SmashLeft()
	{
		FVector Location = Rader.Mesh.GetSocketLocation(n"LeftHand");
		SpawnShockwave(Location);

		Rader.SlamGridPositioner.AccelerateToPosition(1, 1.0);
		
		// Debug::DrawDebugSphere(Location, 1200, Duration = 10);

		TriggerKillPlayersFistHit(false, Location);
	}

	UFUNCTION()
	void TriggerKillPlayersFistHit(bool bWasRightFist, FVector HitLocation)
	{
		FMeltdownPhaseOneSlamHitParams HitParams;
		HitParams.HitLocation = HitLocation;
		HitParams.bWasRightFist = bWasRightFist;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerInvulnerable())
				continue;
			if (Overlap::QueryShapeOverlap(
				Player.CapsuleComponent.GetCollisionShape(),
				Player.CapsuleComponent.WorldTransform,
				FCollisionShape::MakeSphere(1200),
				FTransform(HitLocation),
			))
			{
				Player.KillPlayer();
				if (Player.IsMio())
					HitParams.bHitMio = true;
				else
					HitParams.bHitZoe = true;
			}
		}

		UMeltdownPhaseOneSlamEffectHandler::Trigger_FistHit(Rader, HitParams);
	}
};

struct FMeltdownPhaseOneSlamHitParams
{
	UPROPERTY()
	FVector HitLocation;
	UPROPERTY()
	bool bWasRightFist = false;
	UPROPERTY()
	bool bHitMio = false;
	UPROPERTY()
	bool bHitZoe = false;
}

UCLASS(Abstract)
class UMeltdownPhaseOneSlamEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSlamLeft() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSlamRight() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FistHit(FMeltdownPhaseOneSlamHitParams Params) {}
}
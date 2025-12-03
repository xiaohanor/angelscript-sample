class UMeltdownPhaseOneShockwaveArrowAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseOne Rader;

	int AttackIndex = -1;
	AMeltdownBossPhaseOneMissileAttack CurrentMissile;
	FName CurrentSocket;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseOne>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::ShockwaveArrow && Rader.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::ShockwaveArrow)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Rader.ActionQueue.NetworkSyncPoint(this);
		Rader.ActionQueue.Idle(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::None)
			Rader.ActionQueue.Empty();
		Rader.ShockwaveArrowGridPositioner.ResetToOriginalPosition(1.0);

		if (CurrentMissile != nullptr)
		{
			CurrentMissile.AddActorDisable(this);
			CurrentMissile = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"ShockwaveArrow", this);
		
		if (Rader.ActionQueue.IsEmpty() && Rader.CurrentAttack == EMeltdownPhaseOneAttack::ShockwaveArrow)
		{
			AttackIndex = Math::WrapIndex(AttackIndex + 1, 0, Rader.ShockwaveArrowAttacks.Num());

			if (AttackIndex % 2 == 0)
			{
				CurrentSocket = n"LeftAttach";
				Rader.LastShootLeftHandFrame = GFrameNumber;
			}
			else
			{
				CurrentSocket = n"RightAttach";
				Rader.LastShootRightHandFrame = GFrameNumber;
			}
			Rader.ActionQueue.Idle(0.81);
			Rader.ActionQueue.Event(this, n"SpawnMissile");
			Rader.ActionQueue.Event(this, n"FireAttack");
			Rader.ActionQueue.Duration(1.09, this, n"ScaleDownMissile");
		}

		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::None)
		{
			for (AMeltdownBossPhaseOneMissileAttack Missile : Rader.ShockwaveArrowAttacks)
				Missile.AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void SpawnMissile()
	{
		CurrentMissile = Rader.ShockwaveArrowAttacks[AttackIndex];
		CurrentMissile.ProjectileRoot.SetAbsolute(false, false, true);
		CurrentMissile.ProjectileRoot.AttachToComponent(Rader.Mesh, CurrentSocket);
		CurrentMissile.ProjectileRoot.SetHiddenInGame(false, true);

		FMeltdownBossPhaseOneMissileSpawnParams SpawnParams;
		SpawnParams.MissileLocation = CurrentMissile.ProjectileRoot.WorldLocation;
		SpawnParams.TargetLocation = CurrentMissile.ActorLocation;
		UMeltdownBossPhaseOneMissileAttackEffectHandler::Trigger_SpawnMissile(CurrentMissile, SpawnParams);
	}

	UFUNCTION()
	private void ScaleDownMissile(float Alpha)
	{
		CurrentMissile.ProjectileRoot.SetWorldScale3D(FVector(Math::Lerp(4, 1, Alpha)));
	}

	UFUNCTION()
	private void BendArena()
	{
		if (IsActive())
		{
			Rader.ShockwaveArrowGridPositioner.AccelerateToPosition(
				Math::WrapIndex(AttackIndex, 0, 3), 5.0
			);
		}
	}

	UFUNCTION()
	private void FireAttack()
	{
		CurrentMissile.ProjectileRoot.SetWorldScale3D(FVector(1));
		CurrentMissile.MissileHit.UnbindObject(this);
		CurrentMissile.MissileHit.AddUFunction(this, n"BendArena");

		CurrentMissile.ProjectileRoot.DetachFromParent(true);
		CurrentMissile.FireMissile();
	}
};
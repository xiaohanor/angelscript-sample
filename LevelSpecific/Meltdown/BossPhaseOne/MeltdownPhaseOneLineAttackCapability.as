class UMeltdownPhaseOneLineAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseOne Rader;

	AMeltdownBossPhaseOneLineAttack LineAttack;
	AHazePlayerCharacter TargetPlayer;

	FHazeAcceleratedVector AccRaderPosition;
	float TargetArenaOffset = 0.0;
	int AttackIndex = -1;

	bool bAttackLeftHand = false;
	bool bHasFinished = false;
	bool bStartAnimating = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseOne>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::Line)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::Line && Rader.CurrentAttack != EMeltdownPhaseOneAttack::None)
			return true;
		if (bHasFinished && Rader.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasFinished = false;
		bStartAnimating = false;
		Rader.ActionQueue.NetworkSyncPoint(this);
		Rader.ActionQueue.Event(this, n"StartAnimation");
		Rader.ActionQueue.Idle(3.0);

		AccRaderPosition.SnapTo(Rader.ActorLocation);
	}

	UFUNCTION()
	private void StartAnimation()
	{
		bStartAnimating = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHasFinished && Rader.CurrentAttack != EMeltdownPhaseOneAttack::Line)
		{
			bHasFinished = true;
			Rader.ActionQueue.Duration(1.0, this, n"ResetPosition");
			Rader.ActionQueue.Idle(1.0);
		}

		if (Rader.Mesh.CanRequestLocomotion() && bStartAnimating)
			Rader.Mesh.RequestLocomotion(n"LineAttack", this);

		if (Rader.ActionQueue.IsEmpty() && Rader.CurrentAttack == EMeltdownPhaseOneAttack::Line)
		{
			const float AttackPoint = 0.35;
			Rader.ActionQueue.Event(this, n"StartAttack");
			Rader.ActionQueue.Duration(1.0 - AttackPoint, this, n"TrackAttack");
			Rader.ActionQueue.Event(this, n"AnimateAttack");
			Rader.ActionQueue.Idle(AttackPoint);
			Rader.ActionQueue.Event(this, n"LaunchAttack");
			Rader.ActionQueue.Idle(0.5);
		}

		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::Line)
		{
			FVector TargetLocation = Rader.GetRaderLocationAtArenaOffset(TargetArenaOffset);
			AccRaderPosition.AccelerateTo(TargetLocation, 2.0, DeltaTime);

			Rader.ActorLocation = AccRaderPosition.Value;
			Rader.LateralVelocity = Math::Clamp(Rader.ArenaRoot.ActorTransform.InverseTransformVector(AccRaderPosition.Velocity).X / 2000, -1, 1);
			if (Math::Abs(Rader.LateralVelocity) < 0.05)
				Rader.LateralVelocity = 0.0;

			TEMPORAL_LOG(this)
				.Value("LateralVelocity", Rader.LateralVelocity)
				.Value("Location", Rader.ActorLocation)
				.Value("AccVelocity", AccRaderPosition.Velocity)
			;
		}
	}

	UFUNCTION()
	private void ResetPosition(float Alpha)
	{
		Rader.ActorLocation = Math::Lerp(
			AccRaderPosition.Value, Rader.OriginalTransform.Location,
			Math::EaseInOut(0, 1, Alpha, 2)
		);
	}

	UFUNCTION()
	private void TrackAttack(float Alpha)
	{
		Rader.LeftHandTrackingValue = Rader.GetPositionWithinArena(TargetPlayer.ActorLocation).X;
		Rader.RightHandTrackingValue = Rader.LeftHandTrackingValue;
	}

	UFUNCTION()
	private void AnimateAttack()
	{
		if (bAttackLeftHand)
			Rader.LastShootLeftHandFrame = GFrameNumber;
		else
			Rader.LastShootRightHandFrame = GFrameNumber;
	}

	UFUNCTION()
	private void StartAttack()
	{
		AttackIndex = Math::WrapIndex(AttackIndex+1, 0, Rader.LineAttacks.Num());
		LineAttack = Rader.LineAttacks[AttackIndex];

		if (AttackIndex % 2 == 0)
			TargetPlayer = Game::Zoe;
		else
			TargetPlayer = Game::Mio;

		FVector2D AttackLocation = Rader.GetPositionWithinArena(LineAttack.ActorLocation);
		TargetArenaOffset = AttackLocation.X;
		bAttackLeftHand = TargetArenaOffset >= 0.0;

		LineAttack.bCreateChasm = Rader.bLineAttacksCauseChasms && !TargetPlayer.IsPlayerDead();
		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::Line)
		{
			LineAttack.TriggerAttack();
			LineAttack.HomeAttackOnPlayer(TargetPlayer, 1.0);
		}
	}

	UFUNCTION()
	private void LaunchAttack()
	{
		FMeltdownPhaseOneLineAttackLaunchParams Params;
		if (bAttackLeftHand)
			Params.RaderHandLocation = Rader.Mesh.GetSocketLocation(n"LeftHand");
		else
			Params.RaderHandLocation = Rader.Mesh.GetSocketLocation(n"RightHand");
		Params.LineAttackStartLocation = LineAttack.ActorLocation;

		FVector WorldLineStart = LineAttack.ActorLocation;
		FVector WorldLineEnd = LineAttack.ActorTransform.TransformPosition(LineAttack.LineEnd);
		Params.LineAttackDirection = (WorldLineEnd - WorldLineStart).GetSafeNormal();

		UMeltdownPhaseOneLineAttackEffectHandler::Trigger_LaunchLineAttack(Rader, Params);
	}
}

struct FMeltdownPhaseOneLineAttackLaunchParams
{
	UPROPERTY()
	FVector RaderHandLocation;
	UPROPERTY()
	FVector LineAttackStartLocation;
	UPROPERTY()
	FVector LineAttackDirection;
}

UCLASS(Abstract)
class UMeltdownPhaseOneLineAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchLineAttack(FMeltdownPhaseOneLineAttackLaunchParams Params) {}
}
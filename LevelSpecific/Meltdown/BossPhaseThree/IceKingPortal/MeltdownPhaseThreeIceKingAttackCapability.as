class UMeltdownPhaseThreeIceKingAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 120; 

	AMeltdownPhaseThreeBoss Rader;
	AMeltdownPhaseThreeIceKing IceKing;

	FHazeAcceleratedRotator RaderRotation;
	FRotator RaderTargetRotation;

	bool bHasFinished = false;
	bool bShouldAnimate = false;
	int SpawnCounter = 0;

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
		if (Rader.CurrentAttack == EMeltdownPhaseThreeAttack::IceKing)
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
		Rader.CurrentLocomotionTag = NAME_None;
		bHasFinished = false;
		bShouldAnimate = false;

		RaderTargetRotation = Rader.ActorRotation;
		RaderRotation.SnapTo(RaderTargetRotation);

		IceKing = SpawnActor(Rader.IceKingClass);
		IceKing.MakeNetworked(this, SpawnCounter);
		IceKing.Rader = Rader;
		SpawnCounter += 1;

		Rader.ActionQueue.NetworkSyncPoint(this);
		Rader.ActionQueue.Event(this, n"StartAnimating");
		Rader.ActionQueue.Idle(3.0);
		Rader.ActionQueue.Event(IceKing, n"LaunchFromPortal");
		Rader.ActionQueue.IdleUntil(this, n"CheckIceKingDead");
		Rader.ActionQueue.Event(this, n"StopAnimating");
		Rader.ActionQueue.Idle(1.5);
		Rader.ActionQueue.Event(this, n"HidePortal");
		Rader.ActionQueue.Idle(2.07);

		Rader.ActionQueue.Event(this, n"AttackOver");
	}

	UFUNCTION()
	private bool CheckIceKingDead()
	{
		if (IsValid(IceKing))
			return false;
		return true;
	}

	UFUNCTION()
	private void AttackOver()
	{
		bHasFinished = true;
		bShouldAnimate = false;
		Rader.PortalLocomotionTag = NAME_None;
		Rader.StopAttacking();
		Rader.OnIceKingAttackFinished.Broadcast();
	}

	UFUNCTION()
	private void StartAnimating()
	{
		Rader.bIsAttacking = true;
		Rader.PortalLocomotionTag = n"DecimatorPortal";
		bShouldAnimate = true;
		UMeltdownPhaseThreeIceKingAttackEffectHandler::Trigger_StartIceKingAttack(Rader);
	}

	UFUNCTION()
	private void StopAnimating()
	{
		Rader.bIsAttacking = false;
	}

	UFUNCTION()
	private void HidePortal()
	{
		Rader.PortalLocomotionTag = NAME_None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMeltdownPhaseThreeIceKingAttackEffectHandler::Trigger_FinishIceKingAttack(Rader);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bShouldAnimate && Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"DecimatorPortal", this);

		RaderRotation.AccelerateToWithStop(RaderTargetRotation, 1.0, DeltaTime, 1.0);
		Rader.SetActorRotation(RaderRotation.Value);
	}
};

UCLASS(Abstract)
class UMeltdownPhaseThreeIceKingAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartIceKingAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishIceKingAttack() {}
}
class UMeltdownPhaseThreeDecimatorAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 120; 

	AMeltdownPhaseThreeBoss Rader;
	AMeltdownPhaseThreeDecimator Decimator;

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
		if (Rader.CurrentAttack == EMeltdownPhaseThreeAttack::Decimator)
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

		Decimator = SpawnActor(Rader.DecimatorClass);
		Decimator.MakeNetworked(this, SpawnCounter);
		Decimator.Rader = Rader;
		SpawnCounter += 1;

		Rader.ActionQueue.NetworkSyncPoint(this);
		Rader.ActionQueue.Event(this, n"StartAnimating");
		Rader.ActionQueue.Idle(3.0);
		Rader.ActionQueue.Event(Decimator, n"LaunchFromPortal");
		Rader.ActionQueue.IdleUntil(this, n"CheckDecimatorDead");
		Rader.ActionQueue.Event(this, n"StopAnimating");
		Rader.ActionQueue.Idle(1.5);
		Rader.ActionQueue.Event(this, n"HidePortal");
		Rader.ActionQueue.Idle(2.07);
		Rader.ActionQueue.Event(this, n"AttackOver");
	}

	UFUNCTION()
	private bool CheckDecimatorDead()
	{
		if (IsValid(Decimator))
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
		Rader.OnDecimatorAttackFinished.Broadcast();
	}

	UFUNCTION()
	private void StartAnimating()
	{
		Rader.bIsAttacking = true;
		Rader.PortalLocomotionTag = n"DecimatorPortal";
		bShouldAnimate = true;
		UMeltdownPhaseThreeDecimatorAttackEffectHandler::Trigger_StartDecimatorAttack(Rader);
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
		UMeltdownPhaseThreeDecimatorAttackEffectHandler::Trigger_FinishDecimatorAttack(Rader);
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
class UMeltdownPhaseThreeDecimatorAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartDecimatorAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishDecimatorAttack() {}
}
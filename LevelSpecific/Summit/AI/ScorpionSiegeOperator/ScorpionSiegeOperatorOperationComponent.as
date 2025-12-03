class UScorpionSiegeOperatorOperationComponent : UActorComponent
{
	AScorpionSiegeWeapon TargetWeapon;
	AScorpionSiegeOperator Operator;
	bool bOperating = false;
	USphereComponent OperatorSlot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetWeapon = nullptr;
		Operator = Cast<AScorpionSiegeOperator>(Owner);

		Operator.RespawnComp.OnRespawn.AddUFunction(this, n"ResetTarget");
		Operator.HealthComp.OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		ResetTarget();
	}

	UFUNCTION()
	private void ResetTarget()
	{
		if(TargetWeapon == nullptr) return;
		OperatorSlot = nullptr;
		bOperating = false;
		TargetWeapon.Manager.Operators.Remove(Operator);
		TargetWeapon = nullptr;
	}
}
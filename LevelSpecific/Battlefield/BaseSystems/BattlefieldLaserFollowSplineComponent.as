class UBattlefieldLaserFollowSplineComponent : UActorComponent
{
	UBattlefieldLaserComponent LaserComp;
	ABattlefieldAttackFollowSpline FollowSplineAttack;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserComp = UBattlefieldLaserComponent::Get(Owner);
		FollowSplineAttack = Cast<ABattlefieldAttackFollowSpline>(Owner);
		FollowSplineAttack.OnBattlefieldAttackFollowStarted.AddUFunction(this, n"OnBattlefieldAttackFollowStarted");
		FollowSplineAttack.OnBattlefieldAttackFollowEnded.AddUFunction(this, n"OnBattlefieldAttackFollowEnded");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!FollowSplineAttack.bMakingRun)
			return;	

		LaserComp.SetLaserEndPosition(FollowSplineAttack.Location);
	}

	UFUNCTION()
	private void OnBattlefieldAttackFollowStarted(FVector EndPoint)
	{
		LaserComp.ActivateLaser(EndPoint);
	}

	UFUNCTION()
	private void OnBattlefieldAttackFollowEnded()
	{
		LaserComp.DeactivateLaser();
	}
}
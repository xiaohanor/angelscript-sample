class UBattlefieldProjectileFollowSplineComponent : UActorComponent
{
	UBattlefieldProjectileComponent ProjectileComp;
	ABattlefieldAttackFollowSpline FollowSplineAttack;

	float FireTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp = UBattlefieldProjectileComponent::Get(Owner);
		FollowSplineAttack = Cast<ABattlefieldAttackFollowSpline>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!FollowSplineAttack.bMakingRun)
			return;
		
		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + ProjectileComp.FireRate;
			ProjectileComp.ManualSpawnProjectile(FollowSplineAttack.Direction);
		}
	}
}
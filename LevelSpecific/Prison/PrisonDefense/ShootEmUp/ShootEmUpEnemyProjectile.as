class AShootEmUpEnemyProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProjectileRoot;

	float Lifetime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector DeltaMove = ActorForwardVector * 2000.0 * DeltaTime;
		
		SetActorLocation(ActorLocation + DeltaMove);

		Lifetime += DeltaTime;
		if (Lifetime >= 12.0)
			DestroyActor();
	}
}
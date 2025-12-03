class ABattlefieldTankProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraComp;

	float Speed = 50000.0;

	float LifeTime = 10.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += ActorForwardVector * Speed * DeltaSeconds;

		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
			DestroyActor();
	}
};
class ASkylineGravityBikeExplodableWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBikeWhipThrowTargetComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UPROPERTY()
	UNiagaraSystem NiagaraSystem;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp.OnDeath.AddUFunction(this, n"HandleDeath");
	}

	UFUNCTION()
	private void HandleDeath(FGravityBikeSplineEnemyDeathData DeathData)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraSystem, ActorLocation);
		AddActorDisable(this);
	}
};
class AMeltdownBossBattlePhaseOneRotatingWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Cube;

	UPROPERTY(EditAnywhere)
	float Speed = 10;

	UPROPERTY(EditAnywhere)
	float Lifetime = 10;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(DefaultComponent )
	UMeltdownBossCubeGridDisplacementComponent DisplaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
//		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorWorldOffset(ActorForwardVector * Speed);
	}
};
class AMeltdownBossPhaseThreeArena : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Base;
	default Base.SetHiddenInGame(true);
	default Base.SetCollisionEnabled(ECollisionEnabled::NoCollision);


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartArena()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void StopArena()
	{
		AddActorDisable(this);
	}
};
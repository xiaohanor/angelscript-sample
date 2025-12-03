class AIslandFactoryPerchObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	void StartDestroyTimer()
	{
		Timer::SetTimer(this, n"DestroyObject", 3);
	}

	UFUNCTION()
	private void DestroyObject()
	{
		DestroyActor();
	}

	UFUNCTION()
	private void OnImpact(AActor OverlappedActor, AActor OtherActor)
	{
		DestroyActor();
	}
};
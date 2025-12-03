class AOilPuddle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent PuddleDecal;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem OilSplash;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
	private void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(OilSplash, OtherActor.ActorLocation + FVector::DownVector * 20);

		UDroneOilCoatComponent OilComp = UDroneOilCoatComponent::Get(OtherActor);
		if(OilComp == nullptr)
			return;

		OilComp.EnterOilPuddle();
	}

	UFUNCTION()
	private void OnEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		UDroneOilCoatComponent OilComp = UDroneOilCoatComponent::Get(OtherActor);
		if(OilComp == nullptr)
			return;

		OilComp.ExitOilPuddle();
	}
};
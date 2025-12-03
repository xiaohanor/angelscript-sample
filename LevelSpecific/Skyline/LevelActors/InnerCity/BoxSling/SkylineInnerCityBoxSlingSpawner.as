event void FOnSkylineInnerCityBoxNewSlingLanded(ASkylineInnerCityBoxSling Box);

class ASkylineInnerCityBoxSlingSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LaunchPoint;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	float SpawnVelocity = 0.0;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineInnerCityBoxSling> WhipSlingableObjectClass;

	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToIgnore;

	UPROPERTY(EditInstanceOnly)
	ASkylineInnerCityBoxSlingDeliveryBot DeliveryBot;

	UPROPERTY(EditInstanceOnly)
	ASkylineInnerCityBoxSlingDeliveryBot BackupDeliveryBot;

	int SpawnedBoxiz = 0;
	bool bHasSpawnRequest = false;

	UPROPERTY(EditAnywhere)
	FOnSkylineInnerCityBoxNewSlingLanded OnSkylineInnerCityBoxSlingLanded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DelaySpawnBoxiz();
		DeliveryBot.MySpawner = this;
		BackupDeliveryBot.MySpawner = this;
	}

	private void DelaySpawnBoxiz()
	{
		if (!bHasSpawnRequest)
			Timer::SetTimer(this, n"SpawnBoxiz", 3.0);
		bHasSpawnRequest = true;
	}

	UFUNCTION()
	private void SpawnBoxiz()
	{
		if (DeliveryBot != nullptr && DeliveryBot.bDelivering && BackupDeliveryBot != nullptr && BackupDeliveryBot.bDelivering)
		{
			DelaySpawnBoxiz();
			return;
		}
		bHasSpawnRequest = false;
		if (HasControl())
		{
			CrumbSpawnBoxis(SpawnedBoxiz);
			SpawnedBoxiz++;
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnBoxis(int NumberID)
	{
		auto Boxiz = SpawnActor(WhipSlingableObjectClass,LaunchPoint.WorldLocation,LaunchPoint.WorldRotation, bDeferredSpawn = true);
		Boxiz.MakeNetworked(this, NumberID);
		Boxiz.SetActorControlSide(Game::Mio);
		Boxiz.OnSkylineInnerCityBoxSlingRecyclePlz.AddUFunction(this, n"AnotherBox");
		//Boxiz.OnDestroyed.AddUFunction(this, n"NewBoxPlz");
		FinishSpawningActor(Boxiz);
		if (DeliveryBot != nullptr && !DeliveryBot.bDelivering)
			DeliveryBot.SetBox(Boxiz);
		else if (BackupDeliveryBot != nullptr && !BackupDeliveryBot.bDelivering)
			BackupDeliveryBot.SetBox(Boxiz);
	}

	UFUNCTION()
	void NewBoxPlz(AActor Destoryed)
	{
		SpawnBoxiz();
	}

	UFUNCTION()
	void AnotherBox()
	{
		SpawnBoxiz();
	}
};
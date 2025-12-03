class ASummitBabyDragonFruitBush : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<ASummitBabyDragonFruit> FruitClass;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FruitGrowDelay = 2.0;

	UPROPERTY(DefaultComponent)
	USceneComponent FruitRootParent;

	TArray<USceneComponent> FruitAttachments;
	TMap<ASummitBabyDragonFruit, USceneComponent> AttachmentsPerFruit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FruitRootParent.GetChildrenComponentsByClass(USceneComponent, false, FruitAttachments);
		for(int i = 0; i < FruitAttachments.Num(); i++)
		{
			auto FruitActor = SpawnActor(FruitClass, bDeferredSpawn = true);
			auto Fruit = Cast<ASummitBabyDragonFruit>(FruitActor);
			Fruit.MakeNetworked(this, i);
			FinishSpawningActor(Fruit);
			Fruit.SetActorLocation(FruitAttachments[i].WorldLocation);
			Fruit.SetActorRotation(FruitAttachments[i].WorldRotation);
			Fruit.Spawn(this);
			AttachmentsPerFruit.Add(Fruit, FruitAttachments[i]);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto It : AttachmentsPerFruit)
		{
			auto Fruit = It.Key;

			if(Fruit.IsActorDisabled())
			{
				Fruit.Spawn(this);
				Fruit.ActorLocation = It.Value.WorldLocation;
				Fruit.ActorRotation = It.Value.WorldRotation;
			}
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		TArray<USceneComponent> TempFruitAttachments;
		FruitRootParent.GetChildrenComponentsByClass(USceneComponent, false, TempFruitAttachments);
		for(auto FruitAttachment : TempFruitAttachments)
		{
			Debug::DrawDebugSphere(FruitAttachment.WorldLocation, 20, 12, FLinearColor::DPink, 1);
		}	
	}
#endif
};
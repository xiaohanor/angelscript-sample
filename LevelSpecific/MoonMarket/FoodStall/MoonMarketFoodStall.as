class AMoonMarketFoodStall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Stall;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;
	FMoveToParams MoveParams;
	default MoveParams.Type = EMoveToType::NoMovement;
	default InteractComp.MovementSettings = MoveParams;

	TArray<AMoonMarketFood> FoodArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		TArray<AActor> OutActors;
		GetAttachedActors(OutActors);
		for (AActor Actor : OutActors)
		{
			auto NewFood = Cast<AMoonMarketFood>(Actor);
			if (NewFood != nullptr)
				FoodArray.AddUnique(NewFood);
		}
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		if (FoodArray.Num() == 0)
			return;

		if (FoodArray.Num() > 1)
		{
			int R = Math::RandRange(0, FoodArray.Num() - 1);
			FoodArray[R].DestroyActor();
			FoodArray.RemoveAt(R);
		}
		else
		{
			FoodArray[0].DestroyActor();
			FoodArray.RemoveAt(0);			
			InteractionComponent.Disable(this);
		}
	}
};
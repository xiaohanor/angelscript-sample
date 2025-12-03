event void FOnSummitBrazierPuzzleCompleted();

class ABrazierPuzzleManager : AHazeActor
{
	UPROPERTY()
	FOnSummitBrazierPuzzleCompleted OnSummitBrazierPuzzleCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;

	UPROPERTY(EditAnywhere)
	AActor Pattern1;
	UPROPERTY(EditAnywhere)
	AActor Pattern2;
	UPROPERTY(EditAnywhere)
	AActor Pattern3;

	int CurrentIndex = 1;

	UPROPERTY(EditAnywhere)
	TArray<ASummitSmallBrazier> SmallBraziers1;
	UPROPERTY(EditAnywhere)
	TArray<ASummitSmallBrazier> SmallBraziers2;
	UPROPERTY(EditAnywhere)
	TArray<ASummitSmallBrazier> SmallBraziers3;

	bool bComplete;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivateNextPattern();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CheckPuzzleCompletion();
	}

	void CheckPuzzleCompletion()
	{
		if (bComplete)
			return;
		
		TArray<ASummitSmallBrazier> SmallBraziersToCheck;
		int AmountToCheck = 0;

		switch(CurrentIndex)
		{
			case 1:
				SmallBraziersToCheck = SmallBraziers1;
				AmountToCheck = 3;
				break;

			case 2:
				SmallBraziersToCheck = SmallBraziers2;
				AmountToCheck = 3;
				break;

			case 3:
				SmallBraziersToCheck = SmallBraziers3;
				AmountToCheck = 5;
				break;			
		}

		bool bAllComplete;
		int Amount = 0;

		for (ASummitSmallBrazier Brazier : SmallBraziersToCheck)
		{
			if (Brazier.bIsActive)
				Amount++;
		}

		if (Amount >= AmountToCheck)
		{
			CurrentIndex++;
			ActivateNextPattern();

			if (CurrentIndex > 4)
			{
				OnSummitBrazierPuzzleCompleted.Broadcast();
				bComplete = true;
			}
		}

	}

	void ActivateNextPattern()
	{
		switch(CurrentIndex)
		{
			case 1:
				Pattern1.SetActorHiddenInGame(false);
				Pattern2.SetActorHiddenInGame(true);
				Pattern3.SetActorHiddenInGame(true);
				break;

			case 2:
				Pattern1.SetActorHiddenInGame(true);
				Pattern2.SetActorHiddenInGame(false);
				Pattern3.SetActorHiddenInGame(true);
				break;

			case 3:
				Pattern1.SetActorHiddenInGame(true);
				Pattern2.SetActorHiddenInGame(true);
				Pattern3.SetActorHiddenInGame(false);
				break;
		}
	}
}
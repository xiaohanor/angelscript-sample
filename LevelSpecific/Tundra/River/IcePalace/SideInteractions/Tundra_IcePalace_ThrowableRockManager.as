class ATundra_IcePalace_ThrowableRockManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	int RocksThrown = 0;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_IcePalace_ThrowableRock> Rocks;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Rock : Rocks)
			Rock.OnRockThrown.AddUFunction(this, n"OnRockThrown");
	}

	UFUNCTION()
	private void OnRockThrown(ATundra_IcePalace_ThrowableRock ThrownRock)
	{
		Rocks.Remove(ThrownRock);

		if(Rocks.Num() == 1)
		{
			for(auto Rock : Rocks)
				Rock.SetRockToHitBird();
		}
	}
};
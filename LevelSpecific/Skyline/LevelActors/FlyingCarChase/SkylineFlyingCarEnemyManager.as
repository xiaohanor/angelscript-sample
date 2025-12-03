class ASkylineFlyingCarEnemyManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;
	default BillboardComp.SetWorldScale3D(FVector(5));

	UPROPERTY(DefaultComponent, Attach = Root)
	UTextRenderComponent TextComp;

	UPROPERTY(EditAnywhere)
	int MaxEnemies = 2;
	// UPROPERTY(EditAnywhere)
	// int MaxNetEnemies = 1;	
	// UPROPERTY(EditAnywhere)
	// int MaxShipEnemies = 1;

	int CurrentEnemies;
	// int NetEnemies;
	// int ShipEnemies;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	bool CanAddEnemy(AActor Actor)
	{

		if(CurrentEnemies < MaxEnemies)
			return true;

		return false;
	}

	UFUNCTION()
	void AddEnemy()
	{
		CurrentEnemies++;
		// Print("Enemies: " + CurrentEnemies);
	}


	UFUNCTION()
	void RemoveEnemy()
	{
		CurrentEnemies--;
	}


};
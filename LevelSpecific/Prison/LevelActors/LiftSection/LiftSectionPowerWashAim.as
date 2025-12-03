class ALiftSectionPowerWashAim : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	
	USceneComponent PowerWashStartLocation;
	UPROPERTY(DefaultComponent)
	
	UStaticMeshComponent StaticMesh;
	UPROPERTY(DefaultComponent)

	UBillboardComponent Billboard;

	bool bIsActive = false;
	float FollowSpeed = 10;
	UPROPERTY(EditAnywhere)
	bool bTargetMio = true;
	FVector TargetLocation;
	FHazeAcceleratedFloat AcceleratedfloatX;
	FHazeAcceleratedFloat AcceleratedfloatY;
	FHazeAcceleratedFloat AcceleratedfloatZ;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsActive == false)
			return;

		if(bTargetMio)
			TargetLocation = Game::GetMio().GetActorLocation();
		else
			TargetLocation = Game::GetZoe().GetActorLocation();

		AcceleratedfloatX.SpringTo(TargetLocation.X, 200, 0.8, DeltaTime);
		AcceleratedfloatY.SpringTo(TargetLocation.Y, 30, 0.8, DeltaTime);
		AcceleratedfloatZ.SpringTo(TargetLocation.Z, 30, 0.8, DeltaTime);
	}


	UFUNCTION()
	void StartLaser()
	{
		if(bIsActive)
			return;
		
		SetActorHiddenInGame(false);
		bIsActive = true;
	}
	UFUNCTION()
	void StopLaser()
	{
		SetActorHiddenInGame(true);
		bIsActive = false;
	}
}
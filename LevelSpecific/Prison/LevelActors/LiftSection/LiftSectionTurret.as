UCLASS(Abstract)
class ALiftSectionTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	USceneComponent LaserStartLocation;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMesh;
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshFlameActive;

	UPROPERTY(DefaultComponent)
	UBillboardComponent MoveToLocation;

	float TimeSinceLastHit;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript(){}

	UPROPERTY()
	bool bIsActive = false;


	float FollowSpeed = 10;
	UPROPERTY(EditAnywhere)
	bool bTargetMio = true;

	UPROPERTY()
	FVector TargetLocation;

	AHazePlayerCharacter PlayerTarget;

	FHazeAcceleratedFloat AcceleratedfloatX;
	FHazeAcceleratedFloat AcceleratedfloatY;
	FHazeAcceleratedFloat AcceleratedfloatZ;

	UPROPERTY()
	FVector HitLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaTime)
	// {
	// 	if(bIsActive == false)
	// 		return;

	// 	if(bTargetMio)
	// 	{
	// 		TargetLocation = Game::GetMio().GetActorLocation();
	// 		PlayerTarget = Game::GetMio();
	// 	}
	// 	else
	// 	{
	// 		TargetLocation = Game::GetZoe().GetActorLocation();
	// 		PlayerTarget = Game::GetZoe();
	// 	}

	// 	AcceleratedfloatX.SpringTo(TargetLocation.X, 200, 0.8, DeltaTime);
	// 	AcceleratedfloatY.SpringTo(TargetLocation.Y, 30, 0.8, DeltaTime);
	// 	AcceleratedfloatZ.SpringTo(TargetLocation.Z, 30, 0.8, DeltaTime);

	// 	HitLocation = FVector(AcceleratedfloatX.Value ,AcceleratedfloatY.Value ,AcceleratedfloatZ.Value);

			
	// 	if(HitLocation.PointsAreNear(TargetLocation, 75) && TimeSinceLastHit < GameTimeSinceCreation)
	// 	{
	// 		PlayerTarget.DamagePlayerHealth(0.0833333);
	// 		TimeSinceLastHit = GameTimeSinceCreation + 0.025f;
	// 	}
	// }


	// UFUNCTION()
	// void StartLaser()
	// {
	// 	if(bIsActive)
	// 		return;
			
	// 	AcceleratedfloatX.Value = LaserStartLocation.GetWorldLocation().X;
	// 	AcceleratedfloatY.Value = LaserStartLocation.GetWorldLocation().Y;
	// 	AcceleratedfloatZ.Value = LaserStartLocation.GetWorldLocation().Z;
		
	// 	SetActorHiddenInGame(false);
	// 	bIsActive = true;
	// }
	// UFUNCTION()
	// void StopLaser()
	// {
	// 	SetActorHiddenInGame(true);
	// 	bIsActive = false;
	// }
}
event void FOnSummitTeenDragonPressurePlatePressed();

class ASummitTeenDragonPressurePlate : AHazeActor
{
	UPROPERTY()
	FOnSummitTeenDragonPressurePlatePressed OnSummitTeenDragonPressurePlatePressed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshBaseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshPlateComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EmissiveMat;
	UMaterialInterface DefaultMat;

	TArray<AHazePlayerCharacter> PlayersOverlapping;

	FVector StartPlateLocation;
	FVector OffsetPlateLocation = FVector(0,0,-5);
	FHazeAcceleratedVector AccelVector;

	private bool bIsPressed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		BoxComp.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
		StartPlateLocation = MeshPlateComp.RelativeLocation;
		DefaultMat = MeshPlateComp.GetMaterial(1);
		AccelVector.SnapTo(StartPlateLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector TargetLocation;

		if (bIsPressed)
			TargetLocation = StartPlateLocation + OffsetPlateLocation;
		else
			TargetLocation = StartPlateLocation;

		AccelVector.AccelerateTo(TargetLocation, 0.5, DeltaSeconds);

		MeshPlateComp.RelativeLocation = AccelVector.Value;
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		PlayersOverlapping.AddUnique(Player);
		
		if (!bIsPressed)
		{
			bIsPressed = true;
			MeshPlateComp.SetMaterial(1, EmissiveMat);
			OnSummitTeenDragonPressurePlatePressed.Broadcast();
		}
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		PlayersOverlapping.Remove(Player);
		if (PlayersOverlapping.Num() == 0)
		{
			MeshPlateComp.SetMaterial(1, DefaultMat);
			bIsPressed = false;
		}
	}

	bool IsPressurePlatePressed()
	{
		return bIsPressed;
	}
};
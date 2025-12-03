class AAcidWeightResponder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent WeightEndLocation;
	default WeightEndLocation.SetWorldScale3D(FVector(5.0));
	
	UPROPERTY(EditAnywhere)
	AAcidWeightActor AcidWeightActor;

	FVector StartLocation;
	FVector MoveDirection;
	float MoveDistance;

	FHazeAcceleratedVector AccelVector;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = MeshRoot.RelativeLocation;
		MoveDirection = (WeightEndLocation.RelativeLocation - StartLocation).GetSafeNormal();
		MoveDistance = (WeightEndLocation.RelativeLocation - StartLocation).Size();

		AccelVector.SnapTo(MeshRoot.RelativeLocation);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		AccelVector.AccelerateTo(GetTargetLocation(), 1.5, DeltaSeconds);

		MeshRoot.RelativeLocation = AccelVector.Value;
	}

	FVector GetTargetLocation()
	{
		float MoveValue = MoveDistance * AcidWeightActor.AcidAlpha.Value;
		FVector Target = StartLocation + MoveDirection * MoveValue;

		return Target;
	}



	
}
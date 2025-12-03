class ASummitFloatingStatue : AHazeActor
{
UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	TArray<UStaticMeshComponent> MeshComps;

	UPROPERTY(EditAnywhere)
	ASummitFloatingStatue FloatingStatueTarget; 

	UPROPERTY(EditAnywhere)
	AGiantHorn GiantHorn1;
	UPROPERTY(EditAnywhere)
	AGiantHorn GiantHorn2;

	float MaxRange = 0.8;
	float MinRange = 0.45;

	int HornCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		if (FloatingStatueTarget == nullptr)
		{
			GetComponentsByClass(MeshComps);
			for (UStaticMeshComponent Mesh : MeshComps)
			{
				Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				Mesh.SetHiddenInGame(true);
			}
		}
		else
		{
			GiantHorn1.OnGiantHornActivated.AddUFunction(this, n"OnGiantHornActivated");
			GiantHorn2.OnGiantHornActivated.AddUFunction(this, n"OnGiantHornActivated");
		}
		
		SetActorTickEnabled(false);

	}

	UFUNCTION()
	private void OnGiantHornActivated()
	{
		Print("GiantHorn1.bIsActive: "  +GiantHorn1.bIsActive);
		Print("GiantHorn2.bIsActive: "  +GiantHorn2.bIsActive);
		if (GiantHorn1.bIsActive && GiantHorn2.bIsActive)
			SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (FloatingStatueTarget == nullptr)
			return;

		ActorLocation = Math::VInterpTo(ActorLocation, FloatingStatueTarget.ActorLocation, DeltaSeconds, 1.0);
		ActorRotation = Math::QInterpConstantTo(ActorRotation.Quaternion(), FloatingStatueTarget.ActorQuat, DeltaSeconds, 0.35).Rotator();
	}
}

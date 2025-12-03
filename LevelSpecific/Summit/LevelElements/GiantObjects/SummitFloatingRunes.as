class ASummitFloatingRunes : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitObjectWeightRespondComponent WeightRespondComp;
	default WeightRespondComp.Damping = 1.25;
	default WeightRespondComp.ImpactForce = 325.0;

	UPROPERTY(DefaultComponent, Attach = WeightRespondComp)
	USummitObjectBobbingComponent BobbingComp;
	default BobbingComp.BobbingAmount = 90.0;

	UPROPERTY(DefaultComponent, Attach = BobbingComp)
	USceneComponent MeshRoot;

	TArray<UStaticMeshComponent> MeshComps;

	UPROPERTY(EditAnywhere)
	ASummitFloatingRunes FloatingRuneTarget; 

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
		BobbingComp.BobbingSpeed = Math::RandRange(MinRange, MaxRange);

		if (FloatingRuneTarget == nullptr)
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
		HornCount++;
		SetActorTickEnabled(true);

		if (HornCount >= 2)
			SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (FloatingRuneTarget == nullptr)
			return;

		ActorLocation = Math::VInterpTo(ActorLocation, FloatingRuneTarget.ActorLocation, DeltaSeconds, 1.0);
		ActorRotation = Math::QInterpConstantTo(ActorRotation.Quaternion(), FloatingRuneTarget.ActorQuat, DeltaSeconds, 0.35).Rotator();
	}
}
class AMetalWeightedDownTranslate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent EndComp;
	default EndComp.SetWorldScale3D(FVector(6.0));

	UPROPERTY(EditAnywhere)
	ANightQueenMetal Metal;

	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToAttach;

	FVector StartLoc;
	FVector TargetLoc;
	float MoveSpeed;
	float TargetSpeed = 1000.0;
	float AccelerationRate = 500.0;
	float TotalDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Metal.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		
		if (ActorsToAttach.Num() > 0)
		{
			for (AActor Actor : ActorsToAttach)
			{
				Actor.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			}
		}

		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		Metal.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
		StartLoc = MeshRoot.RelativeLocation;
		TotalDistance = (StartLoc - EndComp.RelativeLocation).Size();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetLoc, DeltaTime, MoveSpeed);

		if (MoveSpeed < TargetSpeed)
			MoveSpeed = Math::FInterpConstantTo(MoveSpeed, TargetSpeed, DeltaTime, AccelerationRate);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		MoveSpeed = 0.0;
		TargetLoc = EndComp.RelativeLocation;
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		MoveSpeed = 0.0;
		TargetLoc = StartLoc;
	}
}
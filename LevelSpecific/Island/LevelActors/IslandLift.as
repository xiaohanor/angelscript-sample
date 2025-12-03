event void FIslandLiftSignature();

class AIslandLift : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetLocationComp;

	UPROPERTY(DefaultComponent, Attach = TargetLocationComp)
	UBillboardComponent BillComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 300;

	FVector StartLocation;
	FVector TargetLocation;

	bool bGoToTarget;

	UPROPERTY()
	FIslandLiftSignature OnActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		DoubleInteract.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		StartLocation = MeshRoot.RelativeLocation;
		TargetLocation = TargetLocationComp.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetLocation, DeltaSeconds, MoveSpeed);
	
		if (HasReachedTarget())
		{
			SetActorTickEnabled(false);
			DoubleInteract.LeftInteraction.Enable(this);
			DoubleInteract.RightInteraction.Enable(this);
		}
	}

	bool HasReachedTarget()
	{
		return (MeshRoot.RelativeLocation - TargetLocation).Size() < 0.05;
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		DoubleInteract.LeftInteraction.Disable(this);
		DoubleInteract.RightInteraction.Disable(this);
		StartLift();
	}

	void StartLift()
	{
		OnActivated.Broadcast();
		SetActorTickEnabled(true);
		bGoToTarget = !bGoToTarget;

		if (bGoToTarget)
			TargetLocation = TargetLocationComp.RelativeLocation;
		else
			TargetLocation = StartLocation;
	}
}
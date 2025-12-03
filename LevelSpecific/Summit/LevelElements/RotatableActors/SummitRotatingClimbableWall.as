enum ESummitRotatingClimbableWallDirection
{
	Left,
	Right
}

class ASummitRotatingClimbableWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailClimbableComponent ClimbComp;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenMetal Metal;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationSpeedTarget = 40.0;
	float RotationSpeed;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DeccelerationSpeed = 100.0;
	float AccelerationSpeed = 50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bRotateSetAmount = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bRotateSetAmount", EditConditionHides))
	float RotationAmountPerMelt;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bRotateSetAmount", EditConditionHides))
	ESummitRotatingClimbableWallDirection RotationDirection;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AActor> AttachActors;

	bool bCanRotate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (AttachActors.Num() > 0)
		{
			for (AActor Actor : AttachActors)
			{
				Actor.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			}
		}

		if (Metal != nullptr)
		{
			Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
			Metal.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
			Metal.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		}
		else
		{
			bCanRotate = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bCanRotate)
		{
			RotationSpeed = Math::FInterpConstantTo(RotationSpeed, 0.0, DeltaTime, DeccelerationSpeed);
		}
		else
		{
			RotationSpeed = Math::FInterpConstantTo(RotationSpeed, RotationSpeedTarget, DeltaTime, AccelerationSpeed);
		}

		MeshRoot.AddRelativeRotation(FRotator(0.0, RotationSpeed * DeltaTime, 0.0));
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		bCanRotate = true;
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		bCanRotate = false;
	}
}
class ASummitSeeSaw  : AHazeActor
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

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenMetal Metal;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationSpeed = 30.0;
	
	float Angle;
	float AngleTarget;
	float Dot;

	bool bGoToTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Dot = MeshRoot.UpVector.DotProduct(FVector::UpVector);
		Angle = Math::RadiansToDegrees(Math::Acos(Dot));
		AngleTarget = Angle;

		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		Metal.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
		Metal.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeRotation = Math::RInterpConstantTo(MeshRoot.RelativeRotation, FRotator(AngleTarget, MeshRoot.RelativeRotation.Yaw, MeshRoot.RelativeRotation.Roll), DeltaSeconds, 25.0);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		AngleTarget = -Angle;
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		AngleTarget = Angle;
	}
}

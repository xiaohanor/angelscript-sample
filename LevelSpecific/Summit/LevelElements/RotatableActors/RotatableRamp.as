class ARotatableRamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UArrowComponent RotationCurrent;
	default RotationCurrent.SetWorldScale3D(FVector(15.0));

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent RotationTarget;
	default RotationTarget.SetWorldScale3D(FVector(15.0));

	UPROPERTY(EditAnywhere)
	AAcidWeightActor AcidWeightActor;

	UPROPERTY(EditAnywhere)
	AActor TEMPAttachedDragonRune;

	FQuat Difference;
	FQuat StartingQuat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingQuat = MeshRoot.RelativeRotation.Quaternion();
		Difference = RotationTarget.RelativeRotation.Quaternion() - StartingQuat;

		if (TEMPAttachedDragonRune != nullptr)
			TEMPAttachedDragonRune.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FQuat TargetQuat = StartingQuat + (Difference * AcidWeightActor.AcidAlpha.Value);
		MeshRoot.RelativeRotation = Math::QInterpTo(MeshRoot.RelativeRotation.Quaternion(), TargetQuat, DeltaSeconds, 1.0).Rotator();
	}
}
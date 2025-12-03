event void FOnHeadStumpTargetSetupSignature(AIslandWalkerHeadStumpTarget Target);

UCLASS(HideCategories = "Rendering ComponentTick Advanced Disable Debug Activation Cooking LOD Collision")
class UIslandWalkerHeadStumpRoot : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandWalkerHeadStumpTarget> StumpTargetClass;

	UPROPERTY()
	EIslandForceFieldType ForceFieldType = EIslandForceFieldType::Red;

	FOnHeadStumpTargetSetupSignature OnStumpTargetSetup;

	UHazeSkeletalMeshComponentBase Mesh;
	AIslandWalkerHeadStumpTarget Target;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	void SetupTarget()
	{
		Target = SpawnActor(StumpTargetClass, bDeferredSpawn = true, Level = Owner.Level);
		Target.MakeNetworked(this, n"StumpTarget");
		Target.OwnerHead = Cast<AHazeCharacter>(Owner);
		Target.ForceFieldComp.WalkerHead = Target.OwnerHead;
		Target.ForceFieldComp.Type = ForceFieldType;
		FinishSpawningActor(Target);
		Target.ForceFieldComp.AttachTo(Target.OwnerHead.Mesh, NAME_None, EAttachLocation::SnapToTarget);

		Target.AttachToComponent(this, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		Target.ActorRelativeRotation = FRotator(90.0, 0.0, 0.0);

		OnStumpTargetSetup.Broadcast(Target);
	}
};



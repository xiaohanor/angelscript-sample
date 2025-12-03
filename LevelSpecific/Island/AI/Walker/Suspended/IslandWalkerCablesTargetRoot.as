event void FOnCablesTargetSetupSignature(AIslandWalkerCablesTarget Target);

UCLASS(HideCategories = "Rendering ComponentTick Advanced Disable Debug Activation Cooking LOD Collision")
class UIslandWalkerCablesTargetRoot : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandWalkerCablesTarget> CablesTargetClass;

	UPROPERTY()
	EIslandForceFieldType ForceFieldType = EIslandForceFieldType::Red;

	FOnCablesTargetSetupSignature OnCablesTargetSetup;

	UHazeSkeletalMeshComponentBase Mesh;
	AIslandWalkerCablesTarget Target;
	AIslandWalkerHead Head;

	const FName BaseBone = n"Head";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	void SetupTarget()
	{
		Target = SpawnActor(CablesTargetClass, bDeferredSpawn = true, Level = Owner.Level);
		Target.MakeNetworked(this, n"CablesTarget");
		Target.OwnerWalker = Cast<AHazeCharacter>(Owner);
		Target.ForceFieldComp.Walker = Target.OwnerWalker;
		Target.ForceFieldComp.Type = ForceFieldType;
		FinishSpawningActor(Target);

		Target.AttachToComponent(this, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);

		OnCablesTargetSetup.Broadcast(Target);
	}
};



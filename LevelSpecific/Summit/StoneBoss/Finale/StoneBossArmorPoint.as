class AStoneBossArmorPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent UpperVisual;
	default UpperVisual.SetWorldScale3D(FVector(10.0));
	default UpperVisual.SetRelativeLocation(FVector(2300.0, 0.0, 0.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UPlayerInheritMovementComponent InheritMovementComp;
	// default InheritMovementComp.

	UPROPERTY(EditAnywhere)
	FName BoneName;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UFUNCTION(CallInEditor)
	void AttachToDragonBone()
	{
		UHazeSkeletalMeshComponentBase SkelMesh = UHazeSkeletalMeshComponentBase::Get(TargetActor); 
		AttachToComponent(SkelMesh, BoneName, EAttachmentRule::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachToDragonBone();

		TArray<AAISummitCritter> Critters;
		TArray<AActor> Childs;
		GetAttachedActors(Childs);

		for (AActor Child : Childs)
		{
			AAISummitCritter Critter = Cast<AAISummitCritter>(Child);
			if (Critter != nullptr)
			{
				Critter.ArmorPoint = this;
			}
		}
	}
};
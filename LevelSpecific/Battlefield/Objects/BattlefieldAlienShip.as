class ABattlefieldAlienShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UBattlefieldBobbingComponent BobbingComp;
	default BobbingComp.Speed = 1.0;
	default BobbingComp.ZAmount = 300.0;

	UPROPERTY(EditAnywhere)
	TArray<AActor> AttachToSkelActors;

	UFUNCTION(CallInEditor)
	void AttachActorsToSkel()
	{
		for (AActor Actor : AttachToSkelActors)
		{
			Actor.AttachToComponent(SkelMesh, n"Base", EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
};
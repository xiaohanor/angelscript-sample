class AIslandSquidAnimationActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SquidMesh;

	UPROPERTY()
	UAnimSequence AnimationToPlay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazePlaySlotAnimationParams Params;
		Params.bLoop = true;
		Params.Animation = AnimationToPlay;
		Params.BlendTime = 0;
		SquidMesh.PlaySlotAnimation(Params);
	}
};
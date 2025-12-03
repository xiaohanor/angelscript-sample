class ASummitDecimatorAnimActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent,Attach = "Root")
	UHazeSkeletalMeshComponentBase SkelMeshBase;

	UPROPERTY()
	UAnimSequence Idle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void PlayIdleAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = Idle;
		Params.BlendTime = 0.5;
		Params.bLoop = true;
		SkelMeshBase.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

};
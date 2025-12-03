class AStonebeastNeckSlotAnimationManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	AHazeSkeletalMeshActor SkelMeshActor;

	UPROPERTY(EditAnywhere)
	UAnimSequence Anim;

	UPROPERTY(EditAnywhere)
	float PlayRate = 1.0;
	
	UFUNCTION()
	void StartAnimation()
	{
		if (Anim == nullptr)
			return;

		FHazeSlotAnimSettings Settings;
		Settings.bLoop = true;
		Settings.PlayRate = PlayRate;
		Settings.BlendTime = 2.0;
		SkelMeshActor.PlaySlotAnimation(Anim, Settings);
	}
};
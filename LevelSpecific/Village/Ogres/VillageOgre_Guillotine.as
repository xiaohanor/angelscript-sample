class AVillageOgre_Guillotine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent OgreRoot;

	UPROPERTY(DefaultComponent, Attach = OgreRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence SeverAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence KnockedDownMh;

	UFUNCTION()
	void SeverHand()
	{
		SkelMeshComp.HideBoneByName(n"RightHand", EPhysBodyOp::PBO_None);

		FHazeAnimationDelegate SeverFinishedDelegate;
		SeverFinishedDelegate.BindUFunction(this, n"SeverFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = SeverAnim;
		SkelMeshComp.PlaySlotAnimation(FHazeAnimationDelegate(), SeverFinishedDelegate, AnimParams);

		BP_SeverHand();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SeverHand() {}

	UFUNCTION()
	private void SeverFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = KnockedDownMh;
		AnimParams.bLoop = true;
		SkelMeshComp.PlaySlotAnimation(AnimParams);
	}
}
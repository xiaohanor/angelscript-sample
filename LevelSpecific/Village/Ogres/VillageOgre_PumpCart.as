class AVillageOgre_PumpCart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent OgreRoot;

	UPROPERTY(DefaultComponent, Attach = OgreRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence JumpAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BalanceAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence FallAnim;

	UFUNCTION()
	void Jump()
	{
		FHazeAnimationDelegate JumpFinishedDelegate;
		JumpFinishedDelegate.BindUFunction(this, n"JumpFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = JumpAnim;
		SkelMeshComp.PlaySlotAnimation(FHazeAnimationDelegate(), JumpFinishedDelegate, AnimParams);
	}

	UFUNCTION()
	private void JumpFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = BalanceAnim;
		AnimParams.bLoop = true;
		SkelMeshComp.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION()
	void FallOff()
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld,EDetachmentRule::KeepWorld);
		FHazeAnimationDelegate FallFinishedDelegate;
		FallFinishedDelegate.BindUFunction(this, n"FallFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = FallAnim;
		SkelMeshComp.PlaySlotAnimation(FHazeAnimationDelegate(), FallFinishedDelegate, AnimParams);
	}

	UFUNCTION()
	private void FallFinished()
	{
		AddActorDisable(this);
	}
}
class ACellBlockJumpScarePrisoner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase PrisonerMeshComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence JumpScareAnim;

	UFUNCTION()
	void ActivateJumpScare()
	{
		FHazeAnimationDelegate AnimFinishedDelegate;
		AnimFinishedDelegate.BindUFunction(this, n"AnimFinished");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = JumpScareAnim;
		AnimParams.BlendTime = 0.0;
		AnimParams.StartTime = 1.0;
		PrisonerMeshComp.PlaySlotAnimation(AnimParams);

		SetActorHiddenInGame(false);

		BP_ActivateJumpScare();

		UJumpScareEffectEventHandler::Trigger_ActivateJumpScare(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateJumpScare() {}

	UFUNCTION()
	private void AnimFinished()
	{
		AddActorDisable(this);
	}
}

class UJumpScareEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ActivateJumpScare() {}
}
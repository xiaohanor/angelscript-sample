UCLASS(Abstract)
class APrisonerChute : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ChuteRoot;

	UPROPERTY(DefaultComponent, Attach = ChuteRoot)
	USceneComponent ChuteAngledRoot;

	UPROPERTY(DefaultComponent, Attach = ChuteRoot)
	USceneComponent PrisonerRoot;

	UPROPERTY(DefaultComponent, Attach = PrisonerRoot)
	UHazeSkeletalMeshComponentBase PrisonerSkelMeshComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PrisonerAnim;

	int PrisonersPerBurst = 6;
	int PrisonersSpawned = 0;
	float BurstSpawnDelay = 0.12;
	FTimerHandle BurstSpawnTimerHandle;

	UFUNCTION()
	void SpawnPrisoners()
	{
		FHazeAnimationDelegate AnimFinishedDelegate;
		AnimFinishedDelegate.BindUFunction(this, n"AnimFinished");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = PrisonerAnim;
		AnimParams.BlendTime = 0.0;
		PrisonerSkelMeshComp.PlaySlotAnimation(FHazeAnimationDelegate(), AnimFinishedDelegate, AnimParams);

		PrisonerSkelMeshComp.SetHiddenInGame(false);

		UPrisonerChuteEffectEventHandler::Trigger_SpawnPrisoners(this);
	}

	UFUNCTION()
	private void AnimFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = PrisonerAnim;
		AnimParams.BlendTime = 0.0;
		AnimParams.PlayRate = 0.0;
		PrisonerSkelMeshComp.PlaySlotAnimation(AnimParams);

		PrisonerSkelMeshComp.SetHiddenInGame(true);
	}
}


class UPrisonerChuteEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void SpawnPrisoners() {}
}
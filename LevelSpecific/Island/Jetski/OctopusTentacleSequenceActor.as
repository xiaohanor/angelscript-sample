class AOctopusTentacleSequenceActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Skelmesh;

	/** Animation to play after the sequence is done */
	UPROPERTY(EditAnywhere)
	UAnimSequence IdleAnim;

	default ActorHiddenInGame = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		Skelmesh.EditorPreviewAnim = IdleAnim;
#endif
	}

	UFUNCTION()
	void PlayIdle()
	{
		SetActorHiddenInGame(false);

		Skelmesh.bPauseAnims = false;

		FHazePlaySlotAnimationParams SlotAnimParams;
		SlotAnimParams.Animation = IdleAnim;
		SlotAnimParams.bLoop = true;

		Skelmesh.PlaySlotAnimation(SlotAnimParams);
	}

};
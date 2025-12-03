enum ESketchbookQuestGiverState
{
	Enter,
	TerribleNews,
	PrinceCaptured,
	Exit
}

UCLASS(Abstract)
class ASketchbookQuestGiver : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Head)
	UStaticMeshComponent Hat;

	UPROPERTY(Category = Animations)
	UAnimSequence EnterAnimation;

	UPROPERTY(Category = Animations)
	UAnimSequence TerribleNews;

	UPROPERTY(Category = Animations)
	UAnimSequence PrinceCaptured;

	UPROPERTY(Category = Animations)
	UAnimSequence Exit;

	UFUNCTION(BlueprintCallable)
	void SetState(ESketchbookQuestGiverState State)
	{
		FHazePlaySlotAnimationParams Params;
		Params.bLoop = true;
		Params.BlendTime = 0;
		FHazeAnimationDelegate BlendInDelegate, BlendOutDelegate;

		switch (State)
		{
			case ESketchbookQuestGiverState::Enter:
			{
				Params.Animation = EnterAnimation;
				SetActorHiddenInGame(false);
				break;
			}
			case ESketchbookQuestGiverState::TerribleNews:
			{
				Params.Animation = TerribleNews;
				break;
			}
			case ESketchbookQuestGiverState::PrinceCaptured:
			{
				Params.Animation = PrinceCaptured;
				break;
			}
			case ESketchbookQuestGiverState::Exit:
			{
				Params.Animation = Exit;
				Params.bLoop = false;
				Params.bPauseAtEnd = true;
				BlendOutDelegate.BindUFunction(this, n"OnExitDone");
				break;
			}
			default:
				break;
		}

		Mesh.PlaySlotAnimation(BlendInDelegate, BlendOutDelegate, Params);
	}


	UFUNCTION()
	void OnExitDone()
	{
		SetActorHiddenInGame(true);
	}
};

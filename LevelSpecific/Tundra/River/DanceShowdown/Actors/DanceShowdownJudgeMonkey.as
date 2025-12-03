UCLASS(Abstract)
class ADanceShowdownJudgeMonkey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent MeshComp;


	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "LeftHand")
	UStaticMeshComponent Sign;

	UPROPERTY()
	FHazePlaySlotAnimationParams IdleAnim;

	UPROPERTY()
	FHazePlaySlotAnimationParams HoldupSignAnim;

	UPROPERTY(EditInstanceOnly)
	int JudgeIndex;

	bool bIsImpressed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DanceShowdown::GetManager().ScoreManager.OnScoreChanged.AddUFunction(this, n"OnScoreChanged");
		DanceShowdown::GetManager().CrowdMonkeyManager.ShowCrowdActorsEvent.AddUFunction(this, n"Show");
		DanceShowdown::GetManager().CrowdMonkeyManager.HideCrowdActorsEvent.AddUFunction(this, n"Hide");
		Hide();
	}

	UFUNCTION()
	private void Hide()
	{
		MeshComp.SetVisibility(false);
		Sign.SetVisibility(false);
	}

	UFUNCTION()
	private void Show()
	{
		MeshComp.SetVisibility(true);
		Sign.SetVisibility(true);
	}

	UFUNCTION()
	private void OnScoreChanged(int Score)
	{
		if(Score > JudgeIndex)
	 	{
			if(!bIsImpressed)
			{
				MeshComp.PlaySlotAnimation(HoldupSignAnim);
				bIsImpressed = true;
			}
		}
		else if(bIsImpressed)
		{
			MeshComp.PlaySlotAnimation(IdleAnim);
			bIsImpressed = false;
		}
	}


	// UFUNCTION()
	// private void OnScoreChanged(float NewScore)
	// {
	// 	float ScoreOverHalf = Math::Saturate(NewScore - 0.5);
	// 	ScoreOverHalf *= 2;
	// 	int JudgePoints = Math::RoundToInt(ScoreOverHalf * DanceShowdown::AmountOfScoreRequired);

	// 	if(JudgePoints > JudgeIndex)
	// 	{
	// 		if(!bIsImpressed)
	// 		{
	// 			MeshComp.PlaySlotAnimation(HoldupSignAnim);
	// 			bIsImpressed = true;
	// 		}
	// 	}
	// 	else if(bIsImpressed)
	// 	{
	// 		MeshComp.PlaySlotAnimation(IdleAnim);
	// 		bIsImpressed = false;
	// 	}
	// }
};

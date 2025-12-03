
class UPlayerMovementTutorialComponent : UActorComponent
{

//Core Movement Prompts

	//
	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt FloorMotionPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt FloorJumpPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt WallScramblePrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt LedgeGrabPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt ShimmyPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt ShimmyDashPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt CancelShimmyPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt WallRunPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt WallRunJumpPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt LedgeRunPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt LocatePlayerPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt SlideTutorialPrompt1;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt SlideTutorialPrompt2;

//Contextual Move Prompts

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt PerchPointPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt PerchOnPointPrompt1;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt PerchOnPointPrompt2;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt PerchSplinePrompt1;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt PerchSplinePrompt2;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt PoleClimbPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt PoleClimbPrompt2;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt PoleClimbPrompt3;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt GrapplePrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt GrappleWallRunPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt GrappleLaunchPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt GrappleSlidePrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt GrapplePerchPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt SwingPrompt;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt SwingingPrompt1;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPrompt SwingingPrompt2;

	AHazePlayerCharacter Player;

	UPROPERTY()
	bool bIsInShimmyArea = false;
	bool bIsShowingShimmyTutorial = false;

	UPROPERTY()
	bool bIsInPerchArea = false;
	bool bIsShowingPerchTutorial = false;

	UPROPERTY()
	bool bInPerchSplineArea = false;
	bool bIsShowingPerchSplineTutorial = false;

	UPROPERTY()
	bool bInPoleClimbArea = false;
	bool bIsShowingPoleClimbTutorial = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		VerifyShouldShowShimmy();
		VerifyShouldShowPerch();
		VerifyShouldShowPerchSpline();
		VerifyShouldShowPoleClimb();
		VerifyShouldShowSwing();
	}

	//
	UFUNCTION()
	void ShowTutorialPrompt(FTutorialPrompt Prompt, FInstigator Instigator)
	{
		Player.ShowTutorialPrompt(Prompt, Instigator);
	}

	UFUNCTION()
	void ShowTutorialPromptChain(FTutorialPromptChain Prompt, FInstigator Instigator)
	{
		Player.ShowTutorialPromptChain(Prompt, Instigator, 1);
	}
	
	//
	UFUNCTION()
	void RemoveTutorialPromptByInstigator(FInstigator Instigator)
	{
		Player.RemoveTutorialPromptByInstigator(Instigator);
	}

	// UFUNCTION()
	// void RemoveSpecificTutorialPrompt(FTutorialPrompt Prompt, FInstigator Instigator)
	// {

	// }

	void VerifyShouldShowShimmy()
	{
		if(bIsInShimmyArea && !bIsShowingShimmyTutorial && Player.IsAnyCapabilityActive(n"LedgeGrab"))
		{
			ShowTutorialPrompt(ShimmyPrompt, this);
			ShowTutorialPrompt(ShimmyDashPrompt, this);
			bIsShowingShimmyTutorial = true;
		}
		else if ((!bIsInShimmyArea && bIsShowingShimmyTutorial) || (!Player.IsAnyCapabilityActive(n"LedgeGrab") && bIsShowingShimmyTutorial))
		{
			RemoveTutorialPromptByInstigator(this);
			bIsShowingShimmyTutorial = false;
		}
	}

	void VerifyShouldShowPerch()
	{
		if(bIsInPerchArea && !bIsShowingPerchTutorial && Player.IsAnyCapabilityActive(PlayerPerchPointTags::PerchPointPerch))
		{
			ShowTutorialPrompt(PerchOnPointPrompt1, this);
			ShowTutorialPrompt(PerchOnPointPrompt2, this);
			bIsShowingPerchTutorial = true;
		}
		else if ((!bIsInPerchArea && bIsShowingPerchTutorial) || (!Player.IsAnyCapabilityActive(PlayerPerchPointTags::PerchPointPerch) && bIsShowingPerchTutorial))
		{
			RemoveTutorialPromptByInstigator(this);
			bIsShowingPerchTutorial = false;
		}
	}

	void VerifyShouldShowPerchSpline()
	{
		if(bInPerchSplineArea && !bIsShowingPerchSplineTutorial && Player.IsAnyCapabilityActive(PlayerPerchPointTags::PerchPointSpline))
		{
			ShowTutorialPrompt(PerchSplinePrompt1, this);
			ShowTutorialPrompt(PerchSplinePrompt2, this);
			bIsShowingPerchSplineTutorial = true;
		}
		else if ((!bInPerchSplineArea && bIsShowingPerchSplineTutorial) || (!Player.IsAnyCapabilityActive(PlayerPerchPointTags::PerchPointSpline) && bIsShowingPerchSplineTutorial))
		{
			RemoveTutorialPromptByInstigator(this);
			bIsShowingPerchSplineTutorial = false;
		}
	}

	void VerifyShouldShowPoleClimb()
	{
		if(bInPoleClimbArea && !bIsShowingPoleClimbTutorial && Player.IsAnyCapabilityActive(PlayerMovementTags::PoleClimb))
		{
			ShowTutorialPrompt(PoleClimbPrompt, this);
			ShowTutorialPrompt(PoleClimbPrompt2, this);
			bIsShowingPoleClimbTutorial = true;
		}
		else if ((!bInPoleClimbArea && bIsShowingPoleClimbTutorial) || (!Player.IsAnyCapabilityActive(PlayerMovementTags::PoleClimb) && bIsShowingPoleClimbTutorial))
		{
			RemoveTutorialPromptByInstigator(this);
			bIsShowingPoleClimbTutorial = false;
		}
	}

	bool bIsShowingSwingPrompt;

	void VerifyShouldShowSwing()
	{
		if(!bIsShowingSwingPrompt && Player.IsAnyCapabilityActive(PlayerMovementTags::Swing))
		{
			ShowTutorialPrompt(SwingingPrompt1, this);
			ShowTutorialPrompt(SwingingPrompt2, this);
			bIsShowingSwingPrompt = true;
		}
		else if (bIsShowingSwingPrompt && !Player.IsAnyCapabilityActive(PlayerMovementTags::Swing))
		{
			RemoveTutorialPromptByInstigator(this);
			bIsShowingSwingPrompt = false;
		}
	}
}
class UPaddleRaftTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);
	USummitRaftPaddleComponent PaddleComp;
	bool bLeftCompleted;
	bool bRightCompleted;
	FName LeftInstigator = n"PaddleLeftTutorial";
	FName RightInstigator = n"PaddleRightTutorial";

	const float MioZOffset = 120;
	const float ZoeZOffset = 0;

	const float MioRightOffset = 50;
	const float MioLeftOffset = -50;

	const float ZoeRightOffset = 100;
	const float ZoeLeftOffset = -100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PaddleComp = USummitRaftPaddleComponent::Get(Player);
		PaddleComp.OnPaddleLeft.AddUFunction(this, n"OnPaddleLeft");
		PaddleComp.OnPaddleRight.AddUFunction(this, n"OnPaddleRight");
	}

	UFUNCTION()
	private void OnPaddleRight()
	{
		bRightCompleted = true;
		Player.RemoveTutorialPromptByInstigator(RightInstigator);
	}

	UFUNCTION()
	private void OnPaddleLeft()
	{
		bLeftCompleted = true;
		Player.RemoveTutorialPromptByInstigator(LeftInstigator);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsPlayerDead())
			return false;

		if (!PaddleComp.bShowTutorial)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;

		if (!PaddleComp.bShowTutorial)
			return true;

		if (bLeftCompleted && bRightCompleted)
			return true;
		

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt RightPaddlePrompt;
		RightPaddlePrompt.Action = ActionNames::PaddleRight;
		RightPaddlePrompt.Text = NSLOCTEXT("PaddleRaftTutorial", "PaddleRightPrompt", "Paddle");

		FTutorialPrompt LeftPaddlePrompt;
		LeftPaddlePrompt.Action = ActionNames::PaddleLeft;
		LeftPaddlePrompt.Text = NSLOCTEXT("PaddleRaftTutorial", "PaddleLeftPrompt", "Paddle");


		if (Player.IsMio())
		{
			Player.ShowTutorialPromptWorldSpace(RightPaddlePrompt, RightInstigator, Player.RootOffsetComponent, FVector(0.0, MioRightOffset, MioZOffset), 0.0, n"Head");
			Player.ShowTutorialPromptWorldSpace(LeftPaddlePrompt, LeftInstigator, Player.RootComponent, FVector(0.0, MioLeftOffset, MioZOffset), 0.0);
		}
		else
		{
			Player.ShowTutorialPromptWorldSpace(RightPaddlePrompt, RightInstigator, Player.RootOffsetComponent, FVector(0.0, ZoeRightOffset, ZoeZOffset), 0.0, n"Head");
			Player.ShowTutorialPromptWorldSpace(LeftPaddlePrompt, LeftInstigator, Player.RootComponent, FVector(0.0, ZoeLeftOffset, ZoeZOffset), 0.0);
		}


	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PaddleComp.bShowTutorial = false;
		Player.RemoveTutorialPromptByInstigator(RightInstigator);
		Player.RemoveTutorialPromptByInstigator(LeftInstigator);
	}
}
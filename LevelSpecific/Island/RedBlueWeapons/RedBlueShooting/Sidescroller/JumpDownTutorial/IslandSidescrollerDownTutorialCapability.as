class UIslandSidescDownerDownTutorialCapability : UTutorialCapability
{
	FTutorialPromptChain TutorialChain;
	int CurrentPosition;

	const float SwitchPositionCooldown = 0.2;
	float TimeOfSwitchPosition;

	AHazePlayerCharacter ShownForPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FTutorialPrompt Down;
		// Down.Action = ActionNames::RightStick_Down;
		Down.DisplayType = ETutorialPromptDisplay::LeftStick_Down;

		Down.Text = NSLOCTEXT("DownMovementTutorial", "DownPrompt", "Down");
		if (Player.IsMio())
			Down.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
		else
			Down.OverrideControlsPlayer = EHazeSelectPlayer::Zoe;
		TutorialChain.Prompts.Add(Down);

		FTutorialPrompt JumpPrompt;
		JumpPrompt.Action = ActionNames::MovementJump;
		JumpPrompt.Text = NSLOCTEXT("DownMovementTutorial", "JumpPrompt", "Jump");
		if (Player.IsMio())
			JumpPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
		else
			JumpPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Zoe;
		TutorialChain.Prompts.Add(JumpPrompt);		

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentPosition = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (ShownForPlayer != nullptr)
		{
			ShownForPlayer.RemoveTutorialPromptByInstigator(Instigator);
			ShownForPlayer = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShownForPlayer == nullptr && SceneView::GetFullScreenPlayer() != nullptr)
		{
			ShownForPlayer = SceneView::GetFullScreenPlayer();
			ShownForPlayer.ShowTutorialPromptChain(TutorialChain, Instigator, 0);
		}

		if (ShownForPlayer != nullptr)
		{
			if (HasControl())
			{
				if(GetAttributeVector2D(AttributeVectorNames::MovementRaw).X < -0.2)
					TrySetPosition(1);
				else
					TrySetPosition(0);
			}
			else
			{
				ShownForPlayer.SetTutorialPromptChainPosition(Instigator, CurrentPosition);
			}
		}
	}

	void TrySetPosition(int Position)
	{
		if(Position == CurrentPosition)
			return;

		if(Time::GetGameTimeSince(TimeOfSwitchPosition) < SwitchPositionCooldown)
			return;

		CrumbSetPosition(Position);

		TimeOfSwitchPosition = Time::GetGameTimeSeconds();
		ShownForPlayer.SetTutorialPromptChainPosition(Instigator, Position);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetPosition(int Position)
	{
		CurrentPosition = Position;
	}

	FInstigator GetInstigator() const property
	{
		return FInstigator(Player, n"IslandSidescrollerDownTutorialCapability");
	}
}
class UBattlefieldHoverboardTrickTutorialCapability : UTutorialCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Tutorial);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardWallRunComponent WallrunComp;
	UBattlefieldHoverboardTrickComponent TrickComp;
	TArray<EBattlefieldHoverboardTrickType> FinishedTricks;
	EBattlefieldHoverboardTrickType CurrentTutorial;

	bool bTutorialCompleted = false;
	int TutorialChainStep = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(TrickComp == nullptr)
			TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);

		if(WallrunComp == nullptr)
			WallrunComp = UBattlefieldHoverboardWallRunComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(TrickComp == nullptr)
			return false;

		if (!TrickComp.bCanRunTutorial)
			return false;

		if(WallrunComp.HasActiveWallRun())
			return false;
		
		if(FinishedTricks.Num() == 3)
			return false;

		if(TrickComp.CurrentTrick.IsSet())
			return false;
		
		if(!FinishedTricks.Contains(EBattlefieldHoverboardTrickType::X))
			return true;

		if (TrickComp.bIsFarEnoughFromGroundToDoTrick)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bTutorialCompleted)
			return true;
		
		if(WallrunComp.HasActiveWallRun())
			return true;

		if(CurrentTutorial != EBattlefieldHoverboardTrickType::X)
		{
			if (!TrickComp.bIsFarEnoughFromGroundToDoTrick)
				return true; 
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTutorialComponent::Get(Player).TutorialScreenSpaceOffset.Apply(-120, this);
		bTutorialCompleted = false;
		TutorialChainStep = 0;

		if(!FinishedTricks.Contains(EBattlefieldHoverboardTrickType::X))
			CurrentTutorial = EBattlefieldHoverboardTrickType::X;
		else if(!FinishedTricks.Contains(EBattlefieldHoverboardTrickType::B))
			CurrentTutorial = EBattlefieldHoverboardTrickType::B;
		else CurrentTutorial = EBattlefieldHoverboardTrickType::Y;

		if(CurrentTutorial == EBattlefieldHoverboardTrickType::X)
		{
			FTutorialPromptChain TutorialChain;
			FTutorialPrompt Jump;
			Jump.Action = ActionNames::MovementJump;
			Jump.Text = NSLOCTEXT("MovementTutorial", "HoverboardJumpPrompt", "Jump");
			TutorialChain.Prompts.Add(Jump);

			FTutorialPrompt Spin;
			Spin.Action = ActionNames::MovementDash;
			Spin.Text = NSLOCTEXT("MovementTutorial", "HoverboardSpinPrompt", "Trick");
			TutorialChain.Prompts.Add(Spin);

			TutorialChain.Type = ETutorialPromptChainType::Arrow;
			Player.ShowTutorialPromptChain(TutorialChain, this, 0);
		}
		else if(CurrentTutorial == EBattlefieldHoverboardTrickType::B)
		{
			FTutorialPrompt Flip;
			Flip.Action = ActionNames::Cancel;
			Flip.Text = NSLOCTEXT("MovementTutorial", "HoverboardFlipJumpPrompt", "Super Trick");
			Player.ShowTutorialPrompt(Flip, this);
		}
		else
		{
			FTutorialPrompt Twirl;
			Twirl.Action = ActionNames::Interaction;
			Twirl.Text = NSLOCTEXT("MovementTutorial", "HoverboardTwirlJumpPrompt", "Extreme Trick");
			Player.ShowTutorialPrompt(Twirl, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UTutorialComponent::Get(Player).TutorialScreenSpaceOffset.Clear(this);
		Player.RemoveTutorialPromptByInstigator(this);

		if(bTutorialCompleted)
		{
			FinishedTricks.Add(CurrentTutorial);
			CurrentTutorial = EBattlefieldHoverboardTrickType::MAX;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) 
	{
		if(CurrentTutorial == EBattlefieldHoverboardTrickType::X)
		{
			if(MoveComp.IsOnWalkableGround())
			{
				TutorialChainStep = 0;
				Player.SetTutorialPromptChainPosition(this, 0);
			}
			else if(TutorialChainStep == 0)
			{
				TutorialChainStep = 1;
				Player.SetTutorialPromptChainPosition(this, 1);
			}
			else if(TutorialChainStep == 1 && WasActionStarted(ActionNames::MovementDash))
			{
				TutorialChainStep = 2;
				Player.SetTutorialPromptChainPosition(this, 2);
				bTutorialCompleted = true;
			}
		}
		else if(CurrentTutorial == EBattlefieldHoverboardTrickType::Y)
		{
			if(WasActionStarted(ActionNames::Interaction))
				bTutorialCompleted = true;
		}
		else
		{
			if(WasActionStarted(ActionNames::Cancel))
				bTutorialCompleted = true;
		}
	}
};
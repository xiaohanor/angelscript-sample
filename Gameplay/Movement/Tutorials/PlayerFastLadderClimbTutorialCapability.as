
class UPlayerFastLadderClimbTutorialCapability : UTutorialCapability
{
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(PlayerMovementTags::Ladder))
			return false;
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(PlayerMovementTags::Ladder))
			return true;
		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPromptChain TutorialChain;

		FTutorialPrompt ClimbPrompt;
		ClimbPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Up;
		ClimbPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_UpDown;
		ClimbPrompt.Text = NSLOCTEXT("MovementTutorial", "ClimbPrompt", "Climb");
		TutorialChain.Prompts.Add(ClimbPrompt);

		FTutorialPrompt LeapPrompt;
		LeapPrompt.Action = ActionNames::MovementDash;
		LeapPrompt.Text = NSLOCTEXT("MovementTutorial", "ClimbJumpPrompt", "Leap Up");
		TutorialChain.Prompts.Add(LeapPrompt);

		Player.ShowTutorialPromptChain(TutorialChain, this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bIsClimbing = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y >= 0.25;

		// The remote side checks the velocity and synced animation input to determine which tutorial to highlight
		if (!HasControl())
			bIsClimbing = Player.GetRawLastFrameTranslationVelocity().Z > 20.0 && MoveComp.SyncedMovementInputForAnimationOnly.Size() > 0.1;

		if (bIsClimbing)
		{
			Player.SetTutorialPromptChainPosition(this, 1);
		}
		else
		{
			Player.SetTutorialPromptChainPosition(this, 0);
		}
	}
};
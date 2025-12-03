class UDesertGrappleFishJumpTutorialCapability : UHazePlayerCapability
{
	UDesertGrappleFishPlayerComponent GrappleFishPlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleFishPlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (!GrappleFishPlayerComp.bTutorialStarted)
			return false;

		if (GrappleFishPlayerComp.bTutorialCompleted)
			return false;

		if (GrappleFishPlayerComp.State != EDesertGrappleFishPlayerState::Riding)
			return false;

		if (Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return true;
		
		if (GrappleFishPlayerComp.State != EDesertGrappleFishPlayerState::Riding)
			return true;

		if (GrappleFishPlayerComp.bTutorialCompleted)
			return true;

		if (Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt JumpPrompt;
		JumpPrompt.Action = ActionNames::MovementJump;
		JumpPrompt.Text = NSLOCTEXT("GrappleFishTutorial", "JumpPrompt", "Jump!");

		Player.ShowTutorialPromptWorldSpace(JumpPrompt, this, Player.Mesh, FVector(0.0, 0.0, 50.0), 0.0, n"Head");

		GrappleFishPlayerComp.bTutorialStarted = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}
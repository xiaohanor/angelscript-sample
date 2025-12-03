class UMoonMarketBouncyBallBlasterPotionCapability : UMoonMarketPlayerShapeshiftCapability
{
	UMoonMarketBouncyBallBlasterPotionComponent BallBlasterComp;
	AMoonMarketBouncyBallBlaster BallBlaster;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BallBlasterComp = UMoonMarketBouncyBallBlasterPotionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnActivated();
		BallBlaster = Cast<AMoonMarketBouncyBallBlaster>(ShapeshiftInto(BallBlasterComp.BallBlasterClass));
		BallBlasterComp.BallBlaster = BallBlaster;

		FTutorialPrompt Prompt;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Prompt.Action = ActionNames::PrimaryLevelAbility;
		Prompt.Text = NSLOCTEXT("BallBlaster", "Shoot", "Shoot");
		Player.ShowTutorialPrompt(Prompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnDeactivated();
		RemoveVisualBlocker();
		BallBlasterComp.BallBlaster = nullptr;
		//Player.DeactivateCameraByInstigator(this);
		Player.RemoveTutorialPromptByInstigator(this);
	}
};
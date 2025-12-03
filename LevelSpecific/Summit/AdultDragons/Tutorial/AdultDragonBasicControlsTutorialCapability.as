class UAdultDragonBasicControlsTutorialCapability : UTutorialCapability
{
	float MoveTime = 1.5;

	bool bDeactivate;

	FTutorialPrompt MovePrompt;
	default MovePrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRightUpDown;
	default MovePrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_LeftRight;
	default MovePrompt.Text = NSLOCTEXT("AdultDragonTutorial", "MovePrompt", "Move");

	FTutorialPrompt DashPrompt;
	default DashPrompt.Action = ActionNames::MovementDash;
	default DashPrompt.Text = NSLOCTEXT("AdultDragonTutorial", "DashPrompt", "Dash");

	int DashCount = 3;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bDeactivate)
			return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bDeactivate)
			return true;

		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(MovePrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Size() > 0.0 && MoveTime > 0.0)
		{
			MoveTime -= DeltaTime;

			if (MoveTime <= 0.0)
			{
				Player.RemoveTutorialPromptByInstigator(this);
				Player.ShowTutorialPrompt(DashPrompt, this);
			}
		}

		if (MoveTime <= 0.0 && WasActionStarted(ActionNames::MovementDash))
		{
			DashCount--;

			if (DashCount <= 0)
				bDeactivate = true;
		}
	}
}
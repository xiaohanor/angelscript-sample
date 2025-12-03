class USkylineFlyingCarGotySplineHopModeSwitchCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::LastDemotable;

	ASkylineFlyingCar CarOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarOwner = Cast<ASkylineFlyingCar>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CarOwner.GetPilot() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// FTutorialPrompt TutorialPrompt;
		// TutorialPrompt.Action = ActionNames::Interaction;
		// TutorialPrompt.DisplayType = ETutorialPromptDisplay::Action;
		// TutorialPrompt.Mode = ETutorialPromptMode::Default;
		// TutorialPrompt.Text = NSLOCTEXT("SkylineFlyingCar", "SwitchMode", "Switch spline hop mode");

		// CarOwner.GetPilot().ShowTutorialPrompt(TutorialPrompt, this);

		FTutorialPrompt DashPrompt;
		DashPrompt.Action = ActionNames::MovementDash;
		DashPrompt.DisplayType = ETutorialPromptDisplay::Action;
		DashPrompt.Mode = ETutorialPromptMode::Default;
		DashPrompt.MaximumDuration = 10;
		DashPrompt.Text = FText::FromString("Dash");

		CarOwner.GetPilot().ShowTutorialPrompt(DashPrompt, this);

		FTutorialPrompt HopPrompt;
		HopPrompt.Action = ActionNames::MovementJump;
		HopPrompt.DisplayType = ETutorialPromptDisplay::Action;
		HopPrompt.Mode = ETutorialPromptMode::Default;
		HopPrompt.MaximumDuration = 10;
		HopPrompt.Text = FText::FromString("Tunnel hop (close to edge)");

		CarOwner.GetPilot().ShowTutorialPrompt(HopPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (WasActionStarted(ActionNames::Interaction))
		// 	CarOwner.bTriggerSplineHopMode = !CarOwner.bTriggerSplineHopMode;

		// FString String = CarOwner.bTriggerSplineHopMode ?
		// 	"LT + Dash" :
		// 	"Edge dash";

		// FVector Location = CarOwner.GetPilot().ViewLocation + CarOwner.GetPilot().ViewRotation.ForwardVector * 1000;
		// Debug::DrawDebugString(Location, String, FLinearColor::LucBlue, 0, 2, ScreenSpaceOffset = FVector2D(0, 450));
	}
}
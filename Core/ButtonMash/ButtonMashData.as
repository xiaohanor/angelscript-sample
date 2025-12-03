
delegate void FOnButtonMashCompleted();

// Console variables to turn all button mashes into button holds instead
namespace ButtonMash
{

const FConsoleVariable CVar_RemoveButtonMashes_Mio("Haze.RemoveButtonMashes_Mio", 0);
const FConsoleVariable CVar_RemoveButtonMashes_Zoe("Haze.RemoveButtonMashes_Zoe", 0);

bool ShouldButtonMashesBeHolds(AHazePlayerCharacter Player)
{
	if (Player.HasControl())
	{
		if (Player.IsMio())
		{
			if (ButtonMash::CVar_RemoveButtonMashes_Mio.GetInt() == 1)
				return true;
		}
		else
		{
			if (ButtonMash::CVar_RemoveButtonMashes_Zoe.GetInt() == 1)
				return true;
		}
	}

	return false;
}

bool ShouldButtonMashesBeAutomatic(AHazePlayerCharacter Player)
{
	if (Player.HasControl())
	{
		if (PlayerInputDevToggles::ButtonMash::AutoButtonMash.IsEnabled(Player))
			return true;
		if (Player.IsMio())
		{
			if (ButtonMash::CVar_RemoveButtonMashes_Mio.GetInt() == 2)
				return true;
		}
		else
		{
			if (ButtonMash::CVar_RemoveButtonMashes_Zoe.GetInt() == 2)
				return true;
		}
	}

	return false;
}

};

enum EButtonMashMode
{
	// Player needs to mash at the rate for the duration to complete the button mash
	ButtonMash,
	// Player needs to hold the button for the specified duration to complete
	ButtonHold,
};

enum EButtonMashProgressionMode
{
	// Mashing fills the progress bar, the button mash completes when filled.
	MashToProgress,
	// Mashing starts at full and will decay down. The button mash completes when fully decayed.
	StartFullDecayDown,
	// Mashing proceeds the button mash, but does not show a progress bar and never decays.
	MashToProceedOnly,
	// Mashing doesn't progress anything, but we can access the mash rate.
	MashRateOnly,
	// Mashing doesn't progress anything, but we can access the mash rate. If 'automatic' mashing is turned on, don't mash.
	MashRateOnlyIgnoreAutomatic,
};

enum EButtonMashDifficulty
{
	Easy,
	Medium,
	Hard,
	ActuallyImpossible,
};

struct FButtonMashSettings
{
	// What style of button mash to use
	UPROPERTY(Category = "Button Mash")
	EButtonMashMode Mode = EButtonMashMode::ButtonMash;

	// How long the player needs to mash or hold to succeed
	UPROPERTY(Category = "Button Mash")
	float Duration = 1.0;

	/**
	 * How hard the player must mash in order to make progress on the duration.
	 */
	UPROPERTY(Category = "Button Mash", Meta = (EditCondition = "Mode == EButtonMashMode::ButtonMash || Mode == EButtonMashMode::DoubleButtonMash", EditConditionHides))
	EButtonMashDifficulty Difficulty = EButtonMashDifficulty::Medium;

	/**
	 * Which button should be mashed.
	 */
	UPROPERTY(Category = "Button Mash", Meta = (AdvancedDisplay))
	FName ButtonAction = ActionNames::Interaction;

	// Allow the player to cancel the button mash instead of completing it.
	UPROPERTY(Category = "Gameplay")
	bool bAllowPlayerCancel = false;

	// Whether to block all other gameplay on the player while mashing
	UPROPERTY(Category = "Gameplay")
	bool bBlockOtherGameplay = true;

	// Whether to display the default button mash widget or not
	UPROPERTY(Category = "Mash Widget")
	bool bShowButtonMashWidget = true;

	// Which component to attach the widget to
	UPROPERTY(Category = "Mash Widget", Meta = (EditCondition = "bShowButtonMashWidget", EditConditionHides))
	USceneComponent WidgetAttachComponent;

	// Which socket on the component to attach the widget to
	UPROPERTY(Category = "Mash Widget", Meta = (EditCondition = "bShowButtonMashWidget", EditConditionHides))
	FName WidgetAttachSocket;

	// Position offset for the widget from its attachment. If no attachment, world position.
	UPROPERTY(Category = "Mash Widget", Meta = (EditCondition = "bShowButtonMashWidget", EditConditionHides))
	FVector WidgetPositionOffset;

	// How the button mash progresses
	UPROPERTY(Category = "Button Mash")
	EButtonMashProgressionMode ProgressionMode = EButtonMashProgressionMode::MashToProgress;

	// Use latest data instead of crumb trail to sync this button mash progress
	UPROPERTY(Category = "Networking", AdvancedDisplay)
	bool bSyncWithNetworkLatestData = false;

	bool IsButtonHold(AHazePlayerCharacter Player) const
	{
		if (Mode == EButtonMashMode::ButtonHold)
			return true;
		return ButtonMash::ShouldButtonMashesBeHolds(Player);
	}

	bool IsAutomatic(AHazePlayerCharacter Player) const
	{
		if (ProgressionMode == EButtonMashProgressionMode::MashRateOnlyIgnoreAutomatic)
			return false;
		return ButtonMash::ShouldButtonMashesBeAutomatic(Player);
	}
	
	bool ShouldShowProgress(AHazePlayerCharacter Player) const
	{
		if (ProgressionMode == EButtonMashProgressionMode::MashRateOnly)
			return false;
		if (ProgressionMode == EButtonMashProgressionMode::MashRateOnlyIgnoreAutomatic)
			return false;
		if (ProgressionMode == EButtonMashProgressionMode::MashToProceedOnly)
			return false;
		return true;
	}
	
	bool IsProgressable(AHazePlayerCharacter Player) const
	{
		if (ProgressionMode == EButtonMashProgressionMode::MashRateOnly)
			return false;
		if (ProgressionMode == EButtonMashProgressionMode::MashRateOnlyIgnoreAutomatic)
			return false;
		return true;
	}
};

void GetConfigForButtonMashDifficulty(EButtonMashDifficulty Difficulty, float DurationPercentage, float& OutMinRate, float& OutTargetRate, float& OutAutoProgressionMultiplier)
{
	switch (Difficulty)
	{
		case EButtonMashDifficulty::Easy:
			OutMinRate = 2.0;
			OutTargetRate = 4.0;
		break;
		case EButtonMashDifficulty::Medium:
			OutMinRate = 3.0;
			OutTargetRate = 6.0;
		break;
		case EButtonMashDifficulty::Hard:
			OutMinRate = 4.0;
			OutTargetRate = 10.0;
		break;
		case EButtonMashDifficulty::ActuallyImpossible:
		{
			OutMinRate = Math::GetMappedRangeValueClamped(
				FVector2D(0.0, 1.0),
				FVector2D(4.0, 20.0),
				DurationPercentage,
			);
			OutTargetRate = OutMinRate * 2.0;

			const float SimulatedRate = 10.0;
			if (SimulatedRate > OutMinRate)
				OutAutoProgressionMultiplier = 1.0;
			else
				OutAutoProgressionMultiplier = (SimulatedRate / OutMinRate) - 1.0;
		}

		break;
	}
}
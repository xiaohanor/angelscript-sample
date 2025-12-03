namespace ForceFeedbackDevToggles
{
	const FHazeDevToggleCategory ForceFeedbackCategory = FHazeDevToggleCategory(n"Force Feedback");

	const FHazeDevToggleBoolPerPlayer DisableFor;
	const FHazeDevToggleBoolPerPlayer DisableTriggersFor;
}

class UForceFeedbackDevTogglesCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastDemotable;
	default DebugCategory = n"ForceFeedback";

	const FString EnableForceFeedbackString = "Haze.EnableForceFeedback";
	const FString EnableTriggerForceFeedbackString = "Haze.EnableTriggerForceFeedback";

	bool bForceFeedbackDisabled;
	bool bTriggerForceFeedbackDisabled;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForceFeedbackDevToggles::DisableFor.MakeVisible();
		ForceFeedbackDevToggles::DisableTriggersFor.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// General force feedback
		{
			if (ForceFeedbackDevToggles::DisableFor.IsEnabled(Player) && !bForceFeedbackDisabled)
			{
				Console::SetConsoleVariableInt(EnableForceFeedbackString, 0);
				bForceFeedbackDisabled = true;
			}

			if (!ForceFeedbackDevToggles::DisableFor.IsEnabled(Player) && bForceFeedbackDisabled)
			{
				Console::SetConsoleVariableInt(EnableForceFeedbackString, 1);
				bForceFeedbackDisabled = false;
			}
		}

		// Triggers
		{
			if (ForceFeedbackDevToggles::DisableTriggersFor.IsEnabled(Player) && !bTriggerForceFeedbackDisabled)
			{
				Console::SetConsoleVariableInt(EnableTriggerForceFeedbackString, 0);
				bTriggerForceFeedbackDisabled = true;
			}

			if (!ForceFeedbackDevToggles::DisableTriggersFor.IsEnabled(Player) && bTriggerForceFeedbackDisabled)
			{
				Console::SetConsoleVariableInt(EnableTriggerForceFeedbackString, 1);
				bTriggerForceFeedbackDisabled = false;
			}
		}
	}
}
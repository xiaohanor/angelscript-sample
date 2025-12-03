
class UTutorialWidgetsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Tutorial);

	default DebugCategory = n"Tutorial";
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::Input;
	
    UTutorialComponent TutorialComponent;

	UTutorialContainerWidget Widget;
	TArray<int> ActiveTutorialIds;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
        TutorialComponent = UTutorialComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
        if (TutorialComponent.bHasTutorials)
            return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
        if (!TutorialComponent.bHasTutorials)
            return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
        Widget = Cast<UTutorialContainerWidget>(Player.AddWidgetToHUDSlot(n"Tutorial", TutorialComponent.TutorialWidget));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Widget.Hide();
		Widget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Remove tutorials we've completed if they're set to complete on button prompts
		for (int i = 0, Count = TutorialComponent.ActiveTutorials.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = TutorialComponent.ActiveTutorials[i];
			if (Tutorial.Prompt.Mode == ETutorialPromptMode::RemoveWhenPressed
				&& Tutorial.Prompt.DisplayType == ETutorialPromptDisplay::Action)
			{
				if (IsActioning(Tutorial.Prompt.Action))
				{
					TutorialComponent.ActiveTutorials.RemoveAt(i);
					--i; --Count;
				}
			}
		}

		// Remove old tutorials from the widget
		for (int i = 0, Count = ActiveTutorialIds.Num(); i < Count; ++i)
		{
			// Check if this tutorial is still active in the component
			bool bStillActive = false;
			for (int j = 0, ActiveCount = TutorialComponent.ActiveTutorials.Num(); j < ActiveCount; ++j)
			{
				if (TutorialComponent.ActiveTutorials[j].TutorialId == ActiveTutorialIds[i])
				{
					bStillActive = true;
					break;
				}
			}

			for (int j = 0, ActiveCount = TutorialComponent.ActiveChains.Num(); j < ActiveCount; ++j)
			{
				if (TutorialComponent.ActiveChains[j].TutorialId == ActiveTutorialIds[i])
				{
					bStillActive = true;
					break;
				}
			}

			// Remove no longer active tutorial prompts from the widget
			if (!bStillActive)
			{
				Widget.RemovePrompt(ActiveTutorialIds[i]);
				ActiveTutorialIds.RemoveAt(i);
				--i; --Count;
			}
		}

		// Add new tutorials to the widget
		for (int i = 0, Count = TutorialComponent.ActiveTutorials.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = TutorialComponent.ActiveTutorials[i];
			if (!ActiveTutorialIds.Contains(Tutorial.TutorialId))
			{
				Widget.AddPrompt(Tutorial.TutorialId, Tutorial.Prompt);
				ActiveTutorialIds.Add(Tutorial.TutorialId);
			}

			Widget.SetPromptState(Tutorial.TutorialId, Tutorial.State);
		}

		// Add new tutorial chains to the widget
		for (int i = 0, Count = TutorialComponent.ActiveChains.Num(); i < Count; ++i)
		{
			FActiveTutorialChain& Tutorial = TutorialComponent.ActiveChains[i];
			if (!ActiveTutorialIds.Contains(Tutorial.TutorialId))
			{
				Widget.AddChain(Tutorial.TutorialId, Tutorial.Chain, Tutorial.ChainPosition);
				ActiveTutorialIds.Add(Tutorial.TutorialId);
			}
			else
			{
				Widget.SetChainPosition(Tutorial.TutorialId, Tutorial.ChainPosition);
			}
		}

		Widget.ScreenSpaceOffset = TutorialComponent.TutorialScreenSpaceOffset.Get();
		Widget.UpdatePrompts();
	}
}
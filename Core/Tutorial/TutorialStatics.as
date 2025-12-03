
/**
 * Add a new single tutorial prompt to the screen.
 */
UFUNCTION(Category = "Tutorials", Meta = (AutoSplit = "Prompt", ExpandToEnum = "Prompt_Action", ExpandedEnum = "/Script/Angelscript.ActionNames"))
mixin void ShowTutorialPrompt(AHazePlayerCharacter Player, FTutorialPrompt Prompt, FInstigator Instigator)
{
	// Warn if we are passing in an incorrectly initialized FText
#if TEST
	if (Prompt.Text.IsInitializedFromString())
	{
		PrintScaled(
			"Tutorial prompt trying to show text '"+Prompt.Text+"' was initialized using FText::FromString"
			+"\nThis breaks translation, so please use NSLOCTEXT or put it in a UPROPERTY() instead!",
		30.0, FLinearColor(1.0, 0.5, 0.0), 2.0);
		check(false);
	}
#endif

    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddTutorial(Prompt, Instigator);
}

/**
 * Set all the tutorial prompts with the specified instigator to be displayed with the given state.
 */
UFUNCTION(Category = "Tutorials")
mixin void SetTutorialPromptState(AHazePlayerCharacter Player, FInstigator Instigator, ETutorialPromptState State)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.SetPromptState(Instigator, State);
}

/**
 * Add a new chain of tutorial prompts to the screen.
 *  NOTE: Prompt chains IGNORE any MaximumDuration or RemoveWhenPressed Mode values specified
 *  in any of the prompts in the chain.
 */
UFUNCTION(Category = "Tutorials")
mixin void ShowTutorialPromptChain(AHazePlayerCharacter Player, FTutorialPromptChain PromptChain, FInstigator Instigator, int InitialPosition)
{
	// Warn if we are passing in an incorrectly initialized FText
#if TEST
	for (auto& Prompt : PromptChain.Prompts)
	{
		if (Prompt.Text.IsInitializedFromString())
		{
			PrintScaled(
				"Tutorial prompt trying to show text '"+Prompt.Text+"' was initialized using FText::FromString"
				+"\nThis breaks translation, so please use NSLOCTEXT or put it in a UPROPERTY() instead!",
			30.0, FLinearColor(1.0, 0.5, 0.0), 2.0);
			check(false);
		}
	}
#endif

    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddTutorialChain(PromptChain, Instigator, InitialPosition);
}

/**
 * Set which position in the prompt chain is currently active for the
 * tutorial chain added with the specified instigator.
 */
UFUNCTION(Category = "Tutorials")
mixin void SetTutorialPromptChainPosition(AHazePlayerCharacter Player, FInstigator Instigator, int ChainPosition)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.SetChainPosition(Instigator, ChainPosition);
}

/**
 * Add a tutorial prompt in world space that hovers over an object.
 * If no attach component is specified, the player mesh is used.
 * Only one tutorial can be attached to the same component at a time. Additional prompts
 * are not displayed until the previous one is removed.
 * TutorialPromptMode (RemoveWhenPressed) is ignored for world prompts, they always need
 * to be manually removed via RemoveTutorialPromptByInstigator().
 */
UFUNCTION(Category = "Tutorials", Meta = (AutoSplit = "Prompt", ExpandToEnum = "Prompt_Action", ExpandedEnum = "/Script/Angelscript.ActionNames", AdvancedDisplay = "AttachComponent,AttachOffset,ScreenSpaceOffset"))
mixin void ShowTutorialPromptWorldSpace(AHazePlayerCharacter Player, FTutorialPrompt Prompt, FInstigator Instigator, USceneComponent AttachComponent = nullptr, FVector AttachOffset = FVector(0.0, 0.0, 176.0), float ScreenSpaceOffset = 100.0, FName AttachSocket = NAME_None)
{
	// Warn if we are passing in an incorrectly initialized FText
#if TEST
	if (Prompt.Text.IsInitializedFromString())
	{
		PrintScaled(
			"Tutorial prompt trying to show text '"+Prompt.Text+"' was initialized using FText::FromString"
			+"\nThis breaks translation, so please use NSLOCTEXT or put it in a UPROPERTY() instead!",
		30.0, FLinearColor(1.0, 0.5, 0.0), 2.0);
		check(false);
	}
#endif

    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddWorldPrompt(Prompt, Instigator, AttachComponent, AttachOffset, ScreenSpaceOffset, AttachSocket);
}

/**
 * Remove any tutorial prompts or chains that were added with the specified instigator.
 */
UFUNCTION(Category = "Tutorials")
mixin void RemoveTutorialPromptByInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
    if (TutorialComponent != nullptr)
		TutorialComponent.RemoveTutorialsByInstigator(Instigator);
}

UFUNCTION(Category = "Tutorials")
mixin void ShowCancelPrompt(AHazePlayerCharacter Player, FInstigator Instigator)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddCancelPrompt(false, FText(), Instigator);
}

UFUNCTION(Category = "Tutorials")
mixin void ShowCancelPromptWithText(AHazePlayerCharacter Player, FInstigator Instigator, FText CustomText)
{
	// Warn if we are passing in an incorrectly initialized FText
#if TEST
	if (CustomText.IsInitializedFromString())
	{
		PrintScaled(
			"Cancel prompt trying to show text '"+CustomText+"' was initialized using FText::FromString"
			+"\nThis breaks translation, so please put it in a UPROPERTY() instead!",
		30.0, FLinearColor(1.0, 0.5, 0.0), 2.0);
		check(false);
	}
#endif

    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
	TutorialComponent.AddCancelPrompt(true, CustomText, Instigator);
}

UFUNCTION(Category = "Tutorials")
mixin void RemoveCancelPromptByInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
{
    UTutorialComponent TutorialComponent = UTutorialComponent::Get(Player);
    if (TutorialComponent != nullptr)
		TutorialComponent.RemoveCancelPrompt(Instigator);
}
namespace CenterView
{
	UFUNCTION(BlueprintCallable)
	void ShowCenterViewTargetTutorial(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto TutorialComp = UCenterViewTutorialPlayerComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;

		TutorialComp.AddTutorialInstigator(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void RemoveCenterViewTargetTutorial(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto TutorialComp = UCenterViewTutorialPlayerComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;

		TutorialComp.RemoveTutorialInstigator(Instigator);
	}
}
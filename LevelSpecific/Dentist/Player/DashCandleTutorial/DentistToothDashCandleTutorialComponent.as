UCLASS(Abstract)
class UDentistToothDashCandleTutorialComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FTutorialPrompt TutorialPrompt;

	bool bHasCompletedTutorial = false;
	TSet<FInstigator> ShowDashCandleTutorialInstigators;

	bool ShouldShowTutorial() const
	{
		if(bHasCompletedTutorial)
			return false;

		return !ShowDashCandleTutorialInstigators.IsEmpty();
	}
};

namespace Dentist
{
	UFUNCTION(BlueprintCallable)
	void DentistShowDashCandleTutorial(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if(Player == nullptr)
			return;

		auto TutorialComp = UDentistToothDashCandleTutorialComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;

		TutorialComp.ShowDashCandleTutorialInstigators.Add(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void DentistRemoveDashCandleTutorial(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if(Player == nullptr)
			return;

		auto TutorialComp = UDentistToothDashCandleTutorialComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;

		TutorialComp.ShowDashCandleTutorialInstigators.Remove(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void DentistForceCompletedDashCandleTutorial(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if(Player == nullptr)
			return;

		auto TutorialComp = UDentistToothDashCandleTutorialComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;

		TutorialComp.bHasCompletedTutorial = true;
	}
}
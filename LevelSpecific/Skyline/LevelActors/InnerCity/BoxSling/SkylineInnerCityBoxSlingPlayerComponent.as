class USkylineInnerCityBoxSlingPlayerComponent : UActorComponent
{
	bool bIsBoxed = false;
	bool bCanExit = false;

	ASkylineInnerCityBoxSling Boxy = nullptr;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptExit;
	default PromptExit.Action = ActionNames::Cancel;
	default PromptExit.Text = NSLOCTEXT("SkylineInnerCity", "BoxSlingExit", "Exit");

	
};
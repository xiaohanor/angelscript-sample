/**
 * 
 */
class UWindJavelinTutorialCapability : UHazePlayerCapability
{
   	default DebugCategory = WindJavelin::DebugCategory;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UWindJavelinPlayerComponent PlayerComp;

	default TickGroupOrder = 100;
	default TickGroup = EHazeTickGroup::Gameplay;

	bool bAiming = false;

	FTutorialPromptChain PromptChain;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UWindJavelinPlayerComponent::Get(Player);

		FTutorialPrompt AimPrompt;
		AimPrompt.Text = PlayerComp.Settings.AimTutorialText;
		AimPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;

		FTutorialPrompt ThrowPrompt;
		ThrowPrompt.Action = WindJavelin::ThrowAction;
		ThrowPrompt.Text = PlayerComp.Settings.ThrowTutorialText;

		PromptChain.Prompts.Add(AimPrompt);
		PromptChain.Prompts.Add(ThrowPrompt);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if (!PlayerComp.bShowTutorial)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if (!PlayerComp.bShowTutorial)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		bAiming = false;
		ShowAimTutorial();
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    { 
        Player.RemoveTutorialPromptByInstigator(this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (PlayerComp.bIsAiming)
		{
			ShowThrowTutorial();
		}
		else
		{
			ShowAimTutorial();
		}
    }

	void ShowAimTutorial()
	{
		if (bAiming)
			return;

		bAiming = true;

		Player.RemoveTutorialPromptByInstigator(this);

		FTutorialPrompt AimPrompt;
		AimPrompt.Action = WindJavelin::ThrowAction;
		AimPrompt.Text = PlayerComp.Settings.AimTutorialText;
		AimPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Player.ShowTutorialPrompt(AimPrompt, this);
	}

	void ShowThrowTutorial()
	{
		if (!bAiming)
			return;

		bAiming = false;

		Player.RemoveTutorialPromptByInstigator(this);

		FTutorialPrompt ThrowPromp;
		ThrowPromp.Action = WindJavelin::ThrowAction;
		ThrowPromp.Text = PlayerComp.Settings.ThrowTutorialText;
		Player.ShowTutorialPrompt(ThrowPromp, this);
	}
}
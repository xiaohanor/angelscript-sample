UFUNCTION()
void ActivateWindJavelinTutorial(bool bActive)
{
	UWindJavelinPlayerComponent PlayerComp = UWindJavelinPlayerComponent::Get(WindJavelin::GetPlayer());
	
	if (PlayerComp == nullptr)
		return;

	PlayerComp.bShowTutorial = bActive;
}
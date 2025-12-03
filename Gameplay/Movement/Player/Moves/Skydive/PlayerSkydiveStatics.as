
UFUNCTION(DisplayName = "Enable Player Skydive")
mixin void EnableSkydive(AHazePlayerCharacter Player, FInstigator Instigator, EPlayerSkydiveMode Mode, EPlayerSkydiveStyle Style, EInstigatePriority SkydivePriority, UPlayerSkydiveSettings SkydiveSettings, EHazeSettingsPriority SettingsPriority = EHazeSettingsPriority::Gameplay, bool bSkipEnter = false)
{
	UPlayerSkydiveComponent SkydiveComp = UPlayerSkydiveComponent::Get(Player);

	if(SkydiveComp == nullptr)
		return;

	SkydiveComp.ApplySkydiveActivation(Instigator, Mode, SkydivePriority, SkydiveSettings, SettingsPriority, Style, bSkipEnter);
}

UFUNCTION(DisplayName = "Disable Player Skydive")
mixin void DisableSkydive(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerSkydiveComponent SkydiveComp = UPlayerSkydiveComponent::Get(Player);

	if(SkydiveComp == nullptr)
		return;

	SkydiveComp.ClearSkyDiveActivation(Instigator);
}
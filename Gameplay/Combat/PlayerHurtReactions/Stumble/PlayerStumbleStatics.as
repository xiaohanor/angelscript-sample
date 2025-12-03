UFUNCTION(BlueprintCallable, DisplayName = StumblePlayer, Meta = (AutoSplit = "Stumble"))
void BP_StumblePlayer(AHazePlayerCharacter Player, FStumble& Stumble)
{
	Player.ApplyStumble(Stumble);
}

mixin void ApplyStumble(AHazePlayerCharacter Player, FStumble& Stumble)
{
	auto StumbleComp = UPlayerStumbleComponent::Get(Player);		
	if ((StumbleComp != nullptr) && !StumbleComp.HasRecentStumble(0.1))
		StumbleComp.ApplyStumble(Stumble);
}

mixin void ApplyStumble(AHazePlayerCharacter Player, FVector Move, float Duration = 1.0, FName FeatureTag = n"Stumble", float Cooldown = 0.0)
{
	FStumble Stumble;
	Stumble.Move = Move;
	Stumble.Duration = Duration;
	Stumble.FeatureTag = FeatureTag;
	Stumble.Cooldown = Cooldown;
	Player.ApplyStumble(Stumble);
}
UFUNCTION(BlueprintCallable, DisplayName = KnockdownPlayer, Meta = (AutoSplit = "Knockdown"))
void BP_KnockdownPlayer(AHazePlayerCharacter Player, FKnockdown& Knockdown)
{
	Player.ApplyKnockdown(Knockdown);
}

mixin void ApplyKnockdown(AHazePlayerCharacter Player, FKnockdown Knockdown)
{
	auto KnockdownComp = UPlayerKnockdownComponent::Get(Player);		
	if ((KnockdownComp != nullptr) && !KnockdownComp.HasRecentKnockdown(0.1))
		KnockdownComp.ApplyKnockdown(Knockdown);
}

mixin void ApplyKnockdown(AHazePlayerCharacter Player, FVector Move, float Duration = 3.0, FName FeatureTag = n"Knockdown", float Cooldown = 0.0)
{
	FKnockdown Knockdown;
	Knockdown.Move = Move;
	Knockdown.Duration = Duration;
	Knockdown.FeatureTag = FeatureTag;
	Knockdown.Cooldown = Cooldown;
	Player.ApplyKnockdown(Knockdown);
}
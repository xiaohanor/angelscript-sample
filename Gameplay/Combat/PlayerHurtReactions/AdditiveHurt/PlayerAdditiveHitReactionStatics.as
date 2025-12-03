UFUNCTION(BlueprintCallable, DisplayName = PlayerAdditiveHitReaction)
mixin void ApplyAdditiveHitReaction(AHazePlayerCharacter Player, FVector WorldHitDirection, EPlayerAdditiveHitReactionType Type = EPlayerAdditiveHitReactionType::Small)
{
	if (Player == nullptr)
		return;
	UPlayerAdditiveHitReactionComponent Comp = UPlayerAdditiveHitReactionComponent::GetOrCreate(Player);
	Comp.ApplyHitReaction(WorldHitDirection, Type);				
}


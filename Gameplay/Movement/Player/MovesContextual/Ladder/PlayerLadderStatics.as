
UFUNCTION(Category = "Player Movement")
mixin void ForceEnterLadder(AHazePlayerCharacter Player, ALadder Ladder)
{
	if (Ladder == nullptr)
		return;

	UPlayerLadderComponent LadderComp = UPlayerLadderComponent::Get(Player);

	if(LadderComp == nullptr)
		return;
	
	LadderComp.ForcePlayerLadderEntry(Ladder);
}

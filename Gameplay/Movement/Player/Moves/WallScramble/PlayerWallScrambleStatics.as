
UFUNCTION(DisplayName = "Reset Player WallScramble Usage")
mixin void ResetWallScrambleUsage(AHazePlayerCharacter Player)
{
	UPlayerWallScrambleComponent ScrambleComp = UPlayerWallScrambleComponent::GetOrCreate(Player);
	ScrambleComp.bCanScramble = true;
}
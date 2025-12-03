
UFUNCTION(DisplayName = "Reset Player WallRun Usage")
mixin void ResetPlayerWallRunUsage(AHazePlayerCharacter Player)
{
	UPlayerWallRunComponent WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
	WallRunComp.bWallRunAvailableUntilGrounded = true;
	WallRunComp.bHasWallRunnedSinceLastGrounded = false;
}
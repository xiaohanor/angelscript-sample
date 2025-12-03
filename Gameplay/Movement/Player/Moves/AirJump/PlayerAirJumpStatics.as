
UFUNCTION(DisplayName = "Reset Player AirJump Usage")
mixin void ResetAirJumpUsage(AHazePlayerCharacter Player)
{
	UPlayerAirJumpComponent AirJumpComp = UPlayerAirJumpComponent::GetOrCreate(Player);

	if(AirJumpComp == nullptr)
		return;

	AirJumpComp.bCanAirJump = true;
}

UFUNCTION(DisplayName = "Consume Player AirJump Usage")
mixin void ConsumeAirJumpUsage(AHazePlayerCharacter Player)
{
	UPlayerAirJumpComponent AirJumpComp = UPlayerAirJumpComponent::GetOrCreate(Player);

	if(AirJumpComp == nullptr)
		return;

	AirJumpComp.bCanAirJump = false;
}

/**
 * From now until the player becomes grounded again or the timeout is reached,
 * air jump will not cancel the player's existing upwards velocity.
 * 
 * Should be used right when the player is launched upward to prevent accidentally
 * cancelling the launch with an air jump.
 */
UFUNCTION(DisplayName = "Player Keep Launch Velocity During Air Jump Until Landed")
mixin void KeepLaunchVelocityDuringAirJumpUntilLanded(AHazePlayerCharacter Player, float Timeout = 0.4)
{
	UPlayerAirJumpComponent AirJumpComp = UPlayerAirJumpComponent::GetOrCreate(Player);
	AirJumpComp.bKeepLaunchVelocityDuringAirJumpUntilLanded = true;
	AirJumpComp.KeepLaunchVelocityUntilTime = Time::GameTimeSeconds + Timeout;
}
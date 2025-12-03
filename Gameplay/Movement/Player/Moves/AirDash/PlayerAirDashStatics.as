
UFUNCTION(DisplayName = "Reset Player AirDash Usage")
mixin void ResetAirDashUsage(AHazePlayerCharacter Player)
{
	UPlayerAirDashComponent AirDashComp = UPlayerAirDashComponent::GetOrCreate(Player);

	if(AirDashComp == nullptr)
		return;

	AirDashComp.bCanAirDash = true;
}

UFUNCTION(DisplayName = "Consume Player AirDash Usage")
mixin void ConsumeAirDashUsage(AHazePlayerCharacter Player)
{
	UPlayerAirDashComponent AirDashComp = UPlayerAirDashComponent::GetOrCreate(Player);

	if(AirDashComp == nullptr)
		return;

	AirDashComp.bCanAirDash = false;
}
UFUNCTION(Category = "Player")
mixin void LaunchPlayerTo(AHazePlayerCharacter Player, FInstigator Instigator, FPlayerLaunchToParameters Parameters)
{
	if (Player.HasControl() || Parameters.NetworkMode != EPlayerLaunchToNetworkMode::Crumbed)
	{
		UPlayerLaunchToComponent LaunchToComp = UPlayerLaunchToComponent::GetOrCreate(Player);
		LaunchToComp.bHasPendingLaunchTo = true;
		LaunchToComp.PendingLaunchToInstigator = Instigator;
		LaunchToComp.PendingLaunchTo = Parameters;
	}
}
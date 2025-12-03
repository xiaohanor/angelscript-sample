class ABattlefieldHoverboardSnipeVolume : APlayerTrigger
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		HoverboardComp.SniperVolumes.AddUnique(this);
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		HoverboardComp.SniperVolumes.Remove(this);
	}
};
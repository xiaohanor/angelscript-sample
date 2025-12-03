class UPlayerHoverboardCapability : UHazePlayerCapability
{
	UHoverboardUserComponent HoverboardUserComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardUserComponent = UHoverboardUserComponent::Get(Player);
		HoverboardUserComponent.Hoverboard = SpawnActor(HoverboardUserComponent.HoverboardClass, Player.ActorLocation, Player.ActorRotation);
		HoverboardUserComponent.Hoverboard.AttachToActor(Player, n"Backpack");
		HoverboardUserComponent.Hoverboard .SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HoverboardUserComponent.Hoverboard.DestroyActor();
	}
}
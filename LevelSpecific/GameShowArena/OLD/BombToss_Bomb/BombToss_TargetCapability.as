class UBombTossTargetCapability : UHazePlayerCapability
{
	UBombTossPlayerComponent BombTossPlayerComponent;
	UBombTossTargetComponent BombTossTargetComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UBombTossPlayerComponent::Get(Owner);
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
		BombTossTargetComponent = Cast<UBombTossTargetComponent>(Owner.CreateComponent(BombTossPlayerComponent.BombTossTargetComponentClass));
		BombTossTargetComponent.SetWorldLocation(Owner.FocusLocation);
		BombTossTargetComponent.DisableForPlayer(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BombTossTargetComponent.DestroyComponent(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}
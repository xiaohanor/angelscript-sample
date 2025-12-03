class UPigSausageBunInteractionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	APigSausage PigSausage;
	UPlayerPigSausageComponent SausageComponent;

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
		SausageComponent = UPlayerPigSausageComponent::Get(Owner);
		PigSausage = SausageComponent.PigSausage;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}
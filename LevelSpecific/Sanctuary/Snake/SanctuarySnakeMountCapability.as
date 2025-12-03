class USanctuarySnakeMountCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SanctuarySnake");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	ASanctuarySnake Snake;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
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
		auto SnakeRiderComponent = USanctuarySnakeRiderComponent::Get(Player);
		Snake = SnakeRiderComponent.Snake;

		Player.AttachToComponent(Snake.RiderAttachpoint);
		Snake.SanctuarySnakeComponent.bHasRider = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DetachFromActor();
		Snake.SanctuarySnakeComponent.bHasRider = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
};
class UCentipedeWaterOutletSprayCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerCentipedeComponent CentipedeComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		UCentipedeBiteComponent OtherPlayerCentipedeBiteComponent = UCentipedeBiteComponent::Get(Player.OtherPlayer);
		if (OtherPlayerCentipedeBiteComponent == nullptr)
			return false;

		UCentipedeBiteResponseComponent BittenComponent = OtherPlayerCentipedeBiteComponent.GetBittenComponent();
		if (BittenComponent == nullptr)
			return false;

		ACentipedeWaterOutlet WaterOutlet = Cast<ACentipedeWaterOutlet>(BittenComponent.Owner);
		if (WaterOutlet == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		UCentipedeBiteComponent OtherPlayerCentipedeBiteComponent = UCentipedeBiteComponent::Get(Player.OtherPlayer);
		if (OtherPlayerCentipedeBiteComponent == nullptr)
			return true;

		UCentipedeBiteResponseComponent BittenComponent = OtherPlayerCentipedeBiteComponent.GetBittenComponent();
		if (BittenComponent == nullptr)
			return true;

		ACentipedeWaterOutlet WaterOutlet = Cast<ACentipedeWaterOutlet>(BittenComponent.Owner);
		if (WaterOutlet == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CentipedeTags::CentipedeBite, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CentipedeTags::CentipedeBite, this);

		CentipedeComponent.ClearMovementFacingDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MovementFacingDirection = (Player.ActorLocation - Player.OtherPlayer.ActorLocation).ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal();
		CentipedeComponent.ApplyMovementFacingDirectionOverride(MovementFacingDirection, this);
	}
}
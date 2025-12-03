class UCentipedeBiteDoubleInteractionFacingDirectionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent BiteComponent;

	FVector InitialForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		BiteComponent = UCentipedeBiteComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BiteComponent.IsDoubleInteractionBite())
			return false;

		UCentipedeBiteComponent OtherPlayerBiteComponent = UCentipedeBiteComponent::Get(Player.OtherPlayer);
		if (!OtherPlayerBiteComponent.IsDoubleInteractionBite())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BiteComponent.IsDoubleInteractionBite())
			return true;

		UCentipedeBiteComponent OtherPlayerBiteComponent = UCentipedeBiteComponent::Get(Player.OtherPlayer);
		if (!OtherPlayerBiteComponent.IsDoubleInteractionBite())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialForward = CentipedeComponent.GetMeshHeadTransform().Rotation.ForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CentipedeComponent.ClearMovementFacingDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// FVector TargetLocation = UCentipedeBiteComponent::Get(Player.OtherPlayer).GetBiteLocation();

		// Eman TODO: Use initial forward for now
		FVector FacingDirection = InitialForward;
		CentipedeComponent.ApplyMovementFacingDirectionOverride(FacingDirection.GetSafeNormal(), this, EInstigatePriority::High);
	}
}
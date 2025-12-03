class UCentipedeHeadInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerMovementComponent MovementComponent;

	UHazeCrumbSyncedVectorComponent CrumbedMovementInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);

		CrumbedMovementInput = UHazeCrumbSyncedVectorComponent::GetOrCreate(Owner, n"CrumbedCentipedeMovementInput");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MoveInput = Centipede::GetPlayerHeadMovementInput(Player, GetAttributeVector2D(AttributeVectorNames::MovementRaw));
		Player.ApplyMovementInput(MoveInput, this);

		if (HasControl())
			CrumbedMovementInput.Value = MoveInput;

		CentipedeComponent.Centipede.PlayerMovementInput[Player] = Math::VInterpTo(CentipedeComponent.Centipede.PlayerMovementInput[Player], CrumbedMovementInput.Value, DeltaTime, 8);
	}
}
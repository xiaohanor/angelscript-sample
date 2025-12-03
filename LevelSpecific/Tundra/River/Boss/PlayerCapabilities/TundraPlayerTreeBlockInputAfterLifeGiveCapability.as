class UTundraPlayerTreeBlockInputAfterLifeGiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UTundraPlayerTreeBlockInputAfterLifeGiveComponent Comp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Comp = UTundraPlayerTreeBlockInputAfterLifeGiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Comp.bShouldBeActive)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Comp.bShouldBeActive)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		if (Math::Abs(RawInput.Y) <= 0.25)
			Comp.bShouldBeActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}
};
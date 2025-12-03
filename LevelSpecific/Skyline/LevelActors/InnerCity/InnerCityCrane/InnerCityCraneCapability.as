class UInnerCityCraneCapability : UHazeCapability
{   
	UInnerCityCraneComponent CraneInputReceivingComponenent;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
		CraneInputReceivingComponenent = UInnerCityCraneComponent::Get(Owner);

        CapabilityInput::LinkActorToPlayerInput(Owner, Game::GetPlayer(CraneInputReceivingComponenent.PlayerInput));
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if (CraneInputReceivingComponenent == nullptr)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		auto Input = (CraneInputReceivingComponenent.bUseMovementRaw ? GetAttributeVector2D(AttributeVectorNames::MovementRaw) : GetAttributeVector2D(AttributeVectorNames::LeftStickRaw));

        CraneInputReceivingComponenent.Input = Input;
    }

}
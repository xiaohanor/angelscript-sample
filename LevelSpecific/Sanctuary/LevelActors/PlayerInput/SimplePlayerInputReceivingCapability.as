class USimplePlayerInputReceivingCapability : UHazeCapability
{   
	USimplePlayerInputReceivingComponenent SimplePlayerInputReceivingComponenent;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
		SimplePlayerInputReceivingComponenent = USimplePlayerInputReceivingComponenent::Get(Owner);

        CapabilityInput::LinkActorToPlayerInput(Owner, Game::GetPlayer(SimplePlayerInputReceivingComponenent.PlayerInput));
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if (SimplePlayerInputReceivingComponenent == nullptr)
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
		auto Input = (SimplePlayerInputReceivingComponenent.bUseMovementRaw ? GetAttributeVector2D(AttributeVectorNames::MovementRaw) : GetAttributeVector2D(AttributeVectorNames::LeftStickRaw));

        SimplePlayerInputReceivingComponenent.Input = Input;
    }

}
class USkylineDivingCarTurnCapability : UHazeCapability
{
    
    ASkylineDivingCar DivingCar;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        DivingCar = Cast<ASkylineDivingCar>(Owner);
        CapabilityInput::LinkActorToPlayerInput(DivingCar, Game::GetPlayer(DivingCar.Pilot));
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
    void TickActive(float DeltaTime)
    {
        auto Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
        
        if(Input.Size() > 0.3)
            DivingCar.Input = Input;

    }

}
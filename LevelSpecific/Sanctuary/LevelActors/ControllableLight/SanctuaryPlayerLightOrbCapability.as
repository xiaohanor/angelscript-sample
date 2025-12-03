class USanctuaryPlayerLightOrbCapability : UHazeCapability
{
    
    ASanctuaryPlayerLightOrb ControllableLight;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        ControllableLight = Cast<ASanctuaryPlayerLightOrb>(Owner);
        CapabilityInput::LinkActorToPlayerInput(ControllableLight, Game::GetPlayer(ControllableLight.Pilot));
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
        
        // if(Input.Size() > 0.3)
            ControllableLight.Input = Input;

    }

}
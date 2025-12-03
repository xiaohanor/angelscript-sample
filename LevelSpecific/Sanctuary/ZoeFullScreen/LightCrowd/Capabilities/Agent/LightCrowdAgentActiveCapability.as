class ULightCrowdAgentActiveCapability : UHazeCapability
{
    default CapabilityTags.Add(LightCrowdTags::LightCrowd);
    default CapabilityTags.Add(LightCrowdTags::LightCrowdAgent);

    default TickGroup = EHazeTickGroup::Gameplay;

    ALightCrowdAgent Agent;
    ULightCrowdDataComponent DataComp;

    default TickGroup = EHazeTickGroup::Gameplay;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Agent = Cast<ALightCrowdAgent>(Owner);
        DataComp = ULightCrowdDataComponent::Get(Game::Zoe);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(Agent.State != ELightCrowdAgentState::Active)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(Agent.State != ELightCrowdAgentState::Active)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        Agent.Light.SetIntensity(Settings.AgentLightIntensity);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FVector ThisLocation = Agent.ActorLocation;
        ThisLocation.Z = 0.0;

        FVector PlayerLocation = Game::Zoe.ActorLocation;
        PlayerLocation.Z = 0.0;

        float DistanceToPlayer = ThisLocation.Distance(PlayerLocation);

		// Disable shadows when far from the player to save performance
        Agent.Light.CastShadows = DistanceToPlayer < Settings.AgentShadowDistance;

		// If we are too far away, respawn
        if(DistanceToPlayer > Settings.FurthestSpawnDistance + 100.0)
            Agent.State = ELightCrowdAgentState::Despawning;
    }

    ULightCrowdSettings GetSettings() const property
    {
        return DataComp.Settings;
    }
}
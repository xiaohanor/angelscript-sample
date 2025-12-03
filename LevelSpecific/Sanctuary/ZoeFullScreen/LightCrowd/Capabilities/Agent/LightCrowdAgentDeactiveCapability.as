class ULightCrowdAgentDeactiveCapability : UHazeCapability
{
	default CapabilityTags.Add(LightCrowdTags::LightCrowd);
    default CapabilityTags.Add(LightCrowdTags::LightCrowdAgent);

    default TickGroup = EHazeTickGroup::BeforeMovement;

    ALightCrowdAgent Agent;
    ULightCrowdPlayerComponent PlayerComp;
    ULightCrowdDataComponent DataComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Agent = Cast<ALightCrowdAgent>(Owner);
        PlayerComp = ULightCrowdPlayerComponent::Get(Game::Zoe);
        DataComp = ULightCrowdDataComponent::Get(Game::Zoe);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(Agent.State != ELightCrowdAgentState::Deactive)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		// Teleport to respawn location
        FVector RespawnLocation = PlayerComp.GetRandomSpawnLocation(false);
        FHitResult Hit;
        Agent.SetActorLocation(RespawnLocation, false, Hit, true);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Agent.State = ELightCrowdAgentState::Spawning;
    }

    ULightCrowdSettings GetSettings() const property
    {
        return DataComp.Settings;
    }
}
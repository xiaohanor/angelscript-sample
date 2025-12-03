class ULightCrowdAgentDespawnCapability : UHazeCapability
{
	default CapabilityTags.Add(LightCrowdTags::LightCrowd);
    default CapabilityTags.Add(LightCrowdTags::LightCrowdAgent);

    default TickGroup = EHazeTickGroup::Gameplay;

    ALightCrowdAgent Agent;
    ULightCrowdDataComponent DataComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Agent = Cast<ALightCrowdAgent>(Owner);
        DataComp = ULightCrowdDataComponent::Get(Game::Zoe);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(Agent.State != ELightCrowdAgentState::Despawning)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(ActiveDuration > Settings.AgentLightFadeOutDuration)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Agent.Light.SetIntensity(0.0);
        Agent.State = ELightCrowdAgentState::Deactive;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        float LightAlpha = 1.0 - (ActiveDuration / Settings.AgentLightFadeOutDuration);
        Agent.Light.SetIntensity(Settings.AgentLightIntensity * LightAlpha);
    }

    ULightCrowdSettings GetSettings() const property
    {
        return DataComp.Settings;
    }
}
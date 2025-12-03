class ULightCrowdAgentSpawnCapability : UHazeCapability
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
        if(Agent.State != ELightCrowdAgentState::Spawning)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(ActiveDuration > Settings.AgentLightFadeInDuration)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        Agent.Light.SetIntensity(0.0);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Agent.Light.SetIntensity(Settings.AgentLightIntensity);
        Agent.State = ELightCrowdAgentState::Active;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        const float LightAlpha = ActiveDuration / Settings.AgentLightFadeInDuration;
        Agent.Light.SetIntensity(Settings.AgentLightIntensity * LightAlpha);
    }

    ULightCrowdSettings GetSettings() const property
    {
        return DataComp.Settings;
    }
}
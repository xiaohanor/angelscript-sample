class ULightCrowdAgentMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(LightCrowdTags::LightCrowd);
    default CapabilityTags.Add(LightCrowdTags::LightCrowdAgent);

    ALightCrowdAgent Agent;
    ULightCrowdDataComponent DataComp;

    default TickGroup = EHazeTickGroup::Movement;

    FHazeAcceleratedVector AccVelocity;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Agent = Cast<ALightCrowdAgent>(Owner);
        DataComp = ULightCrowdDataComponent::Get(Game::Zoe);
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
    void OnActivated()
    {
        AccVelocity.Value = FVector::ZeroVector;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FVector TargetVelocity = FVector::ZeroVector;

        FVector ThisLocation = Agent.ActorLocation;
        ThisLocation.Z = 0.0;

        FVector PlayerLocation = Game::Zoe.ActorLocation;
        PlayerLocation.Z = 0.0;

        const float DistanceToPlayer = ThisLocation.Distance(PlayerLocation);

        if(DistanceToPlayer < Settings.PlayerAvoidDistance)
        {
            FVector DirFromPlayer = -((PlayerLocation - ThisLocation) / DistanceToPlayer);

            float DistanceAlpha = 1.0 - (DistanceToPlayer / Settings.PlayerAvoidDistance);
            DistanceAlpha = Math::Pow(DistanceAlpha, Settings.PlayerAvoidExponent);

            float Force = DistanceAlpha * Settings.PlayerAvoidForce;

            TargetVelocity += (DirFromPlayer * Force);
        }

        ULightCrowdPlayerComponent Manager = LightCrowd::GetPlayerComp();
        for(auto It : Manager.Agents)
        {
            if(It == Agent)
                continue;

            FVector AgentLocation = It.ActorLocation;
            AgentLocation.Z = 0.0;

            float DistanceToAgent = ThisLocation.Distance(AgentLocation);
            if(DistanceToAgent >= Settings.AgentAvoidDistance)
                continue;

            FVector DirFromPlayer = -((AgentLocation - ThisLocation) / DistanceToAgent);

            float DistanceAlpha = 1.0 - (DistanceToAgent / Settings.AgentAvoidDistance);
            DistanceAlpha = Math::Pow(DistanceAlpha, Settings.AgentAvoidExponent);

            float Force = DistanceAlpha * Settings.AgentAvoidForce;
            TargetVelocity += (DirFromPlayer * Force);
        }

        AccVelocity.AccelerateTo(TargetVelocity, Settings.AvoidAccelerationDuration, DeltaTime);

		if(!AccVelocity.Value.IsNearlyZero())
        	Agent.AddActorWorldOffset(AccVelocity.Value);
    }

    ULightCrowdSettings GetSettings() const property
    {
        return DataComp.Settings;
    }
}
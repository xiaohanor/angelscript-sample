
// Capability to control timing of state updating
class UBasicAIUpdateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Update");

	// States are updated before evaluating state capabilities
	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIDestinationComponent DestinationComp;
	UBasicAIAnimationComponent AnimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);

		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
		{
			UBasicBehaviourComponent::Get(Owner).OnUnspawn.AddUFunction(RespawnComp, n"UnSpawn");	
			RespawnComp.OnRespawn.AddUFunction(UBasicBehaviourComponent::Get(Owner), n"Reset");
			RespawnComp.OnRespawn.AddUFunction(UBasicAIHealthComponent::Get(Owner), n"Reset");
			RespawnComp.OnRespawn.AddUFunction(DestinationComp, n"Reset");
			RespawnComp.OnRespawn.AddUFunction(AnimComp, n"Reset");
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.Update();
		AnimComp.Update(DeltaTime);
	}
}
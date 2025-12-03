
// Move towards enemy
class UIslandBuzzerTurtlingBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandBuzzerSettings BuzzerSettings;
	UHazeActorRespawnableComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BuzzerSettings = UIslandBuzzerSettings::GetSettings(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(!IsTurtling())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if(!IsTurtling())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Dir = (Game::Zoe.ActorLocation - RespawnComp.Spawner.ActorLocation).GetSafeNormal();
		FVector TurtleLocation = RespawnComp.Spawner.ActorLocation + Dir * 1000;
		TurtleLocation.Z += BasicSettings.FlyingChaseHeight;

		if (Owner.ActorLocation.IsWithinDist(TurtleLocation, 500))
		{
			Cooldown.Set(0.5);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(TurtleLocation, BasicSettings.ChaseMoveSpeed);
	}

	bool IsTurtling() const
	{
		if(RespawnComp != nullptr && RespawnComp.Spawner != nullptr)
		{
			auto LegsComp = UIslandWalkerLegsComponent::Get(RespawnComp.Spawner);
			if(LegsComp == nullptr)
				return false;

			if(LegsComp.NumDestroyedLegs() >= 2)
				return true;
		}
		return false;
	}
}
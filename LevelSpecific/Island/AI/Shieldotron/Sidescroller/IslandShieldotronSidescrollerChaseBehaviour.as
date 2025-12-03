
// Move towards enemy
class UIslandShieldotronSidescrollerChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandShieldotronSidescrollerSettings Settings;
	UHazeMovementComponent MoveComp;	

	bool bIsBlockingCrowdRepulsion = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();		
		MoveComp = UHazeMovementComponent::Get(Owner);
		Settings = UIslandShieldotronSidescrollerSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if (bIsBlockingCrowdRepulsion)
			Owner.UnblockCapabilities(n"CrowdRepulsion", this);

		bIsBlockingCrowdRepulsion = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Math::Abs(Owner.ActorLocation.X - TargetComp.Target.ActorLocation.X) < Settings.ChaseMinRange)
			return false;
		if (Math::Abs(Owner.ActorLocation.X - TargetComp.Target.ActorLocation.X) > Settings.ChaseMaxRange)
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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		if (bIsBlockingCrowdRepulsion)
			Owner.UnblockCapabilities(n"CrowdRepulsion", this);

		bIsBlockingCrowdRepulsion = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Math::Abs(Owner.ActorLocation.X - TargetComp.Target.ActorLocation.X) < Settings.ChaseMinRange)
		{
			Cooldown.Set(Settings.ChaseMinRangeCooldown);
			return;
		}			
		else if (Math::Abs(Owner.ActorLocation.X - TargetComp.Target.ActorLocation.X) > Settings.ChaseMaxRange)
		{
			Cooldown.Set(Settings.ChaseMinRangeCooldown);
			return;
		}

		FVector Destination = TargetComp.Target.ActorLocation;

		// Keep moving towards target!
		DestinationComp.MoveTowards(Destination, Settings.ChaseMoveSpeed);

		
	}
}
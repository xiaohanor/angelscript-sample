
// Move towards enemy
class UIslandPunchotronChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UGentlemanCostComponent GentCostComp;
	UIslandPunchotronSettings Settings;
	AAIIslandPunchotron Punchotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.ChaseMinRange))
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
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.ChaseMinRange))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.ChaseMinRange))
		{
			Cooldown.Set(Settings.ChaseMinRangeCooldown);
			return;
		}

		float Dist2D = (Owner.ActorLocation - TargetComp.Target.ActorLocation).Size2D();
		float MaxChaseSpeed = Settings.ChaseMoveSpeed;
		UPlayerSprintComponent SprintComp = UPlayerSprintComponent::Get(TargetComp.Target);
		if (SprintComp != nullptr && !SprintComp.IsSprinting())
			MaxChaseSpeed = Settings.ChaseMoveSpeed * 0.8;
		float ChaseMoveSpeed = Math::GetMappedRangeValueClamped(FVector2D(Settings.ChaseMinRange, Settings.ChaseScaleDownMoveSpeedRange), FVector2D(0, MaxChaseSpeed), Dist2D);
		// Keep moving towards target!
		DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, ChaseMoveSpeed);
	}
}
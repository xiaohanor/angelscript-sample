
// Move back and forth against enemy
class UHighwayEnforcerShuffleBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USkylineEnforcerBoundsComponent BoundsComp;

	float Duration;
	bool bForward;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BoundsComp = USkylineEnforcerBoundsComponent::GetOrCreate(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
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
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Duration = Math::RandRange(BasicSettings.ShuffleDurationMin, BasicSettings.ShuffleDurationMax);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		Cooldown.Set(Math::RandRange(BasicSettings.ShuffleCooldownMin, BasicSettings.ShuffleCooldownMin));		
		bForward = !bForward;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Dir = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		if(!bForward)
			Dir *= -1;
		FVector Destination = Owner.ActorLocation + Dir * 100;

		if(StopShuffle(Destination))
		{
			DeactivateBehaviour();
			return;
		}

		DestinationComp.MoveTowardsIgnorePathfinding(Destination, BasicSettings.ShuffleMoveSpeed);
	}

	bool StopShuffle(FVector Dest)
	{	
		if(ActiveDuration > Duration)
			return true;

		if(DestinationComp.MoveFailed())
			return true;

		if(!BoundsComp.LocationIsWithinBounds(Dest + Owner.ActorUpVector * Radius, Radius))
			return true;

		return false;
	}
}
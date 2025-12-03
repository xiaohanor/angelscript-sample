
// Move back and forth against enemy
class UEnforcerHighwayShuffleBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UArcTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings;

	float Duration;
	bool bForward;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;

		TraversalComp = UArcTraversalComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
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

		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (!Pathfinding::HasPath(Owner.ActorLocation, TargetLoc))
			Cooldown.Set(1);
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

		DestinationComp.MoveTowards(Destination, BasicSettings.ShuffleMoveSpeed);

		if(StopShuffle(Destination))
		{
			DeactivateBehaviour();
			return;
		}
	}

	bool StopShuffle(FVector Dest)
	{	
		if(ActiveDuration > Duration)
			return true;

		if(DestinationComp.MoveFailed())
			return true;

		FVector DestNavMesh;
		FVector PathDest = Dest + (Dest - Owner.ActorLocation).GetSafeNormal() * Radius;
		if(!Pathfinding::FindNavmeshLocation(PathDest, 0.0, 100.0, DestNavMesh))
			return true;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, DestNavMesh))
			return true;

		return false;
	}
}
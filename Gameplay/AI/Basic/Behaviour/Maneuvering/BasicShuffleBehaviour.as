
// Move back and forth against enemy
class UBasicShuffleBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	float Duration;
	FVector Direction;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
		Direction = Owner.ActorForwardVector;
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Destination = Owner.ActorLocation + Direction * 100;
		DestinationComp.MoveTowards(Destination, BasicSettings.ShuffleMoveSpeed);

		if(NaturalEnd(Destination))
		{
			Direction = Owner.ActorForwardVector.RotateAngleAxis(Math::RandRange(0, 360), FVector::UpVector);
			DeactivateBehaviour();
		}
		else if(DestinationFail(Destination))
		{
			Direction = (-Direction).RotateAngleAxis(Math::RandRange(-120, 120), FVector::UpVector);
			DeactivateBehaviour();
		}
	}

	bool NaturalEnd(FVector Dest)
	{	
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	bool DestinationFail(FVector Dest)
	{
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
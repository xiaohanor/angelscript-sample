
class UIslandOverseerTowardsChaseMoveIntoPositionBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;

	FBasicAIAnimationActionDurations Durations;
	AHazeCharacter Character;

	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;
	FVector TargetLocation;
	FRotator TargetRotation;
	bool bCompleted;
	UIslandOverseerTowardsChaseComponent TowardsChaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);

		TListedActors<AIslandOverseerTowardsChasePoint> Points;
		TargetLocation = Points[0].ActorLocation;
		TargetRotation = Points[0].ActorRotation;
		TowardsChaseComp = UIslandOverseerTowardsChaseComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bCompleted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		// if(Owner.ActorLocation.IsWithinDist(TargetLocation, 25))
		// 	return true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccLocation.SnapTo(Owner.ActorLocation);
		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
		TowardsChaseComp.OnArrived.Broadcast();
		Owner.ActorRotation = TargetRotation;
		Owner.ActorLocation = TargetLocation;
		Owner.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// AccLocation.AccelerateTo(TargetLocation, 4, DeltaTime);
		// Owner.ActorLocation = AccLocation.Value;

		// AccRotation.AccelerateTo(TargetRotation, 4, DeltaTime);
		// Owner.ActorRotation = AccRotation.Value;
	}
}
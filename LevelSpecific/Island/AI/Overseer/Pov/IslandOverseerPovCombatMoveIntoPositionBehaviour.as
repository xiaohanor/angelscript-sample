
class UIslandOverseerPovCombatMoveIntoPositionBehaviour : UBasicBehaviour
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
	bool bArrived;
	float CompletedTime;
	UIslandOverseerPovComponent PovComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);

		PovComp = UIslandOverseerPovComponent::Get(Owner);

		AIslandOverseerPovCombatPoint MovePoint = TListedActors<AIslandOverseerPovCombatPoint>()[0];
		TargetLocation = MovePoint.ActorLocation;
		TargetRotation = MovePoint.ActorRotation;
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
		if(CompletedTime > 0 && Time::GetGameTimeSince(CompletedTime) > 2)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccLocation.Value = TargetLocation - FVector(2000, 0, 2000);
		Owner.ActorRotation = TargetRotation;
		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ActorLocation = TargetLocation;
		bCompleted = true;
		Owner.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bArrived && PovComp.bIntroEnded && CompletedTime == 0)
		{
			CompletedTime = Time::GameTimeSeconds;
			return;	
		}

		AccLocation.AccelerateTo(TargetLocation, 5, DeltaTime);
		Owner.ActorLocation = AccLocation.Value;

		if(!bArrived && Owner.ActorLocation.IsWithinDist(TargetLocation, 25))
		{
			bArrived = true;
			PovComp.OnArrived.Broadcast();
		}
	}
}

class UIslandOverseerSideChaseMoveIntoPositionBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	AHazeCharacter Character;
	UIslandOverseerSideChaseComponent SideChaseComp;
	UIslandOverseerPovComponent PovComp;
	UIslandOverseerHoistComponent HoistComp;
	UIslandOverseerVisorComponent VisorComp;

	FBasicAIAnimationActionDurations Durations;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;
	FVector TargetLocation;
	FRotator TargetRotation;
	bool bCompleted;
	bool bDropped;
	float bArrived;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);		

		AIslandOverseerSideChaseDropPoint DropPoint = TListedActors<AIslandOverseerSideChaseDropPoint>().GetSingle();
		TargetLocation = DropPoint.ActorLocation;
		TargetRotation = DropPoint.ActorRotation;

		SideChaseComp = UIslandOverseerSideChaseComponent::GetOrCreate(Owner);
		PovComp = UIslandOverseerPovComponent::Get(Owner);
		HoistComp = UIslandOverseerHoistComponent::GetOrCreate(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
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
		if(CanDeactivate())
			return true;
		return false;
	}

	private bool CanDeactivate() const
	{
		return ActiveDuration > 5 && !PovComp.PovCamera.bOutro;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccLocation.SnapTo(Owner.ActorLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
		VisorComp.Open();

		if(Owner.ActorLocation.IsWithinDist(TargetLocation, 25))
		{
			DeactivateBehaviour();
			return;
		}

		HoistComp.HoistUp();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
		Owner.ActorLocation = TargetLocation;
		Owner.ActorRotation = TargetRotation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < 2)
			return;

		AccLocation.SpringTo(TargetLocation, 50, 0.75, DeltaTime);
		Owner.ActorLocation = AccLocation.Value;

		AccRotation.AccelerateTo(TargetRotation, 4, DeltaTime);
		Owner.ActorRotation = AccRotation.Value;
	}
}
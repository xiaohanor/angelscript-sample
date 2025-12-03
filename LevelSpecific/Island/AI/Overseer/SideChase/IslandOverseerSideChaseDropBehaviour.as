
class UIslandOverseerSideChaseDropBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	AHazeCharacter Character;
	UIslandOverseerSideChaseComponent SideChaseComp;
	UIslandOverseerPovComponent PovComp;
	UIslandOverseerHoistComponent HoistComp;
	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerControlCraneComponent ControlCraneComp;
	UAnimInstanceIslandOverseer AnimInstance;

	FBasicAIAnimationActionDurations Durations;
	FVector TargetLocation;
	FRotator TargetRotation;
	bool bCompleted;
	float DropDistance;
	float DropTime;
	bool bLanded;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Character.Mesh.AnimInstance);

		AIslandOverseerSideChaseDropPoint DropPoint = TListedActors<AIslandOverseerSideChaseDropPoint>().GetSingle();
		FVector DropLocation = DropPoint.ActorLocation;

		AIslandOverseerSideChasePoint Point = TListedActors<AIslandOverseerSideChasePoint>().GetSingle();
		TargetLocation = Point.ActorLocation;
		TargetRotation = Point.ActorRotation;

		DropDistance = Math::Abs(DropLocation.Z - TargetLocation.Z);

		SideChaseComp = UIslandOverseerSideChaseComponent::GetOrCreate(Owner);
		PovComp = UIslandOverseerPovComponent::Get(Owner);
		HoistComp = UIslandOverseerHoistComponent::GetOrCreate(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		ControlCraneComp = UIslandOverseerControlCraneComponent::GetOrCreate(Owner);
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
		return ActiveDuration > 2;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		VisorComp.Open();
		HoistComp.HoistUp();
		ControlCraneComp.Drop();
		DropTime = AnimInstance.HoistUpEnd.Sequence.GetAnimNotifyTime(UIslandOverseerSideChaseDropLandAnimNotify);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
		SideChaseComp.OnArrived.Broadcast();
		Owner.ActorLocation = TargetLocation;
		Owner.ActorRotation = TargetRotation;
		HoistComp.Drop();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HoistComp.Drop();
		FVector Move = Owner.ActorUpVector * -DropDistance;
		AnimComp.RequestFeature(FeatureTagIslandOverseer::Drop, EBasicBehaviourPriority::Medium, this, 0.0, Move);

		if(!bLanded && ActiveDuration > DropTime)
		{
			bLanded = true;
			UIslandOverseerEventHandler::Trigger_OnDropLand(Owner);
		}
	}
}
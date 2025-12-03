
class UIslandOverseerAdvanceBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	UIslandOverseerSettings Settings;
	AHazeCharacter Character;
	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerAdvanceComponent AdvanceComp;

	float Distance;
	float TargetDistance;
	int Activations = 0;
	int ActivationsMax = 3;
	AActor Indicator;
	bool bStarted;
	bool bStopping;

	float Duration = 1.5;
	float Telegraph = 0.5;

	FVector TargetLocation;
	FHazeAcceleratedVector AccLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);

		FVector DoorLocation = TListedActors<AIslandOverseerDoorPoint>().GetSingle().ActorLocation;
		FVector LimitLocation = TListedActors<AIslandOverseerAdvanceLimit>().GetSingle().ActorLocation;		
		TargetDistance = DoorLocation.Distance(LimitLocation) / 3;

		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		AdvanceComp = UIslandOverseerAdvanceComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(Activations >= ActivationsMax)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Duration + Telegraph)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Distance = 0;
		VisorComp.Open();
		Activations++;
		bStarted = false;
		bStopping = false;
		FVector Delta = Owner.ActorForwardVector * TargetDistance;
		Indicator = SpawnActor(AdvanceComp.IndicatorClass, Owner.ActorLocation + Delta + Owner.ActorForwardVector * 400, Level = Owner.Level);

		AccLocation.SnapTo(Owner.ActorLocation);
		TargetLocation = Owner.ActorLocation + Delta;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(1);
		Indicator.AddActorDisable(this);
		Owner.ActorLocation = TargetLocation;
		UIslandOverseerEventHandler::Trigger_OnMoveStopped(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < Telegraph)
			return;

		AccLocation.SpringTo(TargetLocation, 100, 0.4, DeltaTime);
		Owner.ActorLocation = AccLocation.Value;

		if(!bStarted)
		{
			bStarted = true;
			UIslandOverseerEventHandler::Trigger_OnAdvanceStart(Owner);
			UIslandOverseerEventHandler::Trigger_OnMoveStarted(Owner);
		}

		if(!bStopping && ActiveDuration > Telegraph + Duration - 0.5)
		{
			bStopping = true;
			UIslandOverseerEventHandler::Trigger_OnMoveStopping(Owner);
		}
	}
}

class UIslandOverseerFloodHideBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	AHazeCharacter Character;
	FHazeAcceleratedVector AccLocation;
	FVector TargetLocation;
	bool bCompleted;
	UIslandOverseerFloodComponent FloodComp;
	UIslandOverseerControlCraneComponent CraneComp;

	FHazeAcceleratedVector AccFloodLocation;
	FVector FloodStartLocation;
	AIslandOverseerFlood Flood;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		FloodComp = UIslandOverseerFloodComponent::Get(Owner);
		CraneComp = UIslandOverseerControlCraneComponent::Get(Owner);
		Flood = TListedActors<AIslandOverseerFlood>().GetSingle();
		FloodStartLocation = Flood.ActorLocation;
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
		if(Owner.ActorLocation.IsWithinDist(TargetLocation, 25))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccLocation.SnapTo(Owner.ActorLocation);
		TargetLocation = Flood.ActorLocation + Character.ActorUpVector * 10000;
		AccFloodLocation.SnapTo(Flood.ActorLocation);
		UIslandOverseerCraneEventHandler::Trigger_OnLeaveFloodStart(CraneComp.Crane);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccLocation.AccelerateTo(TargetLocation, 10, DeltaTime);
		Owner.ActorLocation = AccLocation.Value;
	}
}
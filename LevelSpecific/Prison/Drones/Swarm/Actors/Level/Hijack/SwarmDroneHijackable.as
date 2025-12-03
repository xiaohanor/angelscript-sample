class ASwarmDroneHijackable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USwarmDroneHijackTargetableComponent HijackComponent;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.InitialStoppedSheets.Add(HijackCapabilitySheet);

	UPROPERTY(EditAnywhere)
	private UHazeCapabilitySheet HijackCapabilitySheet;


	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedPositionComponent;
	default CrumbSyncedPositionComponent.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default CrumbSyncedPositionComponent.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Drone::SwarmDronePlayer);

		HijackComponent.OnHijackStartEvent.AddUFunction(this, n"OnHijackStart");
		HijackComponent.OnHijackStopEvent.AddUFunction(this, n"OnHijackStop");
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnHijackStart(FSwarmDroneHijackParams HijackParams)
	{
		CapabilityInput::LinkActorToPlayerInput(this, HijackParams.Player);

		if (HijackCapabilitySheet != nullptr)
			StartCapabilitySheet(HijackCapabilitySheet, this);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnHijackStop()
	{
		CapabilityInput::LinkActorToPlayerInput(this, nullptr);

		if (HijackCapabilitySheet != nullptr)
			StopCapabilitySheet(HijackCapabilitySheet, this);
	}
}
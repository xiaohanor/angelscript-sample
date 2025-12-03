
class UIslandOverseerDoorForceBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UAnimInstanceIslandOverseer AnimInstance;
	UBasicAIHealthComponent HealthComp;
	UIslandOverseerDoorComponent DoorComp;

	bool bOpened;
	float Duration;
	bool bAttached;
	bool bFirstFrameTick;
	bool bHasTeleported;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Character.Mesh.AnimInstance);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		DoorComp = UIslandOverseerDoorComponent::Get(Owner);
		Duration = AnimInstance.DoorCutHeadStart.Sequence.PlayLength;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bOpened)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DoorComp.StartCombat();
		Owner.BlockCapabilities(n"Attack", Owner);
		UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingForced(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

		// SoundDef on doors
		for(auto& Door : DoorComp.Doors)
		{
			UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingForced(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
		}

		DoorComp.EnableCutHeadState();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bOpened = true;
		Owner.UnblockCapabilities(n"Attack", Owner);
		UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingForced(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

		// SoundDef on doors
		for(auto& Door : DoorComp.Doors)
		{
			UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingForced(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// We teleport the Overseer after the first frame since the animation that gets triggered by DoorComp.EnableCutHeadState(); has an offset but doesn't start playing until the frame after
		if(bFirstFrameTick && !bHasTeleported)
		{
			bHasTeleported = true;
			Owner.ActorLocation = DoorComp.CutHeadLocation;
		}

		if(!bFirstFrameTick)
			bFirstFrameTick = true;

		if(!bAttached && ActiveDuration > 0.1)
		{
			bAttached = true;
			DoorComp.AttachCutHeadDoors();
		}
	}
}
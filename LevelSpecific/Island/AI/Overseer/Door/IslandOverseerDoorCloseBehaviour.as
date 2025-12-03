
class UIslandOverseerDoorCloseBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	AHazeCharacter Character;
	UIslandOverseerDoorComponent DoorComp;
	UIslandOverseerPhaseComponent PhaseComp;
	bool bDoorClosed;
	
	float ImpulseMioTime = 0;
	float ImpulseZoeTime = 0;

	float ImpulseTime;
	float ImpulseDuration = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		DoorComp = UIslandOverseerDoorComponent::Get(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::Get(Owner);
		DoorComp.OnDoorImpulse.AddUFunction(this, n"OnDoorImpulse");
	}

	UFUNCTION()
	private void OnDoorImpulse(AHazeActor Instigator)
	{
		if(!IsActive())
			return;
		if(bDoorClosed)
			return;

		if(Instigator == Game::Mio)
			ImpulseMioTime = Time::GameTimeSeconds;
		else
			ImpulseZoeTime = Time::GameTimeSeconds;

		if(Math::Abs(ImpulseMioTime - ImpulseZoeTime) < 0.3)
		{
			if(ImpulseTime == 0)
			{
				UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMoving(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

				// SoundDef on doors
				for(auto& Door : DoorComp.Doors)
				{
					UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMoving(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
				}

			}
			ImpulseTime = Time::GameTimeSeconds;
			DoorComp.StartClosingDoors();
			return;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bDoorClosed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(DoorComp.Doors[0].DistanceFromClosed <= 10)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DoorComp.bDoorClosing = true;
		Owner.BlockCapabilities(n"OpenDoorAttack", Owner);

		if(DoorComp.bInstantClose)
		{
			DoorComp.InstantCloseDoors();
			Finished();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		DoorComp.StopClosingDoors();
		DoorComp.bDoorClosing = false;
		bDoorClosed = true;
		DoorComp.OnDoorClosed.Broadcast();
		Owner.UnblockCapabilities(n"OpenDoorAttack", Owner);
		UIslandOverseerDoorEventHandler::Trigger_OnDoorsClosed(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
	}

	UFUNCTION()
	private void Finished()
	{
		if(!IsActive())
			return;
		DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDoorClosed)
			return;	

		if(DoorComp.Doors[0].DistanceFromClosed <= 50)
		{
			bDoorClosed = true;
			DoorComp.StartClosingDoors();
			return;
		}

		if(ImpulseTime != 0)
		{
			if(Time::GetGameTimeSince(ImpulseTime) > ImpulseDuration)
			{
				DoorComp.StopClosingDoors();
				ImpulseTime = 0;
				UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMoving(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
				
				// SoundDef on doors
				for(auto& Door : DoorComp.Doors)
				{
					UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMoving(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
				}
			}
			return;
		}
	}
}
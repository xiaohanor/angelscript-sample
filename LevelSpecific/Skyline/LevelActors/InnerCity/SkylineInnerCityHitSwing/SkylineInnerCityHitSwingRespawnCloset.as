enum ESkylineInnerCityHitSwingRespawnClosetDoorState
{
	Closed,
	Opening,
	Open,
	Closening,
}

class ASkylineInnerCityHitSwingRespawnCloset : AHazeActor
{
	access ReadOnly = private, * (readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshDoor;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshVoid;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent RespawnLocation;
	default RespawnLocation.CollisionProfileName = n"NoCollision";

	FHazeAcceleratedFloat AccDoor;
	FVector OGMeshDoorRelativeLocation;

	access:ReadOnly ESkylineInnerCityHitSwingRespawnClosetDoorState State;
	private bool bOpen = false;

	void SetOpenState(bool bNewOpen)
	{
		if (bNewOpen == bOpen)
			return;
		if (bNewOpen)
		{
			USkylineInnerCityHitSwingRespawnClosetEventHandler::Trigger_OnRespawnDoorOpening(this);
			State = ESkylineInnerCityHitSwingRespawnClosetDoorState::Opening;
		}
		else
		{
			USkylineInnerCityHitSwingRespawnClosetEventHandler::Trigger_OnRespawnDoorClosing(this);
			State = ESkylineInnerCityHitSwingRespawnClosetDoorState::Closening;
		}
		bOpen = bNewOpen;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OGMeshDoorRelativeLocation = MeshDoor.RelativeLocation;
		AccDoor.SnapTo(MeshDoor.RelativeLocation.Z);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bOpen)
			AccDoor.AccelerateTo(-340.0, 0.2, DeltaSeconds);
		else
			AccDoor.AccelerateTo(0.0, 0.1, DeltaSeconds);
		
		UpdateEvents();

		FVector Target = OGMeshDoorRelativeLocation;
		Target.Z = AccDoor.Value;
		MeshDoor.SetRelativeLocation(Target);
	}

	private void UpdateEvents()
	{
		if (State == ESkylineInnerCityHitSwingRespawnClosetDoorState::Opening && Math::IsNearlyEqual(AccDoor.Value, -140.0))
		{
			State = ESkylineInnerCityHitSwingRespawnClosetDoorState::Open;
			USkylineInnerCityHitSwingRespawnClosetEventHandler::Trigger_OnRespawnDoorOpen(this);
		}
		if (State == ESkylineInnerCityHitSwingRespawnClosetDoorState::Closening && Math::IsNearlyEqual(AccDoor.Value, 0.0))
		{
			State = ESkylineInnerCityHitSwingRespawnClosetDoorState::Closed;
			USkylineInnerCityHitSwingRespawnClosetEventHandler::Trigger_OnRespawnDoorOpen(this);
		}

	}
};
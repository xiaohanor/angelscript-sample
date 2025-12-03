class AIslandOverseerSlidingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	USceneComponent OpenLocationComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxCollision;
	default BoxCollision.CollisionProfileName = CollisionProfile::BlockOnlyPlayerCharacter;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000;

	UPROPERTY(EditInstanceOnly)
	bool bStartOpen;

	FVector OpenLocation;
	FVector ClosedLocation;
	bool bOpen;
	float Duration = 1;
	FHazeAcceleratedVector AccLocation;
	float OpenTime;
	float CloseTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ClosedLocation = MeshComp.WorldLocation;
		OpenLocation = OpenLocationComp.WorldLocation;
		AccLocation.SnapTo(ClosedLocation);

		AccLocation.SnapTo(ClosedLocation);
		bOpen = bStartOpen;

		if(bStartOpen)
		{
			AccLocation.SnapTo(OpenLocation);
			MeshComp.WorldLocation = OpenLocation;
			BoxCollision.AddComponentCollisionBlocker(this);
		}
	}

	UFUNCTION()
	void Open()
	{
		if(bOpen)
			return;

		bOpen = true;
		UIslandOverseerSlidingDoorEventHandler::Trigger_OnOpenStart(this);
		OpenTime = Time::GameTimeSeconds;
		BoxCollision.AddComponentCollisionBlocker(this);
	}

	UFUNCTION()
	void Close()
	{
		if(!bOpen)
			return;

		bOpen = false;
		UIslandOverseerSlidingDoorEventHandler::Trigger_OnCloseStart(this);
		CloseTime = Time::GameTimeSeconds;
		BoxCollision.RemoveComponentCollisionBlocker(this);
	}

	UFUNCTION()
	void CloseInstant()
	{
		if(!bOpen)
			return;

		bOpen = false;
		CloseTime = Time::GameTimeSeconds;
		AccLocation.SnapTo(ClosedLocation);
		MeshComp.WorldLocation = AccLocation.Value;
		BoxCollision.RemoveComponentCollisionBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bOpen)
			AccLocation.AccelerateTo(ClosedLocation, Duration, DeltaSeconds);
		else 
			AccLocation.AccelerateTo(OpenLocation, Duration, DeltaSeconds);
		MeshComp.WorldLocation = AccLocation.Value;
		
		if(OpenTime > 0 && Time::GetGameTimeSince(OpenTime) > Duration)
		{
			UIslandOverseerSlidingDoorEventHandler::Trigger_OnOpenStop(this);
			OpenTime = 0;
		}

		if(CloseTime > 0 && Time::GetGameTimeSince(CloseTime) > Duration)
		{
			UIslandOverseerSlidingDoorEventHandler::Trigger_OnCloseStop(this);
			CloseTime = 0;
		}
	}
}
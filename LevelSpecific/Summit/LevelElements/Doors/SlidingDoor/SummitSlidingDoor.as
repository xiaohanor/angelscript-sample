UCLASS(Abstract)
class ASummitSlidingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent DoorEnd;
	default DoorEnd.CollisionProfileName = n"NoCollision";
	default DoorEnd.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	/* This is how long it will take for the door to open/close */
	UPROPERTY(EditAnywhere)
	float DoorOpenDuration = 0.5;

	/* How it feels when the door opens */
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve OpenInterpolation;
	default OpenInterpolation.AddDefaultKey(0.0, 0.0);
	default OpenInterpolation.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	TPerPlayer<bool> bPlayFrameRumble;

	FVector DoorOriginalRelativeLocation;
	bool bDoorIsOpen = false;
	bool bDoorIsMoving = false;
	float TimeOfChangeState = -100.0;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoorOriginalRelativeLocation = DoorMesh.RelativeLocation;
	}

	UFUNCTION()
	void OpenDoor()
	{
		bDoorIsOpen = true;
		bDoorIsMoving = true;
		TimeOfChangeState = Time::GetGameTimeSeconds();

		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000, Scale = 0.5);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000, Scale = 0.5);

		FVector OriginLocation = Root.WorldTransform.TransformPosition(DoorOriginalRelativeLocation);
		FVector EndLocation = DoorEnd.WorldLocation;

		float TotalDistance = OriginLocation.Distance(EndLocation);
		float CurrentDistance = DoorMesh.WorldLocation.Distance(EndLocation);

		float CurrentAlpha = 1.0 - (CurrentDistance / TotalDistance);
		TimeOfChangeState -= CurrentAlpha * DoorOpenDuration;

		USummitSlidingDoorEventHandler::Trigger_OnStartedOpening(this);
	}

	UFUNCTION()
	void CloseDoor()
	{
		bDoorIsOpen = false;
		bDoorIsMoving = true;
		TimeOfChangeState = Time::GetGameTimeSeconds();

		FVector OriginLocation = Root.WorldTransform.TransformPosition(DoorOriginalRelativeLocation);
		FVector EndLocation = DoorEnd.WorldLocation;

		float TotalDistance = OriginLocation.Distance(EndLocation);
		float CurrentDistance = DoorMesh.WorldLocation.Distance(EndLocation);

		float CurrentAlpha = (CurrentDistance / TotalDistance);
		TimeOfChangeState -= CurrentAlpha * DoorOpenDuration;

		USummitSlidingDoorEventHandler::Trigger_OnStartedClosing(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsDoorOpen()
	{
		return bDoorIsOpen;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bDoorIsMoving)
			return;
		
		FVector OriginLocation = Root.WorldTransform.TransformPosition(DoorOriginalRelativeLocation);
		FVector EndLocation = DoorEnd.WorldLocation;
		float Alpha = OpenInterpolation.GetFloatValue((Time::GetGameTimeSeconds() - TimeOfChangeState) / DoorOpenDuration);
		DoorMesh.WorldLocation = Math::Lerp(bDoorIsOpen ? OriginLocation : EndLocation, bDoorIsOpen ? EndLocation : OriginLocation, Alpha);
		if(Alpha >= 1.0)
		{
			if(bDoorIsOpen)
				USummitSlidingDoorEventHandler::Trigger_OnStoppedOpening(this);
			else
				USummitSlidingDoorEventHandler::Trigger_OnStoppedClosing(this);
			bDoorIsMoving = false;
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (bPlayFrameRumble[Player])
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = 0.5 + Math::Sin(Time::GameTimeSeconds * 10.0) * 0.5;
				FF.RightMotor = 0.5 + Math::Sin(-Time::GameTimeSeconds * 10.0) * 0.5;
				Player.SetFrameForceFeedback(FF, 0.75);
			}
		}
	}

	UFUNCTION()
	void PlayerSetRumble(bool bCanRumble, AHazePlayerCharacter Player)
	{
		bPlayFrameRumble[Player] = bCanRumble;
	}
}
event void FSkylineDoubleDoorSignature();
class ASkylineDoubleDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftDoor;

	UPROPERTY(DefaultComponent)
	USceneComponent RightDoor;

	UPROPERTY(DefaultComponent)
	UBoxComponent DoorCollision;
	default DoorCollision.SetCollisionProfileName(n"BlockAllDynamic");

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY()
	FSkylineDoubleDoorSignature OnDoorOpened;

	UPROPERTY()
	FSkylineDoubleDoorSignature OnDoorClosed;

	UPROPERTY(EditAnywhere)
	bool bStartOpen;

	UPROPERTY(EditAnywhere)
	float OpenDistance = 300.0;

	UPROPERTY(EditAnywhere)
	float OpenDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DoorAnimation;
	default DoorAnimation.Duration = 1.0;
	default DoorAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default DoorAnimation.Curve.AddDefaultKey(1.0, 1.0);

	bool bOpened;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (EditCondition = "!bStartOpen"))
	UHazeAudioEvent DoorOpenEvent;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (EditCondition = "!bStartOpen && DoorOpenEvent != nullptr"))
	FHazeAudioFireForgetEventParams EventParams;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	ASpotSound LinkedSpotSound;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		OnUpdate((bStartOpen ? 1.0 : 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoorAnimation.SetPlayRate(1.0 / OpenDuration);
		DoorAnimation.BindUpdate(this, n"OnUpdate");
		DoorAnimation.BindFinished(this, n"OnFinished");

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

		if(bStartOpen)
		{
			DoorAnimation.SetNewTime(DoorAnimation.Duration);
			OnUpdate(DoorAnimation.Value);
			DoorCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		OpenDoor();
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		CloseDoor();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		LeftDoor.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector::RightVector * OpenDistance, Alpha));
		RightDoor.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector::RightVector * -OpenDistance, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		bOpened = !DoorAnimation.IsReversed();
		
		if(bOpened)
		{
			OnDoorOpened.Broadcast();
			InterfaceComp.TriggerActivate();
		}
		else
		{
			OnDoorClosed.Broadcast();
			InterfaceComp.TriggerDeactivate();
		}
	}

	UFUNCTION()
	void OpenDoor()
	{
		DoorAnimation.Play();
		DoorCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		if(DoorOpenEvent != nullptr)
		{
			EventParams.AttachComponent = Root;
			AudioComponent::PostFireForget(DoorOpenEvent, EventParams);
		}

		if(LinkedSpotSound != nullptr)
		{
			EffectEvent_OnDoorOpen();
		}
	}

	UFUNCTION()
	void EffectEvent_OnDoorOpen()
	{
		USkylineDoubleDoorEventHandler::Trigger_OnDoorOpen(LinkedSpotSound);
	}

	UFUNCTION()
	void CloseDoor()
	{
		DoorAnimation.Reverse();
		DoorCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

}
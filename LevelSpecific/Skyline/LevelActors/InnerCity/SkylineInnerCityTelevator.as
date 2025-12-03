event void FSkylineInnerCityTelevatorSignature();

class ASkylineInnerCityTelevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ElevatorWeightRoot;

	UPROPERTY(DefaultComponent)
	UOneShotInteractionComponent ElevatorButtonInteractionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftDoorPivot;

	UPROPERTY(DefaultComponent)
	USceneComponent RightDoorPivot;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleTrigger;
	default CapsuleTrigger.bGenerateOverlapEvents = true;
	default CapsuleTrigger.bDisableUpdateOverlapsOnComponentMove = true;
	default CapsuleTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CapsuleTrigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditInstanceOnly)
	AStaticCameraActor Camera;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor DisplayCamera;

	UPROPERTY(DefaultComponent)
	UWidgetComponent WidgetComp;

	USkylineInnerCityTelevatorWidget Widget;
	USkylineInnerCityTelevatorWidget DestinationWidget;

	UPROPERTY(EditAnywhere)
	float DoorDistance = 130.0;

	UPROPERTY(EditAnywhere)
	int StartFloor = 150;

	UPROPERTY(EditAnywhere)
	int ElevatorFloor = 200;

	UPROPERTY()
	int ReceptionFloor = 200;

	UPROPERTY()
	int RoofFloor = 215;
	
	int CurrentFloor;
	int TargetFloor;
	FVector StartPosition;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DoorAnimation;
	default DoorAnimation.Duration = 2.0;
	default DoorAnimation.UseLinearCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike EnterTimeLike;
	default EnterTimeLike.Duration = 5.0;
	default EnterTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike GoToRoofTimeLike;
	default GoToRoofTimeLike.Duration = 5.0;
	default GoToRoofTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPoint;

	TPerPlayer<bool> IsInside;
	bool bHasArrived = false;

	UPROPERTY()
	FSkylineInnerCityTelevatorSignature OnClosed;

	UPROPERTY()
	FSkylineInnerCityTelevatorSignature OnTeleported;

	UPROPERTY()
	FSkylineInnerCityTelevatorSignature OnAtDestination;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<ASkylineInnerCityTelevator> DestinationTelevator;

	bool bIsDesinationSetup = false;
	bool bTelevatorActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapsuleTrigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		CapsuleTrigger.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");

		DoorAnimation.BindUpdate(this, n"HandleDoorAnimationUpdate");
		DoorAnimation.BindFinished(this, n"HandleDoorAnimationFinished");

		EnterTimeLike.BindUpdate(this, n"EnterTimeLikeUpdate");
		EnterTimeLike.BindFinished(this, n"EnterTimeLikeFinished");

		GoToRoofTimeLike.BindUpdate(this, n"GoToRoofTimeLikeUpdate");
		GoToRoofTimeLike.BindFinished(this, n"GoToRoofTimeLikeFinished");

		ElevatorButtonInteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleButtonPressed");

		StartPosition = ElevatorRoot.RelativeLocation;

		if (!DestinationTelevator.IsNull())
		{
			InitializeFloorNumber();
			ElevatorRoot.SetRelativeLocation(FVector::UpVector * (StartFloor - ElevatorFloor) * 100.0);
			ElevatorWeightRoot.SetRelativeLocation(FVector::UpVector * (StartFloor - ElevatorFloor) * -100.0);
		}
		else
		{
			bIsDesinationSetup = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsDesinationSetup && DestinationTelevator.Get() != nullptr)
		{
			DestinationTelevator.Get().ElevatorRoot.SetHiddenInGame(true, true);
			DestinationTelevator.Get().StartFloor = StartFloor;
			DestinationTelevator.Get().InitializeFloorNumber();
			bIsDesinationSetup = true;
		}
	}

	UFUNCTION()
	void InitializeFloorNumber()
	{
		FText DisplayText = FText::FromString(f"{StartFloor}");
		Widget = Cast<USkylineInnerCityTelevatorWidget>(WidgetComp.Widget);
		Widget.SetText(DisplayText);
	}

	UFUNCTION()
	private void HandleButtonPressed(UInteractionComponent InteractionComponent,
	                                 AHazePlayerCharacter Player)
	{
		if(DestinationTelevator != nullptr)
		{
			DestinationWidget = Cast<USkylineInnerCityTelevatorWidget>(DestinationTelevator.Get().WidgetComp.Widget);
			DestinationWidget.SetText(FText::FromString("R"));
		}

		ElevatorButtonInteractionComp.Disable(this);
		TargetFloor = ReceptionFloor;
		BP_ElevatorUp();
		USkylineInnerCityTelevatorEventHandler::Trigger_OnButtonClicked(this);

		Timer::SetTimer(this, n"DelayedElevatorEnter", 1.0);
	}

	UFUNCTION()
	private void DelayedElevatorEnter()
	{
		EnterTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		IsInside[Player] = true;

	
		Player.BlockCapabilities(n"GameplayAction",this);
		Player.ActivateCamera(Camera, 1.5, this);

		if (IsBothPlayersInside())
			CloseDoors();
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		IsInside[Player] = false;

		Player.DeactivateCamera(Camera);
		Player.UnblockCapabilities(n"GameplayAction", this);
		OpenDoors();
	}

	UFUNCTION()
	private void HandleDoorAnimationUpdate(float CurrentValue)
	{
		LeftDoorPivot.RelativeRotation = FRotator(0.0, -35 * CurrentValue, 0.0);
		RightDoorPivot.RelativeRotation = FRotator(0.0, 35 * CurrentValue, 0.0);
	}

	UFUNCTION()
	private void HandleDoorAnimationFinished()
	{
		if (DoorAnimation.IsReversed() && IsBothPlayersInside())
		{
			if (!bTelevatorActivated)
				NetActivateTelevator();
		}
	}

	UFUNCTION()
	private void EnterTimeLikeUpdate(float CurrentValue)
	{
		float CurrentFloorFloat = Math::Lerp(float(StartFloor), float(TargetFloor) + KINDA_SMALL_NUMBER, CurrentValue);
		CurrentFloor = Math::FloorToInt(CurrentFloorFloat);
		FText DisplayText;

		if (CurrentFloor == ReceptionFloor)
		{
			Widget.BP_OnFloorReached(false);
			DisplayText = FText::FromString(f"{CurrentFloor}");
			Widget.SetText(DisplayText);

			if(DestinationWidget != nullptr)
				DestinationWidget.SetText(FText::FromString("R"));
		}
		else if (CurrentFloor == RoofFloor)
		{
			DisplayText = FText::FromString(f"{RoofFloor}");
			Widget.SetText(DisplayText);
			
			if(DestinationWidget != nullptr)
				DestinationWidget.SetText(DisplayText);
		}
		else
		{
			DisplayText = FText::FromString(f"{CurrentFloor}");
			Widget.SetText(DisplayText);

			if(DestinationWidget != nullptr)
				DestinationWidget.SetText(DisplayText);
		}

		
		ElevatorRoot.SetRelativeLocation(FVector::UpVector * (CurrentFloorFloat - ElevatorFloor) * 100.0);
		ElevatorWeightRoot.SetRelativeLocation(FVector::UpVector * (CurrentFloorFloat - ElevatorFloor) * -100.0);

		USkylineInnerCityTelevatorEventHandler::Trigger_OnElevatorStartMoving(this);
	}

	UFUNCTION()
	private void EnterTimeLikeFinished()
	{
		OpenDoors();
		StartFloor = CurrentFloor;
		BP_ElevatorLight();
	}
	
	UFUNCTION()
	private void GoToRoofTimeLikeUpdate(float CurrentValue)
	{
		float CurrentFloorFloat = Math::Lerp(float(StartFloor), float(TargetFloor) + KINDA_SMALL_NUMBER, CurrentValue);
		CurrentFloor = Math::FloorToInt(CurrentFloorFloat);
		FText DisplayText;

		if (CurrentFloor == ReceptionFloor)
		{
		}
		else if (CurrentFloor == RoofFloor)
		{
		}
		else
		{
			DisplayText = FText::FromString(f"{CurrentFloor}");
			Widget.SetText(DisplayText);
		}

		ElevatorRoot.SetRelativeLocation(FVector::UpVector * (CurrentFloorFloat - ElevatorFloor) * 20.0);
		ElevatorWeightRoot.SetRelativeLocation(FVector::UpVector * (CurrentFloorFloat - ElevatorFloor) * -20.0);

		USkylineInnerCityTelevatorEventHandler::Trigger_OnElevatorStartMovingToRoof(this);
	}

	UFUNCTION()
	private void GoToRoofTimeLikeFinished()
	{
		TeleportPlayers();
	}

	UFUNCTION()
	void CloseDoors()
	{
		DoorAnimation.Reverse();
		USkylineInnerCityTelevatorEventHandler::Trigger_OnDoorClose(this);
	}

	UFUNCTION()
	void OpenDoors()
	{
		DoorAnimation.Play();
		USkylineInnerCityTelevatorEventHandler::Trigger_OnDoorOpen(this);
		USkylineInnerCityTelevatorEventHandler::Trigger_OnElevatorStopMoving(this);
	}

	UFUNCTION(NetFunction)
	private void NetActivateTelevator()
	{	
		if (bTelevatorActivated)
			return;

		bTelevatorActivated = true;
		Widget.BP_OnStartMoving();
		OnClosed.Broadcast();

		Camera::BlendToFullScreenUsingProjectionOffset(Game::Mio, this, 1.5, 1.5);
		Game::Mio.BlockCapabilities(n"MovementInput",this);
		Game::Zoe.BlockCapabilities(n"MovementInput",this);

		Timer::SetTimer(this, n"GoToRoof", 1.5);
	}

	UFUNCTION()
	private void GoToRoof()
	{
		DestinationTelevator.Get().ElevatorRoot.SetHiddenInGame(false, true);
		DestinationWidget.SetText(FText::FromString(f"{RoofFloor}"));
		TargetFloor = RoofFloor;
		GoToRoofTimeLike.PlayFromStart();
		

		for (auto Player : Game::Players)
		{
			Player.ActivateCamera(DisplayCamera, 4.0, this, EHazeCameraPriority::Medium);
			ElevatorButtonInteractionComp.Disable(this);
			Player.BlockCapabilities(n"Dash", this);
			Player.BlockCapabilities(n"Jump", this);
		}
	}

	bool IsBothPlayersInside()
	{
		for (auto Player : Game::Players)
		{
			if (!IsInside[Player])
				return false;
		}

		return true;
	}

	UFUNCTION()
	void TeleportPlayers()
	{
		if (!DestinationTelevator.IsValid())
			return;

		DestinationTelevator.Get().SetAtDestination();
		DestinationWidget.SetText(FText::FromString(f"{RoofFloor}"));
		DestinationWidget.BP_OnFloorReached(true);

		for (auto Player : Game::Players)
		{
			FTransform RelativeTransform = Player.ActorTransform.GetRelativeTransform(ActorTransform);
			FTransform DestinationTransform = RelativeTransform * DestinationTelevator.Get().ActorTransform;

			// Transform actor velocity
			FVector RelativeVelocity = ActorTransform.InverseTransformVectorNoScale(Player.ActorVelocity);
			Player.TeleportActor(DestinationTransform.Location, DestinationTransform.Rotator(), this, false);
			Player.ActorVelocity = DestinationTelevator.Get().ActorTransform.TransformVectorNoScale(RelativeVelocity);
		
			Player.TeleportToRespawnPoint(DestinationTelevator.Get().RespawnPoint, this);
			Player.DeactivateCameraByInstigator(this, 0.0);
			Player.UnblockCapabilities(n"Dash", this);
			Player.UnblockCapabilities(n"Jump", this);
			//Player.UnblockCapabilities(n"GameplayAction",this);
			Player.UnblockCapabilities(n"MovementInput",this);
		}

		OnTeleported.Broadcast();
	}

	void SetAtDestination()
	{
		for (auto Player : Game::Players)
			Player.ActivateCamera(DisplayCamera, 0.0, this);

		BP_ElevatorLight();

		CapsuleTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ElevatorButtonInteractionComp.Disable(this);
		OpenDoors();

		Timer::SetTimer(this, n"OpenAtDestination", 1.0);
	}

	UFUNCTION()
	void OpenAtDestination()
	{
		for (auto Player : Game::Players)
			Player.DeactivateCameraByInstigator(this, 3.0);
	
		OnAtDestination.Broadcast();
		USkylineInnerCityTelevatorEventHandler::Trigger_OnDoorOpenAtDestination(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ElevatorLight(){}

	UFUNCTION(BlueprintEvent)
	void BP_ElevatorUp(){}
};
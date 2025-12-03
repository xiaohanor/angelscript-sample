class AMaxSecurityPressurePlate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent OnButtonTrigger;

	UPROPERTY(DefaultComponent)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityPressurePlate PlateSibling;

	UPROPERTY(EditAnywhere)
	float ButtonPressedOffset = 20.0;

	UPROPERTY(EditAnywhere)
	float ButtonPressedSpeed = 8.0;

	UPROPERTY(EditInstanceOnly)
	bool bIsTheParent;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserHellDoor DoorToOpen;

	UPROPERTY(BlueprintReadOnly)
	bool bMioOn;
	UPROPERTY(BlueprintReadOnly)
	bool bZoeOn;
	UPROPERTY(BlueprintReadOnly)
	bool bIsPressed;
	UPROPERTY(BlueprintReadOnly)
	bool bIsCompleted;
	bool bIsMoving = false;

	bool bIsButtonPressable = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnButtonTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnButtonTriggerOverlapped");
		OnButtonTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnButtonTriggerOverlapEnd");
	}

	UFUNCTION()
	private void OnButtonTriggerOverlapped(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                       bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(!bIsButtonPressable)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = true;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = true;

		if (bIsPressed)
			return;

		bIsPressed = true;
		BP_OnOverlap();
		Activated();

		bIsMoving = true;
	}

	UFUNCTION()
	private void OnButtonTriggerOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if(!bIsButtonPressable)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if (bIsCompleted)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = false;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = false;

		if(bMioOn == false && bZoeOn == false)
		{
			bIsPressed = false;
			FLaserHellButtonEventData Data;
			Data.PressurePlate = this;
			UMaxSecurityLaserHellEventHandler::Trigger_ButtonReleased(this, Data);
		}

		if (!bIsPressed)
			BP_OnEndOverlap();
		
		bIsMoving = true;
	}

	UFUNCTION()
	void Activated()
	{		
		if (bIsCompleted)
			return;

		if (PlateSibling == nullptr)
			return;
		
		if (!bIsTheParent)
		{
			PlateSibling.Activated();
			return;
		}

		FLaserHellButtonEventData Data;
		Data.PressurePlate = this;
		UMaxSecurityLaserHellEventHandler::Trigger_ButtonPressed(this, Data);
			

		if(!HasControl())
			return;

		if (bIsPressed == true && PlateSibling.bIsPressed == true)
		{
			CrumbActivated();
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbActivated()
	{
		bIsCompleted = true;
		PlateSibling.bIsCompleted = true;
		BP_OnActivated();
		DoorToOpen.OpenDoor();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbTeleportPlayerToButton(AHazePlayerCharacter PlayerToTeleport, AMaxSecurityPressurePlate Plate)
	{
		PlayerToTeleport.SmoothTeleportActor(Plate.ActorLocation, PlayerToTeleport.ActorRotation, this, 0.2);
	}

	void ResetPressurePlate()
	{
		BP_OnReset();
		bIsCompleted = false;
		bIsMoving = true;
		bIsPressed = false;
		bMioOn = false;
		bZoeOn = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsMoving)
		{
			FVector TargetLocation = GetButtonTargetLocation();
			MoveRoot.RelativeLocation = Math::VInterpTo(MoveRoot.RelativeLocation, TargetLocation, DeltaSeconds, ButtonPressedSpeed);

			FVector DeltaToTarget = TargetLocation - MoveRoot.RelativeLocation;
			if(DeltaToTarget.IsNearlyZero(1.0))
			{
				MoveRoot.RelativeLocation = TargetLocation;
				bIsMoving = false;
			}
		}

	}

	UFUNCTION()
	void MakeButtonsPressable(bool bPressable)
	{
		bIsButtonPressable = bPressable;
	}

	private FVector GetButtonTargetLocation() const
	{
		if(bIsPressed)
			return FVector::DownVector * ButtonPressedOffset;
		else
			return FVector::ZeroVector;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnOverlap(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnEndOverlap(){}
	
	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReset(){}
};
event void FMaxSecurityLaserHellElevatorEvent();

UCLASS(Abstract)
class AMaxSecurityLaserHellElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UPlayerInheritMovementComponent InheritMoveComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveElevatorTimeLike;

	UPROPERTY()
	FMaxSecurityPillarElevatorEvent OnStartMovingUp;

	private TArray<AMaxSecurityPillarElevatorButton> Buttons;
	private const float MaxOffset = 2000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveElevatorTimeLike.BindUpdate(this, n"UpdateMoveElevator");
		MoveElevatorTimeLike.BindFinished(this, n"FinishedMoveElevator");

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for(auto AttachedActor : AttachedActors)
		{
			auto Button = Cast<AMaxSecurityPillarElevatorButton>(AttachedActor);
			if(Button == nullptr)
				continue;

			Buttons.Add(Button);
		}

		Buttons.Remove(nullptr);

		for(auto Button : Buttons)
		{
			Button.OnActivated.AddUFunction(this, n"OnButtonActivated");
		}
	}

	UFUNCTION()
	private void UpdateMoveElevator(float CurValue)
	{
		float Offset = Math::Lerp(0.0, MaxOffset, CurValue);
		ElevatorRoot.SetRelativeLocation(FVector(0.0, 0.0, Offset));
	}

	UFUNCTION()
	private void FinishedMoveElevator()
	{
		ElevatorActivated(false);

		if(!MoveElevatorTimeLike.IsReversed() && HasControl())
		{
			for(auto Button : Buttons)
			{
				if(Button == nullptr)
					continue;
				
				Button.CrumbReleaseButton(Game::Mio);
				Button.CrumbReleaseButton(Game::Zoe);
			}
		}
	}

	UFUNCTION()
	private void OnButtonActivated(int ButtonIndex)
	{
		if(!HasControl())
			return;

		if(AreAllButtonsActivated())
			StartMoving(true);
	}

	bool AreAllButtonsActivated() const
	{
		for(auto Button : Buttons)
		{
			if(!Button.IsButtonPressed())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintEvent)
	void StartMoving(bool bGoingUp)
	{
		if(!HasControl())
			return;

		NetStartMoving(bGoingUp);
	}

	UFUNCTION(NetFunction)
	private void NetStartMoving(bool bGoingUp)
	{
		if(bGoingUp)
		{
			MoveElevatorTimeLike.PlayFromStart();
			OnStartMovingUp.Broadcast();

			FLaserHellElevatorEventData Data;
			Data.Elevator = this;
			UMaxSecurityLaserHellEventHandler::Trigger_ElevatorGoingUp(this, Data);
		}
		else
		{
			MoveElevatorTimeLike.ReverseFromEnd();

			FLaserHellElevatorEventData Data;
			Data.Elevator = this;
			UMaxSecurityLaserHellEventHandler::Trigger_ElevatorGoingDown(this, Data);
		}

		ElevatorActivated(true);
	}

	UFUNCTION()
	void ElevatorActivated(bool bActivated)
	{
		for(auto Button : Buttons)
		{
			if(Button == nullptr)
				continue;
			
			Button.OnElevatorActivated(bActivated);
		}
	}

	UFUNCTION()
	void MoveElevatorDown()
	{
		StartMoving(false);	
	}
}
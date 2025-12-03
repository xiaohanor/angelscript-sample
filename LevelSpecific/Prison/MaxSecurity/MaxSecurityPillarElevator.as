event void FMaxSecurityPillarElevatorEvent();

UCLASS(Abstract)
class AMaxSecurityPillarElevator : AHazeActor
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
	FMaxSecurityPillarElevatorEvent OnReachedTop;

	UPROPERTY()
	FMaxSecurityPillarElevatorEvent OnStartMoving;

	private TArray<AMaxSecurityPillarElevatorButton> Buttons;
	private const float MaxOffset = 16695.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveElevatorTimeLike.BindUpdate(this, n"UpdateMoveElevator");
		MoveElevatorTimeLike.BindFinished(this, n"FinishMoveElevator");

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
	private void FinishMoveElevator()
	{
		OnReachedTop.Broadcast();

		UMaxSecurityPillarElevatorEffectEventHandler::Trigger_ReachedTop(this);
	}

	UFUNCTION()
	private void OnButtonActivated(int ButtonIndex)
	{
		if(!HasControl())
			return;

		BP_OnButtonActivated(ButtonIndex);

		if(AreAllButtonsActivated())
			StartMoving();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnButtonActivated(int ButtonIndex)
	{}

	bool AreAllButtonsActivated() const
	{
		for(auto Button : Buttons)
		{
			if(!Button.IsButtonPressed())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintEvent, meta = (NoSuperCall))
	void StartMoving()
	{
		if(!HasControl())
			return;

		NetStartMoving();
	}

	UFUNCTION(NetFunction)
	private void NetStartMoving()
	{
		MoveElevatorTimeLike.PlayFromStart();

		UMaxSecurityPillarElevatorEffectEventHandler::Trigger_StartMoving(this);

		OnStartMoving.Broadcast();

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
	void ResetElevator()
	{
		ElevatorRoot.SetRelativeLocation(FVector::ZeroVector);
		Timer::SetTimer(this, n"Wiggle", 0.15);
		
		// This prevents a bug that caused the actor to lose collision??
		AddActorCollisionBlock(this);
		RemoveActorCollisionBlock(this);
		
		ElevatorActivated(false);

		if(HasControl())
		{
			for(auto Button : Buttons)
			{
				if(Button == nullptr)
					continue;
				
				Button.CrumbReleaseButton(Game::Mio, true);
				Button.CrumbReleaseButton(Game::Zoe, true);
			}
		}
	}

	UFUNCTION()
	private void Wiggle()
	{
		ActorLocation = ActorLocation + FVector(0, 0, 0.01);
	}
}
enum EPrisonDoubleDoorNetwork
{
	Local,
	Host,
	Mio,
	Zoe,
};

UCLASS(Abstract)
class APrisonDoubleDoor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorFrame;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftDoorRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightDoorRoot;

	UPROPERTY(DefaultComponent, Attach = LeftDoorRoot)
	UStaticMeshComponent LeftDoorMesh;

	UPROPERTY(DefaultComponent, Attach = RightDoorRoot)
	UStaticMeshComponent RightDoorMesh;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float MoveOutAmount = 310;

	/** How long it takes to extend the actor forward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	float ForwardMovementDuration = 2.25;

	/** How long it takes to retract the actor backward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	float BackwardMovementDuration = 2.75;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Network")
	EPrisonDoubleDoorNetwork NetworkMode = EPrisonDoubleDoorNetwork::Local;

	private bool bMoving = false;
	private float StartCrumbTime = 0.0;
	private bool bStartForward = true;
	private bool bActivatedForward = false;
	private bool bActivatedBackward = false;
	private bool bReachedForward = false;
	private bool bReachedBackward = false;

	UFUNCTION()
	void Open()
	{
		float NewStartTime = Time::GetActorControlCrumbTrailTime(this) - (InverseMovementCurve(GetCurrentAlpha()) * ForwardMovementDuration);
		if (NetworkMode == EPrisonDoubleDoorNetwork::Local)
			InternalSetMovement(true, NewStartTime);
		else if (HasControl())
			CrumbSetMovement(true, NewStartTime);
	}

	UFUNCTION()
	void Close()
	{
		float NewStartTime = Time::GetActorControlCrumbTrailTime(this) - (InverseMovementCurve(1.0 - GetCurrentAlpha()) * BackwardMovementDuration);
		if (NetworkMode == EPrisonDoubleDoorNetwork::Local)
			InternalSetMovement(false, NewStartTime);
		else if (HasControl())
			CrumbSetMovement(false, NewStartTime);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		switch (NetworkMode)
		{
			case EPrisonDoubleDoorNetwork::Mio:
				SetActorControlSide(Game::Mio);
				break;

			case EPrisonDoubleDoorNetwork::Zoe:
				SetActorControlSide(Game::Zoe);
				break;

			default:
				break;
		}

		StartCrumbTime = Time::GetActorControlCrumbTrailTime(this);

		bMoving = false;
		bStartForward = false;
		StartCrumbTime = -BackwardMovementDuration;
	}

	private float EvaluateMovementCurve(float Alpha) const
	{
		return 1.0 - Math::Pow(1.0 - Alpha, 2.5);
	}

	private float InverseMovementCurve(float Alpha) const
	{
		return 1.0 - Math::Pow(1.0 - Alpha, 1.0 / 2.5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bMoving)
			UpdatePosition();
		else
			SetActorTickEnabled(false);
	}

	protected float GetCurrentAlpha() const
	{
		return GetAlphaAtTime(GetCurrentTime());
	}

	private float GetCurrentTime() const
	{
		return Time::GetActorControlCrumbTrailTime(this) - StartCrumbTime;
	}

	private float GetAlphaAtTime(float InTime) const
	{
		float Alpha = 0.0;
		if (bStartForward)
		{
			if (InTime < ForwardMovementDuration)
				Alpha = EvaluateMovementCurve(InTime / Math::Max(ForwardMovementDuration, 0.001));
			else
				Alpha = 1.0;
		}
		else
		{
			if (InTime < BackwardMovementDuration)
				Alpha = 1.0 - EvaluateMovementCurve(InTime / Math::Max(BackwardMovementDuration, 0.001));
			else
				Alpha = 0.0;
		}

		return Alpha;
	}

	protected bool IsMovingBackward() const
	{
		return !bStartForward;
	}

	private void UpdatePosition()
	{
		const float Alpha = GetCurrentAlpha();

		float MoveDistance = Math::Lerp(0, MoveOutAmount, Alpha);

		LeftDoorRoot.SetRelativeLocation(FVector(0, MoveDistance, 0));
		RightDoorRoot.SetRelativeLocation(FVector(0, -MoveDistance, 0));

		if (bMoving)
		{
			// Update what direction we're moving in
			bool bMovingBackward = IsMovingBackward();
			if (bMovingBackward)
			{
				bActivatedForward = false;
				if (!bActivatedBackward)
				{
					bActivatedBackward = true;
					OnBackwardsActivated();
				}
			}
			else
			{
				bActivatedBackward = false;
				if (!bActivatedForward)
				{
					bActivatedForward = true;
					OnForwardActivated();
				}
			}

			// Update if we reached a destination
			if(!bMovingBackward && Alpha > 1 - KINDA_SMALL_NUMBER)
			{
				if(!bReachedForward)
					OnForwardReached();

				bReachedForward = true;
			}
			else if(bMovingBackward && Alpha < KINDA_SMALL_NUMBER)
			{
				if(!bReachedBackward)
					OnBackwardsReached();

				bReachedBackward = true;
			}
			else
			{
				bReachedForward = false;
				bReachedBackward = false;
			}
		}

		// Stop moving after we're done
		float Time = GetCurrentTime();
		if (bStartForward)
		{
			if (Time > ForwardMovementDuration)
				bMoving = false;
		}
		else
		{
			if (Time > BackwardMovementDuration)
				bMoving = false;
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetMovement(bool bForward, float NewStartTime)
	{
		InternalSetMovement(bForward, NewStartTime);
	}

	private void InternalSetMovement(bool bForward, float NewStartTime)
	{
		StartCrumbTime = NewStartTime;
		bStartForward = bForward;
		bMoving = true;
		SetActorTickEnabled(true);
	}

	bool IsMoving() const
	{
		return bMoving;
	}

	UFUNCTION(BlueprintEvent)
	void OnForwardActivated()
	{
		UPrisonDoubleDoorEventHandler::Trigger_StartOpen(this);
	}

	UFUNCTION(BlueprintEvent)
	void OnBackwardsActivated()
	{
		UPrisonDoubleDoorEventHandler::Trigger_StartClose(this);
	}

	UFUNCTION(BlueprintEvent)
	void OnForwardReached()
	{
		UPrisonDoubleDoorEventHandler::Trigger_Opened(this);
	}
	UFUNCTION(BlueprintEvent)
	void OnBackwardsReached()
	{
		UPrisonDoubleDoorEventHandler::Trigger_Closed(this);
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void DevOpen()
	{
		Open();
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void DevClose()
	{
		Close();
	}
};
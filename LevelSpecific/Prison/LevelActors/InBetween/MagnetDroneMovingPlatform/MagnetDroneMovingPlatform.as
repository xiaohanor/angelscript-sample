class AMagnetDroneMovingPlatform : AKineticMovingActor
{
	private bool bWasMoving;
	private bool bWasMovingBackwards;
	private float Speed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnReachedForward.AddUFunction(this, n"OnReachedForward");
		OnReachedBackward.AddUFunction(this, n"OnReachedBackward");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector PreviousLocation = ActorLocation;

		Super::Tick(DeltaSeconds);

		const bool bIsMoving = IsActive();
		const bool bIsMovingBackwards = IsMovingBackward();

		if(bIsMoving && bWasMoving)
		{
			if(bIsMovingBackwards != bWasMovingBackwards)
				UMagnetDroneMovingPlatformEventHandler::Trigger_ChangeDirection(this);
		}
		else if(bIsMoving && !bWasMoving)
		{
			UMagnetDroneMovingPlatformEventHandler::Trigger_StartMoving(this);
		}
		else if(!bIsMoving && bWasMoving)
		{
			UMagnetDroneMovingPlatformEventHandler::Trigger_StopMoving(this);
		}

		bWasMoving = bIsMoving;
		bWasMovingBackwards = bIsMovingBackwards;
		Speed = (ActorLocation - PreviousLocation).Size() / DeltaSeconds;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnReachedForward()
	{
		UMagnetDroneMovingPlatformEventHandler::Trigger_ReachedEnd(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnReachedBackward()
	{
		UMagnetDroneMovingPlatformEventHandler::Trigger_ReachedStart(this);
	}

	UFUNCTION(BlueprintPure)
	float GetSpeedNormalized()
	{
		return Speed;
	}

	UFUNCTION(BlueprintPure)
	int GetDirection()
	{
		if(!IsActive())
			return 0;

		if(IsMovingBackward())
			return -1;
		else if(IsMovingForward())
			return 1;
		else
			return 0;
	}
};
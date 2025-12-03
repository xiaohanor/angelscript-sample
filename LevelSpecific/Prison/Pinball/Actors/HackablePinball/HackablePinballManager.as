event void FOnFlipPinballPaddleStart(EHackablePinballInputSide Side, float Intensity);
event void FOnFlipPinballPaddleTick(EHackablePinballInputSide Side);
event void FOnFlipPinballPaddleEnd(EHackablePinballInputSide Side);
event void FOnPinballPlungerEvent();

class UHackablePinballManager : UActorComponent
{
	access Events = protected, UHackablePinballResponseComponent;

	UPROPERTY()
	access:Events
	FOnFlipPinballPaddleStart OnFlipPinballPaddleStart;

	UPROPERTY()
	access:Events
	FOnFlipPinballPaddleTick OnFlipPinballPaddleTick;

	UPROPERTY()
	access:Events
	FOnFlipPinballPaddleEnd OnFlipPinballPaddleEnd;

	UPROPERTY()
	FOnPinballPlungerEvent OnPinballPlungerPulledBack;

	UPROPERTY()
	FOnPinballPlungerEvent OnPinballPlungerReleased;

	private bool bIsHoldingLeft;
	private bool bIsHoldingRight;

	TArray<UPinballBallComponent> Balls;
	TArray<UPinballTriggerComponent> Triggers;

	bool bGravityFollowsCameraDown = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// The level BP was checked out, don't judge me...
		for(auto Player : Game::Players)
		{
			UDroneMovementSettings::SetUnstableOnEdges(Player, false, this);
		}
	}

	void StartHolding(bool bLeft, float Intensity)
	{
		if(bLeft)
		{
			if(bIsHoldingLeft)
				return;

			bIsHoldingLeft = true;

			OnFlipPinballPaddleStart.Broadcast(EHackablePinballInputSide::Left, Intensity);

			if(!bIsHoldingRight)
				OnFlipPinballPaddleStart.Broadcast(EHackablePinballInputSide::Any, Intensity);
			else
				OnFlipPinballPaddleStart.Broadcast(EHackablePinballInputSide::Both, Intensity);
		}
		else
		{
			if(bIsHoldingRight)
				return;

			bIsHoldingRight = true;

			OnFlipPinballPaddleStart.Broadcast(EHackablePinballInputSide::Right, Intensity);

			if(!bIsHoldingLeft)
				OnFlipPinballPaddleStart.Broadcast(EHackablePinballInputSide::Any, Intensity);
			else
				OnFlipPinballPaddleStart.Broadcast(EHackablePinballInputSide::Both, Intensity);
		}
	}

	void StopHolding(bool bLeft)
	{
		if(bLeft)
		{
			if(!bIsHoldingLeft)
				return;

			bIsHoldingLeft = false;

			OnFlipPinballPaddleEnd.Broadcast(EHackablePinballInputSide::Left);

			if(!bIsHoldingRight)
				OnFlipPinballPaddleEnd.Broadcast(EHackablePinballInputSide::Any);
			else
				OnFlipPinballPaddleEnd.Broadcast(EHackablePinballInputSide::Both);
		}
		else
		{
			if(!bIsHoldingRight)
				return;

			bIsHoldingRight = false;

			OnFlipPinballPaddleEnd.Broadcast(EHackablePinballInputSide::Right);

			if(!bIsHoldingLeft)
				OnFlipPinballPaddleEnd.Broadcast(EHackablePinballInputSide::Any);
			else
				OnFlipPinballPaddleEnd.Broadcast(EHackablePinballInputSide::Both);
		}
	}

	void StartPlungerPullBack()
	{
		OnPinballPlungerPulledBack.Broadcast();
	}

	void StopPlungerPullBack()
	{
		OnPinballPlungerReleased.Broadcast();
	}
}
enum EHackablePinballInputSide
{
	/*
	Only trigger when the left input is pressed.
	*/
	Left,

	/*
	Only trigger when the right input is pressed.
	*/
	Right,

	/*
	Trigger if any of the two inputs are pressed.
	Will only register on the first input that starts, and the last input that ends.
	The Input value will be the largest of the two inputs.
	*/
	Any,

	/*
	Trigger if both of the inputs are pressed at the same time.
	Will only register on the second input that starts, and on the fist input that ends.
	The Input value will be the largest of the two inputs.
	*/
	Both
}

event void FOnPinballInputStart(float Intensity);
event void FOnPinballInputTick();
event void FOnPinballInputEnd();

class UHackablePinballResponseComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	EHackablePinballInputSide InputSide;

	UPROPERTY()
	FOnPinballInputStart OnPinballInputStart;

	UPROPERTY()
	FOnPinballInputTick OnPinballInputTick;

	UPROPERTY()
	FOnPinballInputEnd OnPinballInputEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UHackablePinballManager Manager = Pinball::GetManager();

		Manager.OnFlipPinballPaddleStart.AddUFunction(this, n"FlipPinballPaddleStart");
		Manager.OnFlipPinballPaddleTick.AddUFunction(this, n"FlipPinballPaddleTick");
		Manager.OnFlipPinballPaddleEnd.AddUFunction(this, n"FlipPinballPaddleEnd");
	}

	UFUNCTION()
	private void FlipPinballPaddleStart(EHackablePinballInputSide Side, float Intensity)
	{
		if(Side == InputSide)
			OnPinballInputStart.Broadcast(Intensity);
	}

	UFUNCTION()
	private void FlipPinballPaddleTick(EHackablePinballInputSide Side)
	{
		if(Side == InputSide)
			OnPinballInputTick.Broadcast();
	}

	UFUNCTION()
	private void FlipPinballPaddleEnd(EHackablePinballInputSide Side)
	{
		if(Side == InputSide)
			OnPinballInputEnd.Broadcast();
	}
}
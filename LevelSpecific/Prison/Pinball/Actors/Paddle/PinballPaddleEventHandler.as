struct FPinballPaddleEventParams
{
	UPROPERTY()
	float PositionAlpha = 0.0;

	/**
	 * How hard was the trigger pressed? (Approximately)
	 * Range is 0 -> 1
	 */
	UPROPERTY()
	float Intensity = 0.0;
}

struct FPinballPaddleLaunchEventParams
{
	UPROPERTY()
	float Intensity = 0.0;

	/**
	 * How hard was the trigger pressed? (Approximately)
	 * Range is 0 -> 1
	 */
	UPROPERTY()
	float InputIntensity = 0.0;
}

UCLASS(Abstract)
class UPinballPaddleEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballPaddle Paddle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Paddle = Cast<APinballPaddle>(Owner);
	}

	UFUNCTION(BlueprintEvent)
	void PaddleUp(FPinballPaddleEventParams Params) {};

	UFUNCTION(BlueprintEvent)
	void PaddleDown(FPinballPaddleEventParams Params) {};

	UFUNCTION(BlueprintEvent)
	void PaddleLaunch(FPinballPaddleLaunchEventParams Params) {};
};
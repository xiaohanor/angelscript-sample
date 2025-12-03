struct FPinballBouncePadOnHitByBallEventData
{
	UPinballBallComponent BallComp;
	bool bIsProxy;
};

UCLASS(Abstract)
class UPinballBouncePadEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	APinballBouncePad BouncePad;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BouncePad = Cast<APinballBouncePad>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByBall(FPinballBouncePadOnHitByBallEventData EventData) {}
};
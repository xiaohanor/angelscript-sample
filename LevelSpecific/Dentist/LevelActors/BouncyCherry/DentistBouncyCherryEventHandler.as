struct FDentistBouncyCherryOnBouncePlayerEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
};

struct FDentistBouncyCherryOnBounceLaunchedBallEventData
{
	UPROPERTY()
	ADentistLaunchedBall LaunchedBall;
};

UCLASS(Abstract)
class UDentistBouncyCherryEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistBouncyCherry BouncyCherry;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BouncyCherry = Cast<ADentistBouncyCherry>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBouncePlayer(FDentistBouncyCherryOnBouncePlayerEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounceLaunchedBall(FDentistBouncyCherryOnBounceLaunchedBallEventData EventData) {}
};
struct FDentistBirthdayCandleOnLightEventData
{
	UPROPERTY()
	int LitCandles;
};

struct FDentistBirthdayCandleOnUpOutEventData
{
	UPROPERTY()
	int LitCandles;
};

UCLASS(Abstract)
class UDentistBirthdayCandleEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistBirthdayCandle BirthdayCandle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BirthdayCandle = Cast<ADentistBirthdayCandle>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLight(FDentistBirthdayCandleOnLightEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPutOut(FDentistBirthdayCandleOnUpOutEventData EventData) {}
};
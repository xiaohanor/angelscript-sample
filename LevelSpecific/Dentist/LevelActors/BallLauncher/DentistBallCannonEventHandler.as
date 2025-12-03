struct FDentistBallCannonOnShootEventData
{
	UPROPERTY()
	FVector Location;
};

UCLASS(Abstract)
class UDentistBallCannonEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistBallCannon BallCannon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallCannon = Cast<ADentistBallCannon>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot(FDentistBallCannonOnShootEventData EventData) {}
};
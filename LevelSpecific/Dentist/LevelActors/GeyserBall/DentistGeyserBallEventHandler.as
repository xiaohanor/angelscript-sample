struct FDentistGeyserBallJumpOutOfWaterEventData
{
	UPROPERTY()
	FVector Location;
};

struct FDentistGeyserBallPlungeIntoWaterEventData
{
	UPROPERTY()
	FVector Location;
};

UCLASS(Abstract)
class UDentistGeyserBallEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistGeyserBall GeyserBall;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GeyserBall = Cast<ADentistGeyserBall>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JumpOutOfWater(FDentistGeyserBallJumpOutOfWaterEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlungeIntoWater(FDentistGeyserBallPlungeIntoWaterEventData EventData)
	{
	}
};
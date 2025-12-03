struct FMagneticFieldAxisRotateStartMagneticPushEventData
{
	UPROPERTY()
	bool bWasBurst;
}

struct FMagneticFieldAxisRotateImpactEventData
{
	UPROPERTY()
	float Strength;
}

UCLASS(Abstract)
class UMagneticFieldAxisRotateEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AMagneticFieldAxisRotateActor AxisRotate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AxisRotate = Cast<AMagneticFieldAxisRotateActor>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMagneticPush(FMagneticFieldAxisRotateStartMagneticPushEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMagneticPush()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FMagneticFieldAxisRotateImpactEventData EventData)
	{
	}
};
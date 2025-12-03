struct FMeltdownScreenWalkDoorBreaking 
{
	FMeltdownScreenWalkDoorBreaking(UStaticMeshComponent _BreakLocation)
	{
		BreakLocation = _BreakLocation;
	}

	UPROPERTY()
	UStaticMeshComponent BreakLocation;
}

UCLASS(Abstract)
class UScreenwalkJumpDoorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorBreak(FMeltdownScreenWalkDoorBreaking Params) {}
};
event void FMagnetDroneAttached();
event void FMagnetDroneDetached();

UCLASS(Abstract)
class ADroneDoubleInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
		
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveComp;

	UPROPERTY(DefaultComponent, Attach = MoveComp)
	UDroneMagneticSocketComponent MagnetComp;

	UPROPERTY(DefaultComponent)
	USwarmDroneHijackTargetableComponent HackComp;

	UPROPERTY()
	FMagnetDroneAttached MagnetAttach;

	UPROPERTY()
	FMagnetDroneDetached MagnetDroneDetached;

	UPROPERTY()
	float LidAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagnetComp.OnMagnetDroneAttached.AddUFunction(this, n"MagnetDroneAttach");
		MagnetComp.OnMagnetDroneDetached.AddUFunction(this, n"MagnetDroneDeAttach");
	}

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY()
	bool bReverse = true;


	UFUNCTION()
	private void MagnetDroneDeAttach(FOnMagnetDroneDetachedParams Params)
	{
		MagnetDroneDetached.Broadcast();
		//UDroneDoubleInteractEventHandler::Trigger_MagnetDroneAttachEvent(this);
		UDroneDoubleInteractEventHandler::Trigger_OnMagnetDroneDetachedEvent(this);
	}

	UFUNCTION()
	void MagnetDroneAttach(FOnMagnetDroneAttachedParams Params)
	{
		MagnetAttach.Broadcast();
		//UDroneDoubleInteractEventHandler::Trigger_OnMagnetDroneDetachedEvent(this);
		UDroneDoubleInteractEventHandler::Trigger_MagnetDroneAttachEvent(this);
	}
};

UCLASS(Abstract)
class AMagnetDroneBreakableDoor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	USceneComponent BotRoot;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	UDroneMagneticZoneComponent MagneticZoneComp;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	UMagnetDroneAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagnetComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	bool bFirstAttach = false;

	UPROPERTY()
	bool bSecondAttach = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagnetComp.OnMagnetDroneAttached.AddUFunction(this, n"MagnetDroneAttached");
		AxisRotateComp.OnMinConstraintHit.AddUFunction(this,n"MinConstraintHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bSecondAttach)
		{
			AxisRotateComp.ApplyAngularForce(-15);
		}
		else if(bFirstAttach)
		{
			AxisRotateComp.ApplyAngularForce(-2);
		}
	}

	UFUNCTION()
	private void MinConstraintHit(float Strength)
	{
		DoorHitFloor();
	}

	UFUNCTION(BlueprintCallable)
	void DoorHitFloor()
	 {
		UMagnetDroneBreakableDoorEventHandler::Trigger_DoorHitFloorEvent(this);
	 }

	 UFUNCTION(BlueprintCallable)
	 void OpenFromStart()
	 {
		bFirstAttach = true;
		bSecondAttach = true;
		AxisRotateComp.SpringStrength = 0;
		AutoAimComp.Disable(this);
		MagneticZoneComp.Disable(this);
		AddActorWorldRotation(FRotator(-90,0,0));
	 }

	UFUNCTION()
	private void MagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		if(bFirstAttach)
		{
			UMagnetDroneBreakableDoorEventHandler::Trigger_SecondHitEvent(this);
			bSecondAttach = true;
			AxisRotateComp.SpringStrength = 0;
			AutoAimComp.Disable(this);
			MagneticZoneComp.Disable(this);
		}

		if(!bFirstAttach)
		{
			UMagnetDroneBreakableDoorEventHandler::Trigger_FirstHitEvent(this);
		}
		
		bFirstAttach = true;

		SetActorTickEnabled(true);
	}
};

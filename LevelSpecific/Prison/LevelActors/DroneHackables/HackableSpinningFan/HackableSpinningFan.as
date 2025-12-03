event void EventHideFanTutorial();

UCLASS(Abstract)
class AHackableSpinningFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	FSwarmHijackStartEvent OnHackingStarted;
	UPROPERTY()
	FSwarmHijackStopEvent OnHackingStopped;

	UPROPERTY(BlueprintReadWrite)
	EventHideFanTutorial OnHideTutorial;

	UPROPERTY(DefaultComponent)
	USceneComponent SpinningFanRoot;

	UPROPERTY(DefaultComponent, Attach = SpinningFanRoot)
	USceneComponent FanRotationRoot;

	UPROPERTY(DefaultComponent, Attach = FanRotationRoot)
	USceneComponent MagneticRoot;

	UPROPERTY(DefaultComponent, Attach = MagneticRoot)
	UDroneMagneticZoneComponent MagneticZoneComp;

	UPROPERTY(DefaultComponent, Attach = MagneticRoot)
	UMagnetDroneAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HackableRoot;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableSpinningFanCapability");

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::Low;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bAllowSpinClockwise = true;

	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bAllowSpinCounterClockwise = true;

	// Minimum speed to rotate while spinning the stick (degrees/second)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float MinimumRotationSpeed = 50.0;

	// Maximum speed to rotate while spinning the stick (degrees/second)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float MaximumRotationSpeed = 100.0;

	// Acceleration of the rotation speed (degrees/second^2)
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float RotationSpeedAcceleration = 100.0;

	// How many times per second must the player spin to get the minimum speed
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float SpinsForMinimumSpeed = 0.2;

	// How many times per second must the player spin to get the maximum speed
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	float SpinsForMaximumSpeed = 2.0;

	// Whether the spin speed should be constant no matter how much the player is spinning
	UPROPERTY(EditAnywhere, Category = "Spinning Fan")
	bool bConstantSpinSpeed = false;

	float TotalRotation = 0.0;

	float RotationSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		HijackTargetableComp.OnHijackStartEvent.AddUFunction(this, n"HackingStarted");
		HijackTargetableComp.OnHijackStopEvent.AddUFunction(this, n"HackingStopped");

		TotalRotation = -FanRotationRoot.RelativeRotation.Pitch;
	}

	UFUNCTION(BlueprintPure)
	float GetNormalizedSpinningSpeed() const
	{
		return Math::NormalizeToRange(Math::Abs(RotationSpeed), 0, MaximumRotationSpeed);
	}

	UFUNCTION(BlueprintPure)
	float GetRotationAngle() const
	{
		return FRotator::ClampAxis(TotalRotation);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted(FSwarmDroneHijackParams HijackParams)
	{
		OnHackingStarted.Broadcast(HijackParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStopped()
	{
		OnHackingStopped.Broadcast();
	}
};
UCLASS(Abstract)
class AHackableWaterGearWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent SpinningFanRoot;

	UPROPERTY(DefaultComponent, Attach = SpinningFanRoot)
	USceneComponent FanRotationRoot;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Water Gear")
	bool bAllowSpinClockwise = true;

	UPROPERTY(EditAnywhere, Category = "Water Gear")
	bool bAllowSpinCounterClockwise = true;

	// Minimum speed to rotate while spinning the stick (degrees/second)
	UPROPERTY(EditAnywhere, Category = "Water Gear")
	float MinimumRotationSpeed = 25.0;

	// Maximum speed to rotate while spinning the stick (degrees/second)
	UPROPERTY(EditAnywhere, Category = "Water Gear")
	float MaximumRotationSpeed = 75.0;

	// Acceleration of the rotation speed (degrees/second^2)
	UPROPERTY(EditAnywhere, Category = "Water Gear")
	float RotationSpeedAcceleration = 100.0;

	// How many times per second must the player spin to get the minimum speed
	UPROPERTY(EditAnywhere, Category = "Water Gear")
	float SpinsForMinimumSpeed = 0.2;

	// How many times per second must the player spin to get the maximum speed
	UPROPERTY(EditAnywhere, Category = "Water Gear")
	float SpinsForMaximumSpeed = 2.0;

	// Whether the spin speed should be constant no matter how much the player is spinning
	UPROPERTY(EditAnywhere, Category = "Water Gear")
	bool bConstantSpinSpeed = false;

	UPROPERTY(EditInstanceOnly, Category = "Water Gear")
	bool bStartDisabled = false;

	TArray<UDroneMagneticSocketComponent> SocketComponents;
	float TotalRotation = 0.0;
	float RotationSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		TotalRotation = -FanRotationRoot.RelativeRotation.Pitch;

		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"OnAttached");
		MagneticSurfaceComp.OnMagnetDroneDetached.AddUFunction(this, n"OnDetached");

		GetComponentsByClass(SocketComponents);

		if(bStartDisabled)
			DisableGear(this);
	}

	UFUNCTION()
	private void OnAttached(FOnMagnetDroneAttachedParams Params)
	{
		UFollowComponentMovementSettings::SetMaxIterations(Params.Player, 3, this);
	}

	UFUNCTION()
	private void OnDetached(FOnMagnetDroneDetachedParams Params)
	{
		UFollowComponentMovementSettings::ClearMaxIterations(Params.Player, this);
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

	UFUNCTION(BlueprintCallable)
	void SetSpinningFanRotationRoot(FRotator NewRot)
	{
		FanRotationRoot.SetRelativeRotation(NewRot);
	}

	UFUNCTION(BlueprintCallable)
	void SetSpinningFanRotationSpeed(float Speed)
	{
		//RotationSpeed = Speed;
	}

	UFUNCTION(BlueprintCallable)
	void SetTotalSpinningFanRotation(float Total)
	{
		//TotalRotation = Total;
	}

	void EnableGear(FInstigator Instigator)
	{
		for(auto SocketComp : SocketComponents)
		{
			SocketComp.Enable(Instigator);
		}
	}

	UFUNCTION()
	void DisableGear(FInstigator Instigator)
	{
		for(auto SocketComp : SocketComponents)
		{
			SocketComp.Disable(Instigator);
		}
	}
};
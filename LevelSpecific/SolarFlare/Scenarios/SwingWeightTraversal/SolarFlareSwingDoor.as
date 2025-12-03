class ASolarFlareSwingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareBatteryPerch> Batterys;

	FVector Start;
	FVector End;

	UPROPERTY(EditAnywhere)
	float ZOffset = 1100.0;
	UPROPERTY(EditAnywhere)
	float Speed = 7000.0;

	FHazeAcceleratedVector AccelVector;

	bool bIsMoving;

	int BatteriesActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Start = ActorLocation;
		End = ActorLocation + FVector(0,0,ZOffset);
		AccelVector.Value = ActorLocation;

		for (ASolarFlareBatteryPerch Battery : Batterys)
		{
			Battery.OnSolarFlareBatteryPerchActivated.AddUFunction(this, n"OnSolarFlareBatteryPerchActivated");
			Battery.OnSolarFlareBatteryPerchDeactivated.AddUFunction(this, n"OnSolarFlareBatteryPerchDeactivated");
		}
	}

	UFUNCTION()
	private void OnSolarFlareBatteryPerchActivated(AHazePlayerCharacter Player)
	{
		BatteriesActive++;
	}

	UFUNCTION()
	private void OnSolarFlareBatteryPerchDeactivated()
	{
		BatteriesActive--;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Target = Start;

		if (BatteriesActive > 0)
		{
			Target = End;
		}
		else
		{
			Target = Start;
		}

		AccelVector.AccelerateTo(Target, 0.45, DeltaSeconds);
		ActorLocation = AccelVector.Value;

		if (ActorLocation != Target && !bIsMoving)
		{
			bIsMoving = true;
			USolarFlareSwingDoorEffectHandler::Trigger_StartMove(this);
		}
		else if (ActorLocation == Target && bIsMoving)
		{
			bIsMoving = false;
			USolarFlareSwingDoorEffectHandler::Trigger_StopMove(this);
		}
	}
};
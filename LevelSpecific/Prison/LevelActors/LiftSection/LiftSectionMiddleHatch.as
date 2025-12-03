UCLASS(Abstract)
class ALiftSectionMiddleHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MoveRootLeft;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MoveLocationLeft;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MoveRootRight;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MoveLocationRight;


	UPROPERTY(DefaultComponent, Attach = MoveRootLeft)
	UStaticMeshComponent StaticMeshLeft;
	UPROPERTY(DefaultComponent, Attach = MoveRootRight)
	UStaticMeshComponent StaticMeshRight;

	FHazeAcceleratedFloat AcceleratedFloatLeft;
	FHazeAcceleratedFloat AcceleratedFloatRight;
	float TargetLocationleft;
	float TargetLocationRight;

	bool bIsActive = false;
	UPROPERTY(EditAnywhere)
	float SpeedMultipier = 1;
	UPROPERTY(EditAnywhere)
	float ExtraHeightOffset = 2;

	float CurrentHeightOffset;
	UPROPERTY(EditAnywhere)
	float Delay = 2.0;

	bool bMainHatchesMove = false;
	bool bHeightOffsetMove = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsActive == true)
		{
			if(bMainHatchesMove)
			{
				TargetLocationleft = MoveLocationLeft.GetRelativeLocation().Y;
				TargetLocationRight = MoveLocationRight.GetRelativeLocation().Y;
			}
			if(bHeightOffsetMove)
				CurrentHeightOffset = ExtraHeightOffset;

			AcceleratedFloatLeft.SpringTo(TargetLocationleft, 0.2 * SpeedMultipier, 0.9, DeltaTime);
			MoveRootLeft.SetRelativeLocation(FVector(0, AcceleratedFloatLeft.Value, CurrentHeightOffset));

			AcceleratedFloatRight.SpringTo(TargetLocationRight, 0.2 * SpeedMultipier, 0.9, DeltaTime);
			MoveRootRight.SetRelativeLocation(FVector(0, AcceleratedFloatRight.Value, CurrentHeightOffset));
		}
		else
		{
			if(bMainHatchesMove)
				TargetLocationleft = 0;
			if(bHeightOffsetMove)
				CurrentHeightOffset = 0;

			AcceleratedFloatLeft.SpringTo(TargetLocationleft, 0.7 * SpeedMultipier, 0.9, DeltaTime);
			MoveRootLeft.SetRelativeLocation(FVector(0, AcceleratedFloatLeft.Value, CurrentHeightOffset));

			TargetLocationRight = 0;
			AcceleratedFloatRight.SpringTo(TargetLocationRight, 0.7 * SpeedMultipier, 0.9, DeltaTime);
			MoveRootRight.SetRelativeLocation(FVector(0, AcceleratedFloatRight.Value, CurrentHeightOffset));
		}
	}

	UFUNCTION()
	void StartMainMove()
	{
		bMainHatchesMove = true;
	}
	UFUNCTION()
	void StartHeightOffset()
	{
		bHeightOffsetMove = true;
	}


	UFUNCTION()
	void OpenHatch()
	{
		bIsActive = true;
		StartHeightOffset();
		Timer::SetTimer(this, n"StartMainMove", Delay);
		Timer::SetTimer(this, n"ResetValues", 8.0);
	}
	UFUNCTION()
	void CloseHatch()
	{
		bIsActive = false;
		StartMainMove();
		Timer::SetTimer(this, n"StartHeightOffset", 8.0);
		Timer::SetTimer(this, n"ResetValues", 20.0);
	}

	UFUNCTION()
	void ResetValues()
	{
		bHeightOffsetMove = false;
		bMainHatchesMove = false;
	}
}
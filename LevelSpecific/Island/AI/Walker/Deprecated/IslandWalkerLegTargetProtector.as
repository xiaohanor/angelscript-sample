class AIslandWalkerLegTargetProtector : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UIslandWalkerLegProtectorPlate Plate0;

	UPROPERTY(DefaultComponent)
	UIslandWalkerLegProtectorPlate Plate1;

	UPROPERTY(DefaultComponent)
	UIslandWalkerLegProtectorPlate Plate2;

	UPROPERTY(DefaultComponent)
	UIslandWalkerLegProtectorPlate Plate3;

	private TArray<UIslandWalkerLegProtectorPlate> Plates;
	bool bOpen;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Plates.Add(Plate0);	
		Plates.Add(Plate1);	
		Plates.Add(Plate2);	
		Plates.Add(Plate3);	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bOpen)
		{
			for(UIslandWalkerLegProtectorPlate Plate: Plates)
			{
				Plate.AccPlateRot.AccelerateTo(Plate.OpenRotation, 1, DeltaSeconds);
				Plate.SetRelativeRotation(Plate.AccPlateRot.Value);
			}
		}
		else
		{
			for(UIslandWalkerLegProtectorPlate Plate: Plates)
			{
				Plate.AccPlateRot.AccelerateTo(Plate.StartRotation, 1, DeltaSeconds);
				Plate.SetRelativeRotation(Plate.AccPlateRot.Value);
			}
		}
	}
}

class UIslandWalkerLegProtectorPlate : UStaticMeshComponent
{
	FRotator StartRotation;
	FRotator OpenRotation;
	FHazeAcceleratedRotator AccPlateRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = RelativeRotation;
		AccPlateRot.Value = StartRotation;
		OpenRotation = StartRotation.Vector().RotateAngleAxis(90, StartRotation.RightVector).Rotation();
	}
}
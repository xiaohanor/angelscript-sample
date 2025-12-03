
struct FIntroTrainCarriageData
{
	AHazeActor Carriage;
	float DistanceAlongSpline;	
	UHazeSplineComponent Spline;

	void MoveCarriage()
	{
		Carriage.ActorLocation = Spline.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
		Carriage.ActorRotation = Spline.GetWorldRotationAtSplineDistance(DistanceAlongSpline).Rotator();
	}
}

class ATrainIntroSpline : ASplineActor
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AHazeActor> TrainCarriageClass;

	UPROPERTY()
	TArray<FIntroTrainCarriageData> CarriagesArray;

	UPROPERTY(EditAnywhere)
	float SpawnDistanceInterval = 3800.0;

	UPROPERTY(EditAnywhere)
	float TrainTravelSpeed = 4000.0;

	UPROPERTY(EditAnywhere)
	int NumberOfCarriages = 15;

	UFUNCTION()
	void StartTrain()
	{
		int Index = 0;

		for (int i = 0; i < NumberOfCarriages; i++)
		{
			SpawnCarriage(SpawnDistanceInterval * Index);
			Index++;
		}
	}

	void SpawnCarriage(float StartingDistance)
	{
		FIntroTrainCarriageData IntroTrainCarriageData;
		IntroTrainCarriageData.Carriage = SpawnActor(TrainCarriageClass, ActorLocation, ActorRotation); 
		IntroTrainCarriageData.DistanceAlongSpline = StartingDistance;
		IntroTrainCarriageData.Carriage.ActorLocation = Spline.GetWorldLocationAtSplineDistance(StartingDistance);
		IntroTrainCarriageData.Spline = Spline;
		CarriagesArray.Add(IntroTrainCarriageData);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FIntroTrainCarriageData StructToRemove;
		bool bRemove = false;

		if (CarriagesArray.Num() == 0)
			return;

		for (FIntroTrainCarriageData& CarriageData : CarriagesArray)
		{
			float MoveCheck = CarriageData.DistanceAlongSpline + TrainTravelSpeed * DeltaSeconds;

			if (MoveCheck >= Spline.SplineLength)
			{
				StructToRemove = CarriageData;
				CarriageData.Carriage.DestroyActor();
				bRemove = true;
			}
			else
			{
				CarriageData.DistanceAlongSpline = MoveCheck;
				CarriageData.MoveCarriage();
			}
		}

		if (bRemove)
			CarriagesArray.Remove(StructToRemove);
	}
}
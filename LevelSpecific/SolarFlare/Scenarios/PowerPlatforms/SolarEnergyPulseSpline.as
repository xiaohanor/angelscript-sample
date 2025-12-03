struct FSolarEnergyPulseData
{
	UPROPERTY()
	AActor TargetActor;

	UPROPERTY()
	float DistanceAlong;

	UHazeSplineComponent SplineComp;

	bool bActive = false;

	void Initiate(UHazeSplineComponent InSplineComp)
	{
		SplineComp = InSplineComp;
		FVector Loc = SplineComp.GetClosestSplineWorldLocationToWorldLocation(TargetActor.ActorLocation);
		DistanceAlong = InSplineComp.GetClosestSplineDistanceToWorldLocation(Loc);
		bActive = false;
	}

	void Reset()
	{
		FVector Loc = SplineComp.GetClosestSplineWorldLocationToWorldLocation(TargetActor.ActorLocation);
		DistanceAlong = SplineComp.GetClosestSplineDistanceToWorldLocation(Loc);
		bActive = false;		
	}
}

class ASolarEnergyPulseSpline : ASplineActor
{	
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TempPulse;

	UPROPERTY(EditAnywhere)
	TArray<AActor> TargetActors;

	UPROPERTY(EditAnywhere)
	float RangeFromPlatform = 300.0; 

	TArray<FSolarEnergyPulseData> PulseData;

	// UPROPERTY()
	// float EnergySpeed = 2000.0;

	FSplinePosition SplinePosition;

	// float EnergyDistance;

	// bool bEnergyActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);

		// SetActorTickEnabled(false);
		TempPulse.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// float NextMove = EnergyDistance + (EnergySpeed * DeltaSeconds); 

		// for (FSolarEnergyPulseData& Data : PulseData)
		// {	
		// 	if (SplinePosition.GetCurrentSplineDistance() > Data.DistanceAlong - RangeFromPlatform && 
		// 	SplinePosition.GetCurrentSplineDistance() < Data.DistanceAlong + RangeFromPlatform)
		// 	{
		// 		if (!Data.bActive)
		// 		{
		// 			Data.bActive = true;
		// 			USolarEnergyPulseResponseComponent ResponseComp = USolarEnergyPulseResponseComponent::Get(Data.TargetActor);
		// 			ResponseComp.EnergyPulseStart();
		// 		}
		// 	}
		// 	else
		// 	{
		// 		if (Data.bActive)
		// 		{
		// 			Data.bActive = false;
		// 			USolarEnergyPulseResponseComponent ResponseComp = USolarEnergyPulseResponseComponent::Get(Data.TargetActor);
		// 			ResponseComp.EnergyPulseStop();
		// 		}
		// 	}
		// }

		// TempPulse.WorldLocation = Spline.GetWorldLocationAtSplineDistance(SplinePosition.GetCurrentSplineDistance());

		// if (NextMove >= Spline.SplineLength)
		// {
		// 	SetActorTickEnabled(false);
		// 	TempPulse.SetHiddenInGame(true);
		// 	bEnergyActive = false;
		// }
		// else
		// {
		// 	EnergyDistance += EnergySpeed * DeltaSeconds;
		// }
	}

	UFUNCTION()
	void AddTargetActor(AActor Actor)
	{
		FSolarEnergyPulseData NewData;
		NewData.TargetActor = Actor;
		NewData.Initiate(Spline);
		PulseData.AddUnique(NewData);
	}

	UFUNCTION()
	void ActivateEnergyPulse()
	{
		// SetActorTickEnabled(true);
		// bEnergyActive = true;
		// EnergyDistance = 0.0;

		// TempPulse.WorldLocation = Spline.GetWorldLocationAtSplineDistance(EnergyDistance);
		// TempPulse.SetHiddenInGame(false);

		// for (FSolarEnergyPulseData& Data : PulseData)
		// {
		// 	Data.bActive = false;
		// 	Data.Reset();
		// }
	}

	void MoveEnergyPulse(float MoveAmount, float DeltaTime)
	{
		SplinePosition.Move(MoveAmount * DeltaTime);
	}
}
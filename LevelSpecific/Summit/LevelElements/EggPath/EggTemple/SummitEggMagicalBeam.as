event void FSummitEggMagicalBeamSignature();
struct FSummitEggBeamDestinationSplineData
{
	UPROPERTY()
	float TargetSplineDistance = 0;
	UPROPERTY()
	float MoveDuration = 0;
}

class ASummitEggMagicalBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(EditAnywhere)
	APropLineProgression PropLineProgression;

	UPROPERTY()
	FSummitEggMagicalBeamSignature OnReachedDestination;

	UPROPERTY(EditAnywhere)
	TArray<FSummitEggBeamDestinationSplineData> SplineDestinationData;

	int CurrentDestinationDataIndex = 0;

	float SplineLength;
	float DistanceAlongSpline;
	float TimeChangedDestination = MAX_flt;
	float PreviousDistanceAlongSpline;
	UHazeSplineComponent Spline;

	UPROPERTY()
	bool bIsDestroyed;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FSplinePosition StartingPosition = Spline.GetSplinePositionAtSplineDistance(0);
		Debug::DrawDebugCircle(StartingPosition.WorldLocation, 500, 12, FLinearColor::Blue, 10, StartingPosition.WorldRightVector, StartingPosition.WorldUpVector);
		float CurrentSplineDistance = 0;
		for (int i = 0; i < SplineDestinationData.Num(); i++)
		{
			CurrentSplineDistance = SplineDestinationData[i].TargetSplineDistance;
			StartingPosition = Spline.GetSplinePositionAtSplineDistance(CurrentSplineDistance);
			Debug::DrawDebugCircle(StartingPosition.WorldLocation, 500, 12, FLinearColor::Blue, 10, StartingPosition.WorldRightVector, StartingPosition.WorldUpVector);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (PropLineProgression != nullptr && PropLineProgression.Target != nullptr && PropLineProgression.Target.bGameplaySpline)
		{
			Spline = Spline::GetGameplaySpline(PropLineProgression.Target);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = Spline::GetGameplaySpline(PropLineProgression.Target);
		SplineLength = Spline.SplineLength;

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FSummitEggBeamDestinationSplineData CurrentData = SplineDestinationData[CurrentDestinationDataIndex];

		float SegmentMoveDuration = Time::GetGameTimeSince(TimeChangedDestination);
		float MoveAlpha = Math::Saturate(SegmentMoveDuration / CurrentData.MoveDuration);

		DistanceAlongSpline = Math::Lerp(PreviousDistanceAlongSpline, CurrentData.TargetSplineDistance, MoveAlpha);
		PropLineProgression.Progression = DistanceAlongSpline / SplineLength;

		FSplinePosition SplinePos = Spline.GetSplinePositionAtSplineDistance(DistanceAlongSpline);

		FVector CurrentLocation = SplinePos.WorldLocation;
		FQuat ActorCurrentRotation = SplinePos.WorldRotation;

		SetActorLocationAndRotation(CurrentLocation, ActorCurrentRotation);
		if (MoveAlpha >= 1.0)
		{
			TimeChangedDestination = Time::GameTimeSeconds;
			CurrentDestinationDataIndex++;
			PreviousDistanceAlongSpline = DistanceAlongSpline;
			if (CurrentDestinationDataIndex >= SplineDestinationData.Num())
			{
				DistanceAlongSpline = 0;
				PreviousDistanceAlongSpline = 0;
				SetActorTickEnabled(false);
			}
		}
	}
	UFUNCTION(CrumbFunction, DevFunction)
	void Crumb_ActivateSplineMove()
	{
		DistanceAlongSpline = 0;
		CurrentDestinationDataIndex = 0;
		PreviousDistanceAlongSpline = 0;
		TimeChangedDestination = Time::GameTimeSeconds;
		SetActorTickEnabled(true);
		BP_StartSplineMove();
		USummitEggMagicalBeamEventHandler::Trigger_StartSplineMove(this);
	}

	UFUNCTION()
	void DeactivateEggBeam()
	{
		SetActorTickEnabled(false);
		PropLineProgression.Progression = 0;

		BP_StopSplineMove(); 
		USummitEggMagicalBeamEventHandler::Trigger_StopSplineMove(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartSplineMove()
	{
	}
	UFUNCTION(BlueprintEvent)
	void BP_StopSplineMove()
	{
	}
}
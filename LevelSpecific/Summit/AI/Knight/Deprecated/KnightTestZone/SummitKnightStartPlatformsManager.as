event void FOnPlatformsCalled();

struct FPlatformData
{
	AActor Platform;
	FVector OriginalVector;
	float SplineDistance;
}

class ASummitKnightStartPlatformsManager : AHazeActor
{
	UPROPERTY()
	FOnPlatformsCalled OnPlatformsCalled;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	FSplinePosition SplinePos;

	TArray<FPlatformData> PlatformData;
	TArray<FPlatformData> MovingPlatformData;

	float SplineMoveSpeed = 4000.0;
	float MoveSpeed = 3000.0;
	float ZOffsetDown = 3000.0;
	bool bHaveActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		SplinePos = SplineActor.Spline.GetSplinePositionAtSplineDistance(0.0);

		TArray<AActor> AttachedPlatforms;
		GetAttachedActors(AttachedPlatforms);
		for (AActor Platform : AttachedPlatforms)
		{
			FPlatformData NewData;
			NewData.Platform = Platform;
			NewData.OriginalVector = Platform.ActorLocation;
			NewData.Platform.ActorLocation += -FVector::UpVector * ZOffsetDown;
			NewData.Platform.AddActorDisable(this);
			NewData.SplineDistance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(NewData.OriginalVector);
			PlatformData.AddUnique(NewData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePos.Move(SplineMoveSpeed * DeltaSeconds);


		//ADD TO MOVING
		TArray<FPlatformData> ToRemovePlatformData;
		
		for (FPlatformData& Data : PlatformData)
		{
			if (Data.SplineDistance < SplinePos.CurrentSplineDistance)
			{
				MovingPlatformData.AddUnique(Data);
				Data.Platform.RemoveActorDisable(this);
				ToRemovePlatformData.Add(Data);
			}
		}

		for (FPlatformData& Data : ToRemovePlatformData)
		{
			PlatformData.Remove(Data);
		}



		//MOVE THEN CHECK REMOVE
		TArray<FPlatformData> ToRemoveMovingPlatformData;

		for (FPlatformData& Data : MovingPlatformData)
		{
			Data.Platform.ActorLocation = Math::VInterpConstantTo(Data.Platform.ActorLocation, Data.OriginalVector, DeltaSeconds, MoveSpeed);
			if (Data.Platform.ActorLocation == Data.OriginalVector)
				ToRemoveMovingPlatformData.Add(Data);
		}

		for (FPlatformData& Data : ToRemoveMovingPlatformData)
		{
			MovingPlatformData.Remove(Data);
		}

		if (MovingPlatformData.Num() == 0 && PlatformData.Num() == 0)
			SetActorTickEnabled(false);
	}


	UFUNCTION()
	void RaisePlatforms()
	{
		if (!HasControl())
			return;

		CrumbRaisePlatforms();
	}

	UFUNCTION(CrumbFunction)
	void CrumbRaisePlatforms()
	{
		if (bHaveActivated)
			return;
		SetActorTickEnabled(true);
		bHaveActivated = true;
		OnPlatformsCalled.Broadcast();
	}
};
event void FSplineMoveEnd();

UCLASS(Abstract)
class ALiftSectionShipThruster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSplineActor;
	UHazeSplineComponent TargetSplineComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor TrackingSplineActor;

	UPROPERTY(EditInstanceOnly)
	ASplineActor LookAtSplineActor;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Target;

	UPROPERTY()
	FSplineMoveEnd SplineEnd;

	UPROPERTY(EditAnywhere)
	bool bActiveFromStart = true;

	bool bMoving = false;

	float CurrentDistanceAlongSpline = 0.0;
	float MovementSpeed = 1000.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetSplineActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		#if EDITOR
		if(TargetSplineActor == nullptr)
		{
			PrintError("TargetSplineActor has not been set on: " + GetName());
			return;
		}
		#endif

		TargetSplineComp = TargetSplineActor.Spline;

		if (bActiveFromStart)
		{
			CurrentDistanceAlongSpline = TargetSplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintCallable)
	void ActivateSpline()
	{
		SetActorTickEnabled(true);
		bMoving = true;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bMoving)
		{
			CurrentDistanceAlongSpline += MovementSpeed * DeltaTime;
			if (CurrentDistanceAlongSpline >= TargetSplineComp.SplineLength)
			{
				bMoving = false;
				SplineEnd.Broadcast();
			}

			FVector CurLoc = TargetSplineComp.GetWorldLocationAtSplineDistance(CurrentDistanceAlongSpline);

			SetActorLocation(CurLoc);
		}	
	}
}
UCLASS(Abstract)
class ALiftSectionShipWing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent WingPivotComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSplineActor;
	UHazeSplineComponent TargetSplineComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SwipeSplineActor;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SwipeReturnSplineActor;

	UPROPERTY(EditAnywhere)
	bool bActiveFromStart = true;

	UPROPERTY(EditInstanceOnly)
	bool bControlledByMio = true;

	bool bMoving = false;

	float CurrentDistanceAlongSpline = 0.0;
	float MovementSpeed = 2500.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetSplineActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bControlledByMio)
			SetActorControlSide(Game::Mio);
		else
			SetActorControlSide(Game::Zoe);

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

	UFUNCTION(BlueprintCallable)
	void SnapActivateSpline()
	{
		SetActorTickEnabled(true);
		bMoving = true;
		CurrentDistanceAlongSpline = TargetSplineComp.SplineLength;
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
			}

			FVector CurLoc = TargetSplineComp.GetWorldLocationAtSplineDistance(CurrentDistanceAlongSpline);

			SetActorLocation(CurLoc);
		}	
	}
}
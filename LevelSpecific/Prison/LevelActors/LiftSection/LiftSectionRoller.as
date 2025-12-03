UCLASS(Abstract)
class ALiftSectionRoller : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent RollerPivotComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSplineActor;
	UHazeSplineComponent TargetSplineComp;

	UPROPERTY(EditAnywhere)
	FVector OriginLocation;

	UPROPERTY(EditAnywhere)
	bool bActiveFromStart = true;

	UPROPERTY(EditAnywhere)
	bool bMoving = false;

	bool bReverseDirection;

	UPROPERTY(BlueprintReadOnly)
	int Reverse = 1;

	int AttackCount = 3;

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
		TargetSplineComp = TargetSplineActor.Spline;

		if (bActiveFromStart)
		{
			CurrentDistanceAlongSpline = TargetSplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
			SetActorTickEnabled(true);
		}
		OriginLocation = GetActorLocation();
	}

	UFUNCTION(BlueprintCallable)
	void ActivateSpline()
	{
		SetActorTickEnabled(true);
		CurrentDistanceAlongSpline = 0;
		bMoving = true;
	}

	UFUNCTION(BlueprintCallable)
	void DeactivateSpline()
	{
		SetActorTickEnabled(false);
		bMoving = false;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bMoving)
		{
			CurrentDistanceAlongSpline += MovementSpeed * DeltaTime * Reverse;
			if (CurrentDistanceAlongSpline >= TargetSplineComp.SplineLength || CurrentDistanceAlongSpline < 0)
			{
				Reverse *= -1;
				AttackCount--;

			}
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				bool bPlayerNearLaser = Math::LineSphereIntersection(GetActorLocation()-FVector(1150,0,0), ActorForwardVector, 3000, Player.ActorCenterLocation, 500.0);
				if (bPlayerNearLaser)
					Player.SetFrameForceFeedback(0.1, 0.1, 0.0, 0.0);
			}

			FVector CurLoc = TargetSplineComp.GetWorldLocationAtSplineDistance(CurrentDistanceAlongSpline);

			SetActorLocation(CurLoc);
		}	
	}
}
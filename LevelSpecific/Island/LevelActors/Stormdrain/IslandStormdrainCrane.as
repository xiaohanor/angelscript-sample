class AIslandStormdrainCrane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = "MovingRoot")
	UStaticMeshComponent Crane;

	UPROPERTY(DefaultComponent, Attach = "Crane")
	USceneComponent CogWheelSlotLeft;

	UPROPERTY(DefaultComponent, Attach = "Crane")
	USceneComponent CogWheelSlotRight;

	UPROPERTY(EditInstanceOnly)
	AIslandStormdrainCraneCogWheel LeftCogWheel;

	UPROPERTY(EditInstanceOnly)
	AIslandStormdrainCraneCogWheel RightCogWheel;

	UPROPERTY(EditInstanceOnly)
	ASplineActor MovementSpline;
	float MaxDistanceAlongSpline;

	float RightSplineAlpha;
	float LeftSplineAlpha;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(LeftCogWheel != nullptr)
		{
			LeftCogWheel.AttachToComponent(CogWheelSlotLeft, NAME_None, EAttachmentRule::SnapToTarget);
		}

		if(RightCogWheel != nullptr)
		{
			RightCogWheel.AttachToComponent(CogWheelSlotRight, NAME_None, EAttachmentRule::SnapToTarget);
		}

		if(RightCogWheel != nullptr && LeftCogWheel != nullptr && MovementSpline != nullptr)
		{
			FSplinePosition SplinePos = Spline::GetGameplaySpline(MovementSpline).GetSplinePositionAtSplineDistance(0*Spline::GetGameplaySpline(MovementSpline).GetSplineLength());
			FQuat SplineRot = Spline::GetGameplaySpline(MovementSpline).GetWorldRotationAtSplineDistance(0*Spline::GetGameplaySpline(MovementSpline).GetSplineLength());
			MovingRoot.SetWorldLocationAndRotation(SplinePos.GetWorldLocation(), SplineRot.Rotator());
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RightCogWheel.ProgressUpdate.AddUFunction(this, n"RightCogUpdate");
		LeftCogWheel.ProgressUpdate.AddUFunction(this, n"LeftCogUpdate");

		MaxDistanceAlongSpline = Spline::GetGameplaySpline(MovementSpline).GetSplineLength();
	}

	UFUNCTION()
	void RightCogUpdate(float SplineAlpha)
	{
		RightSplineAlpha = SplineAlpha;
		PrintToScreen(""+SplineAlpha, 0, FLinearColor::Red);
	}

	UFUNCTION()
	void LeftCogUpdate(float SplineAlpha)
	{
		LeftSplineAlpha = SplineAlpha;
		
		PrintToScreen(""+SplineAlpha, 0, FLinearColor::Red);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float AverageSplineAlpha = (RightSplineAlpha + LeftSplineAlpha)/2;
		if(MovementSpline != nullptr)
		{
			FSplinePosition SplinePos = Spline::GetGameplaySpline(MovementSpline).GetSplinePositionAtSplineDistance(AverageSplineAlpha*MaxDistanceAlongSpline);
			FQuat SplineRot = Spline::GetGameplaySpline(MovementSpline).GetWorldRotationAtSplineDistance(AverageSplineAlpha*MaxDistanceAlongSpline);
			MovingRoot.SetWorldLocationAndRotation(SplinePos.GetWorldLocation(), SplineRot.Rotator());
		}
	}
}
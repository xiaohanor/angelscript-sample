event void CoastTrainCircuitLockeSplineMoveFinishedSignature();

class UCoastTrainCircuitLockeSplineMoveComponent : UActorComponent
{	
	ACoastTrainCircuitLockeSpline CurrentSpline;
	bool bActioned;
	bool bHidden;
	float DistanceAlongSpline;

	UPROPERTY()
	CoastTrainCircuitLockeSplineMoveFinishedSignature OnStart;
	UPROPERTY()
	CoastTrainCircuitLockeSplineMoveFinishedSignature OnFinished;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FinishSpline();
	}

	void SetSpline(ACoastTrainCircuitLockeSpline Spline)
	{
		CurrentSpline = Spline;
		DistanceAlongSpline = 0.0;
		bActioned = false;		
		Cast<AHazeActor>(Owner).TeleportActor(CurrentSpline.Spline.GetWorldLocationAtSplineDistance(0.0), CurrentSpline.Spline.GetWorldRotationAtSplineDistance(0.0).Rotator(), this);

		if(bHidden)
		{
			Owner.RemoveActorVisualsBlock(this);
			Owner.RemoveActorCollisionBlock(this);	
		}
		bHidden = false;
	}

	void FinishSpline()
	{
		bHidden = true;
		CurrentSpline = nullptr;
		Owner.AddActorVisualsBlock(this);
		Owner.AddActorCollisionBlock(this);
	}
}
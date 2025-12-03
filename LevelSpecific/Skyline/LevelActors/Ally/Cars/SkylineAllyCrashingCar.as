UCLASS(Abstract)
class USkylineAllyCrashingCarEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDriving() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCarCrashed() {}
}

class ASkylineAllyCrashingCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;
	float DistanceAlongSpline;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CarRoot;

	UPROPERTY(DefaultComponent, Attach = CarRoot)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(EditAnywhere)
	float Speed = 3000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION()
	void Activate()
	{
		DistanceAlongSpline = 0.0;
		RemoveActorDisable(this);
		USkylineAllyCrashingCarEventHandler::Trigger_OnStartDriving(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		SetActorTickEnabled(false);
		ConeRotateComp.ApplyImpulse(ConeRotateComp.WorldLocation + FVector::UpVector * 100.0, ActorRightVector * 30.0);
		USkylineAllyCrashingCarEventHandler::Trigger_OnCarCrashed(this);
	}

	UFUNCTION()
	void StartCrashed()
	{
		RemoveActorDisable(this);
		SetActorTickEnabled(false);

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(SplineComp.SplineLength);
		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(SplineComp.SplineLength);
		CarRoot.SetWorldLocationAndRotation(Location, Rotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
			if (DistanceAlongSpline < SplineComp.SplineLength)
				DistanceAlongSpline += Speed * DeltaSeconds;
			else
				Deactivate();

			FVector Location = SplineComp.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
			FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(DistanceAlongSpline);
			CarRoot.SetWorldLocationAndRotation(Location, Rotation);
	}
};
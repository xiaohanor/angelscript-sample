class ASummitQuarryLift : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UHazeSplineComponent SplineRef;

	UPROPERTY(EditAnywhere)
	ASummitRollingWheel RollingWheel;

	AHazePlayerCharacter Player;

	float CurrentDistance;
	float TargetDistance;

	UPROPERTY(EditAnywhere)
	float SpeedMultiplier = 1;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{


	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolling");
		SplineRef = SplineActor.Spline;
		RollingWheel.AttachToComponent(MeshRoot);
	}

	UFUNCTION()
	private void OnWheelRolling(float Amount)
	{
		TargetDistance += -Amount * SpeedMultiplier;	
		TargetDistance = Math::Clamp(TargetDistance, 0.0, SplineRef.SplineLength);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentDistance = Math::FInterpTo(CurrentDistance, TargetDistance, DeltaSeconds, 1);
		ActorLocation = SplineRef.GetWorldLocationAtSplineDistance(CurrentDistance);
		FRotator Splinerot = SplineRef.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator();
		Splinerot.Roll = 0.0;
		Splinerot.Pitch = 0.0;
		ActorRotation = Splinerot;
	}
}
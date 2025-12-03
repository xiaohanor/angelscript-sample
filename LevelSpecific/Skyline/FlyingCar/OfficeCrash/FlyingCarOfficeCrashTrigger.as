struct FFlyingCarOfficeCrashParams
{
	AFlyingCarOfficeCrashTrigger OfficeCrashTrigger = nullptr;

	FVector Target;
	FVector Velocity;
	float Time;
}

class AFlyingCarOfficeCrashTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFlyingCarOfficeCrashMovablePlayerTriggerComponent MovableTriggerComponent;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent TargetSpline;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UFlyingCarOfficeCrashTriggerVisualizerComponent VisualizerComponent;
#endif

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect CrashForceFeedbackAsset;

	UPROPERTY(EditAnywhere, Category = "Camera")
	TSubclassOf<UCameraShakeBase> CrashCameraShakeClass;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovableTriggerComponent.OnPlayerEnter.AddUFunction(this, n"OnOfficeCrash");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnOfficeCrash(AHazePlayerCharacter Player)
	{
		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
		if (PilotComponent == nullptr)
			return;

		UFlyingCarOfficeCrashComponent OfficeCrashComponent = UFlyingCarOfficeCrashComponent::Get(PilotComponent.Car);
		if (OfficeCrashComponent == nullptr)
			return;

		ASkylineFlyingCar Car = PilotComponent.Car;
		USkylineFlyingCarGotySettings Settings = USkylineFlyingCarGotySettings::GetSettings(Car);

		FVector StartLocation = Car.ActorLocation + Car.ActorVelocity * Time::GetActorDeltaSeconds(Car);

		float HorizontalSpeed = Car.ActorVelocity.Size();
		float GravityMagnitude = Settings.GravityAmount * UMovementGravitySettings::GetSettings(Car).GravityScale;

		FVector TargetLocation = GetWorldTargetLocation(Car);

		// Debug::DrawDebugSphere(TargetLocation, 100, 12, FLinearColor::Yellow, 4, 20);

		auto JumpParams = Trajectory::CalculateParamsForPathWithHorizontalSpeed(StartLocation, TargetLocation, GravityMagnitude, HorizontalSpeed);

		FFlyingCarOfficeCrashParams CrashParams;
		CrashParams.OfficeCrashTrigger = this;
		CrashParams.Target = TargetLocation;
		CrashParams.Velocity = JumpParams.Velocity;
		CrashParams.Time = JumpParams.Time;

		OfficeCrashComponent.Crash(CrashParams);

		// auto TrajectoryPoints = Trajectory::CalculateTrajectory(StartLocation, 10000, JumpParams.Velocity, GravityMagnitude, 100);
		// for (int i = 0; i < TrajectoryPoints.Num() - 1; i++)
		// 	Debug::DrawDebugLine(TrajectoryPoints.Positions[i], TrajectoryPoints.Positions[i + 1], FLinearColor::DPink, 20, 20);
	}

	FVector GetWorldTargetLocation(ASkylineFlyingCar Car) const
	{
		if (Car == nullptr)
			return TargetSpline.WorldLocation;

		float DistanceToSpline = TargetSpline.WorldLocation.Distance(Car.ActorLocation);
		FVector WantedLocation = Car.ActorLocation + Car.ActorVelocity.GetSafeNormal() * DistanceToSpline;
		
		return TargetSpline.GetClosestSplineWorldLocationToWorldLocation(WantedLocation);
	}
}

#if EDITOR
class UFlyingCarOfficeCrashTriggerVisualizerComponent : UActorComponent {}
class UFkylingCarOfficeCrashComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFlyingCarOfficeCrashTriggerVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AFlyingCarOfficeCrashTrigger CrashTrigger = Cast<AFlyingCarOfficeCrashTrigger>(Component.Owner);
		if (CrashTrigger == nullptr)
			return;

		float Gravity = 2000;

		FVector StartLocation = CrashTrigger.ActorLocation;
		FVector TargetLocation = CrashTrigger.GetWorldTargetLocation(nullptr);

		auto JumpParams = Trajectory::CalculateParamsForPathWithHorizontalSpeed(StartLocation, TargetLocation, Gravity, 7000);
		auto TrajectoryPoints = Trajectory::CalculateTrajectory(StartLocation, 10000, JumpParams.Velocity, Gravity, 100);
		for (int i = 0; i < TrajectoryPoints.Num() - 1; i++)
			DrawDashedLine(TrajectoryPoints.Positions[i], TrajectoryPoints.Positions[i + 1], FLinearColor::DPink, 1000, 20);
	}
}
#endif
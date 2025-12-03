UCLASS(NotBlueprintable)
class APinballBossBallAutoAimVolume : AActorTrigger
{
	default ActorClasses.Add(APinballBossBall);

	UPROPERTY(DefaultComponent)
	UPinballBossBallAutoAimVolumeVisualizeLaunchComponent VisualizeLaunchComp;

	UPROPERTY(EditInstanceOnly, Category = "Auto Aim")
	AActor AimAtActor;

	UPROPERTY(EditInstanceOnly, Category = "Auto Aim")
	float LaunchHeight = 250;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		check(AimAtActor != nullptr, f"{this} needs a AimAtActor assigned!");
		OnActorEnter.AddUFunction(this, n"ActorEnter");
		OnActorLeave.AddUFunction(this, n"ActorLeave");
	}

	UFUNCTION()
	private void ActorEnter(AHazeActor Actor)
	{
		auto BossBall = Cast<APinballBossBall>(Actor);
		if(BossBall == nullptr)
			return;

		BossBall.AutoAimVolumes.AddUnique(this);
	}

	UFUNCTION()
	private void ActorLeave(AHazeActor Actor)
	{
		auto BossBall = Cast<APinballBossBall>(Actor);
		if(BossBall == nullptr)
			return;

		BossBall.AutoAimVolumes.RemoveSingleSwap(this);
	}

	FVector GetLaunchHorizontalDirection() const
	{
		return (AimAtActor.ActorLocation - ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
	}

	FTraversalTrajectory CalculateTrajectory(FVector LaunchFromLocation) const
	{
		const float Gravity = 2500;

		FTraversalTrajectory Trajectory;
		Trajectory.LaunchLocation = LaunchFromLocation;
		Trajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(
			LaunchFromLocation,
			AimAtActor.ActorLocation,
			Gravity,
			LaunchHeight
		);

		Trajectory.Gravity = FVector::UpVector * -Gravity;
		Trajectory.LandLocation = AimAtActor.ActorLocation;
		Trajectory.LandArea = AimAtActor;

		return Trajectory;
	}
};

UCLASS(NotBlueprintable, NotPlaceable)
class UPinballBossBallAutoAimVolumeVisualizeLaunchComponent : USceneComponent
{
}

#if EDITOR
class UPinballBossBallAutoAimVolumeEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPinballBossBallAutoAimVolumeVisualizeLaunchComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto VisualizeLaunchComp = Cast<UPinballBossBallAutoAimVolumeVisualizeLaunchComponent>(Component);
		if(VisualizeLaunchComp == nullptr)
			return;

		auto AutoAimVolume = Cast<APinballBossBallAutoAimVolume>(Component.Owner);
		if(AutoAimVolume == nullptr)
			return;

		const FVector LaunchLocation = VisualizeLaunchComp.WorldLocation;

		DrawWireSphere(LaunchLocation, APinballBossBall::Radius);

		const auto Trajectory = AutoAimVolume.CalculateTrajectory(LaunchLocation);

		float Time = 0;

		FVector PreviousLocation = LaunchLocation;
		while(Time < Trajectory.GetTotalTime())
		{
			Time += 0.02;
			auto Location = Trajectory.GetLocation(Time);

			DrawLine(PreviousLocation, Location, FLinearColor::Green);

			PreviousLocation = Location;
		}
	}
}
#endif
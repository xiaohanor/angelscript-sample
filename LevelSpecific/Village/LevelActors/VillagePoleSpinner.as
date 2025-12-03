UCLASS(Abstract)
class AVillagePoleSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpinnerRoot;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	USceneComponent LeftHazardRoot;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	UDeathTriggerComponent LeftDeathTrigger1;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	UDeathTriggerComponent LeftDeathTrigger2;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	USceneComponent RightHazardRoot;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	UDeathTriggerComponent RightDeathTrigger1;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	UDeathTriggerComponent RightDeathTrigger2;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 4000.0;

	float RotationSpeed = 65.0;
	float HazardRotationRate = 180.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		LeftHazardRoot.AddLocalRotation(FRotator(0.0, HazardRotationRate * DeltaTime, 0.0));
		RightHazardRoot.AddLocalRotation(FRotator(0.0, -HazardRotationRate * DeltaTime, 0.0));

		FRotator Rotation = SpinnerRoot.GetWorldRotation();
		Rotation.Yaw = RotationSpeed * Time::PredictedGlobalCrumbTrailTime;
		Rotation.Normalize();
		SetActorRotation(Rotation);
		SpinnerRoot.SetWorldRotation(Rotation);
	}
}
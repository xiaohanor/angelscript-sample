UCLASS(Abstract)
class AVillageSwingAndPerchWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WheelRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 14000.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FRotator Rotation = GetActorRotation();
		Rotation.Yaw = 30.0 * Time::PredictedGlobalCrumbTrailTime;
		Rotation.Normalize();
		SetActorRotation(Rotation);
	}
}
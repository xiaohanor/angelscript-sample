UCLASS(Abstract)
class AVillageWindmillGrinder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GrinderRoot;

	UPROPERTY(DefaultComponent, Attach = GrinderRoot)
	USceneComponent LeftWheelRoot;

	UPROPERTY(DefaultComponent, Attach = LeftWheelRoot)
	USceneComponent LeftWheelRotator;

	UPROPERTY(DefaultComponent, Attach = LeftWheelRoot)
	UDeathTriggerComponent LeftDeathTrigger;

	UPROPERTY(DefaultComponent, Attach = GrinderRoot)
	USceneComponent RightWheelRoot;
	
	UPROPERTY(DefaultComponent, Attach = RightWheelRoot)
	USceneComponent RightWheelRotator;

	UPROPERTY(DefaultComponent, Attach = RightWheelRoot)
	UDeathTriggerComponent RightDeathTrigger;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	float GrinderSpeed = -30.0;
	float WheelSpeed = 55.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		GrinderRoot.AddWorldRotation(FRotator(0.0, GrinderSpeed * DeltaTime, 0.0));
		LeftWheelRotator.AddLocalRotation(FRotator(0.0, 0.0, WheelSpeed * DeltaTime));
		RightWheelRotator.AddLocalRotation(FRotator(0.0, 0.0, -WheelSpeed * DeltaTime));

		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * 15.0) * 0.2;
		FF.RightMotor = Math::Sin(-Time::GameTimeSeconds* 15.0) * 0.2;
		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, GrinderRoot.WorldLocation - (FVector::UpVector * 150.0), 300.0, 200.0);
	}
}
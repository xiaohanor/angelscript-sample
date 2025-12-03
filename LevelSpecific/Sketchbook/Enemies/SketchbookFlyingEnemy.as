UCLASS(Abstract)
class ASketchbookFlyingEnemy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent,Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent)
	USketchbookArrowResponseComponent ResponseComp;

	FVector AverageVelocity;

	float Wiggle = 10;
	
	float RotationTimer = 1;
	float TimeSinceLastRotation = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitByArrow.AddUFunction(this,n"OnHitbyArrow");
	}

	UFUNCTION()
	private void OnHitbyArrow(FSketchbookArrowHitEventData ArrowHitData, FVector ArrowLocation)
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GetGameTimeSince(TimeSinceLastRotation) > RotationTimer)
		{
			Wiggle*=-1;
			RotationRoot.SetRelativeRotation(FRotator(RotationRoot.RelativeRotation.Pitch, RotationRoot.RelativeRotation.Yaw,Wiggle));
			TimeSinceLastRotation = Time::GameTimeSeconds;
		}
	}
};

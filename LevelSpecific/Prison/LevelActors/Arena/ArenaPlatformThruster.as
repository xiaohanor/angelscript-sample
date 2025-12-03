UCLASS(Abstract)
class AArenaPlatformThruster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HolderRoot;

	UPROPERTY(DefaultComponent, Attach = HolderRoot)
	USceneComponent ThrusterRoot;

	float BasePitch = 0.0;
	float SwingSpeed = 1.0;
	float SwingAngle = 10.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BasePitch = ThrusterRoot.RelativeRotation.Pitch;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Rot = Math::Sin(Time::GameTimeSeconds * SwingSpeed) * SwingAngle;
		ThrusterRoot.SetRelativeRotation(FRotator(BasePitch + Rot, 0.0, 0.0));
	}
}
UCLASS(Abstract)
class ARemoteHackableCamera : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	USceneComponent YawRoot;

	UPROPERTY(DefaultComponent, Attach = YawRoot)
	USceneComponent PitchRoot;

	UPROPERTY(DefaultComponent, Attach = PitchRoot)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	FVector2D YawRange = FVector2D(-15.0, 15.0);
	float InitialYaw = 0.0;
	float InitialYawPitch = 0.0;

	UPROPERTY(EditAnywhere)
	FVector2D PitchRange = FVector2D(-15.0, 15.0);

	float CurrentYaw = 0.0;
	float CurrentPitch = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialYawPitch = YawRoot.WorldRotation.Pitch;
		InitialYaw = YawRoot.WorldRotation.Yaw;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Yaw = Math::Wrap(InitialYaw + CurrentYaw, 0.0, 360.0);
		YawRoot.SetWorldRotation(FRotator(InitialYawPitch, Yaw, 0.0));
		PitchRoot.SetRelativeRotation(FRotator(CurrentPitch, 0.0, 0.0));
	}
}
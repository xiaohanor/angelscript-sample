class USerpentRunCameraSettings : UHazeComposableSettings
{
	UPROPERTY()
	FVector LocalOffset = FVector(-850.0, -700.0, 1250.0);

	UPROPERTY()
	FRotator LocalRotation = FRotator(-14.0, 35.0, 0.0);

	UPROPERTY()
	float BlendTime = 1.0;
}

class ASerpentRunCameraActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UCameraFocusTrackerComponent FocusTracker;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SerpentRunCameraMoveCapability");

	UPROPERTY(DefaultComponent)
	UCameraWeightedTargetComponent FocusTargetComp;

	UPROPERTY(EditAnywhere)
	ASerpentHead SerpentHead;

	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer TargetPlayer;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Target", Meta = (EditCondition = "TargetPlayer == EHazeSelectPlayer::Both", EditConditionHides))
	FVector TargetOffset = FVector(0.0, 0.0, 500.0);

	UPROPERTY()
	USerpentRunCameraSettings CameraSettings;

	// UPROPERTY()
	// USerpentRunCameraSettings Start;
	// UPROPERTY()
	// USerpentRunCameraSettings Weakpoint1;
	// UPROPERTY()
	// USerpentRunCameraSettings Weakpoint2;
	// UPROPERTY()
	// USerpentRunCameraSettings JumpSegment;
	// UPROPERTY()
	// USerpentRunCameraSettings Sidescroller;
	// UPROPERTY()
	// USerpentRunCameraSettings EndSidescroller;
	// UPROPERTY()
	// USerpentRunCameraSettings Slide;

	FVector LocalOffset;
	FVector LocalRotation;
	float LocalOffsetBlendTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplySettings(CameraSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// SetLocalOffset(FVector(-600.0, 200.0, 900.0));
	}

	UFUNCTION()
	void SetLocalOffset(FVector NewLocalOffset, float NewBlendTime = 0.0)
	{
		LocalOffset = NewLocalOffset;
		LocalOffsetBlendTime = Math::Clamp(NewBlendTime, 0.0, 100000.0);
		// CameraComp.RelativeLocation = FVector(NewLocalOffset);
	}

	UFUNCTION()
	void SetLocalRotation(FRotator NewLocalRotation, float NewBlendTime)
	{

	}

	UFUNCTION()
	void ApplyCameraSettings(USerpentRunCameraSettings NewSettings)
	{

	}

	UFUNCTION()
	void ActivateCamera(AHazePlayerCharacter Player, float BlendTime)
	{
		Player.ActivateCamera(CameraComp, BlendTime, this);
	}
}
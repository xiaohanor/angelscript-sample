UCLASS(Abstract)
class UWaveRaftPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FName AttachmentSocketName = n"Align";

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect CollisionFF;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CollisionCameraShake;

	AWaveRaft WaveRaft;

	FVector2D Input;
	float PlayerLean = 0.0;

	UPROPERTY()
	EWaveRaftPaddleBreakDirection BreakState;
	EWaveRaftPaddleBreakDirection LastBreakDirection;
	bool bRaftIsFalling = false;

	float PlayerPaddleSpeed;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("BreakState", BreakState)
			.Value("LastBreakDirection", LastBreakDirection)
			.Value("bRaftIsFalling", bRaftIsFalling)
			.Value("PaddleStrength", PlayerPaddleSpeed);
	}
};
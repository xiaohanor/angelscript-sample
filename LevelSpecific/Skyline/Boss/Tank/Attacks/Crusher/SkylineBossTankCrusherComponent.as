class USkylineBossTankCrusherComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineBossTankCrusherBlastProjectile> BlastProjectileClass;

	UPROPERTY(EditAnywhere)
	UMaterialInterface BlastTelegraphDecal;

	float Spin = 0.0;
	float ArmRotationTarget = 0.0;
	float ArmRotation = 0.0;
	float TelegraphTime = 1.0;
	float ArmMaxAngle = 30.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ArmRotationAnimation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ArmRotationAnimation.BindUpdate(this, n"ArmRotationAnimationUpdate");
	}

	UFUNCTION()
	private void ArmRotationAnimationUpdate(float CurrentValue)
	{
		ArmRotation = ArmRotationAnimation.Value * ArmMaxAngle;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		AccArmRotation.AccelerateTo(ArmRotationTarget * 40.0, 0.5, DeltaSeconds);
	}

	void PlayTelegraph()
	{
		ArmRotationAnimation.PlayFromStart();
	}
};
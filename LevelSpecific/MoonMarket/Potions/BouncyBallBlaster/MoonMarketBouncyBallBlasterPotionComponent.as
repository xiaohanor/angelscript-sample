class UMoonMarketBouncyBallBlasterPotionComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMoonMarketBouncyBallBlaster> BallBlasterClass;

	UPROPERTY()
	TSubclassOf<AMoonMarketBouncyBall> BallClass;

	UPROPERTY()
	FRuntimeFloatCurve ZScaleCurve;

	UPROPERTY()
	FRuntimeFloatCurve JumpHeightCurve;

	UPROPERTY()
	float MoveSpeed = 2000;

	UPROPERTY()
	float RotationSpeed = 90;

	UPROPERTY()
	float RotationAccelerationDuration = 0.5;

	UPROPERTY()
	float ShootCooldown = 0.8;

	UPROPERTY()
	float LaunchVelocity = 2000;

	UPROPERTY()
	UForceFeedbackEffect ShootFeedback;

	AMoonMarketBouncyBallBlaster BallBlaster;
	bool bIsShooting = false;

	FRotator TargetRotation;
};
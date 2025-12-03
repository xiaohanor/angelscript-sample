class UTeenDragonFireBreathSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Input")
	FName InputActionName = ActionNames::PrimaryLevelAbility;

	UPROPERTY()
	float InputBufferDuration = 0.5;

	UPROPERTY()
	float FireBreathDuration = 0.5;

	UPROPERTY()
	float FireBreathCooldown = 0.2;
	
	UPROPERTY()
	FHazeRange FireBreathRadius = FHazeRange(200, 350);

	UPROPERTY()
	float FireBreathRange = 1250.0;

	UPROPERTY()
	FName SocketName = n"Jaw";

	UPROPERTY()
	FRuntimeFloatCurve TravelCurve;
	default TravelCurve.AddDefaultKey(0.0, 0.0);
	default TravelCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	UNiagaraSystem FireBreath;

	UPROPERTY()
	UNiagaraSystem FireBreathMuzzle;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UTeenDragonMovementSettings ShootingMovementSettings;

	UPROPERTY()
	float FireBreathDelay = 0.1;

	UPROPERTY(Category = "Fire Jump")
	float FireJumpImpulse = 2200.0;

	UPROPERTY(Category = "Fire Jump")
	float FireJumpInputGraceTime = 0.2;

	UPROPERTY(Category = "Fire Jump")
	UNiagaraSystem FireJumpExplosion;

	UPROPERTY(Category = "Fire Jump")
	float FireJumpBurningBallDuration = 1.0;

	UPROPERTY(Category = "Fire Jump")
	UNiagaraSystem FireJumpBurningBallEffect;
	
	UPROPERTY(Category = "Fire Jump")
	float FireJumpBurningBallRadius = 500.0;
}
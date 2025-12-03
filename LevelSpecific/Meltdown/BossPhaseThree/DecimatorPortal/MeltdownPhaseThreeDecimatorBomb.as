UCLASS(Abstract)
class AMeltdownPhaseThreeDecimatorBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.bApplyKnockbackImpulse = true;
	default DamageTrigger.HorizontalKnockbackStrength = 900.0;
	default DamageTrigger.VerticalKnockbackStrength = 1200.0;

	AMeltdownPhaseThreeBoss Rader;
	AHazePlayerCharacter TargetPlayer;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> ShellShake;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ShellFeedback;

	FVector StartLocation;
	FVector LandLocation;

	Trajectory::FOutCalculateVelocity LaunchTrajectory;
	const float Gravity = 5000.0;
	bool bChasing = false;
	bool bLockedOnPlayer;
	bool bClockwise = true;
	bool bFellOff = false;

	float TargetSpeed = 1000.0;
	float RotationSpeed = 720;

	float TargetRadius = 0.0;
	float ChaseTimer;
	FVector ChaseVelocity;
	float YawVelocity = 0.0;
	float FallVelocity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Launch()
	{
		StartLocation = GetActorLocation();
		LaunchTrajectory = Trajectory::CalculateParamsForPathWithHeight(
			ActorLocation, LandLocation,
			Gravity, 700.0
		);

		ActionQueue.Duration(LaunchTrajectory.Time, this, n"UpdateLanding");
		ActionQueue.Event(this, n"Landed");
		ActionQueue.Idle(5.0);
		ActionQueue.Duration(0.25, this, n"UpdateExpire");
		ActionQueue.Event(this, n"Destroy");
		UMeltdownBossPhaseThreeDecimatorSpikeBombEventHandler::Trigger_OnSpawn(this);
	}

	UFUNCTION()
	private void UpdateExpire(float Alpha)
	{
		SetActorScale3D(FVector(Math::Lerp(1.0, 0.01, Alpha)));
	}

	UFUNCTION()
	private void Destroy()
	{
		DestroyActor();
	}

	UFUNCTION()
	private void UpdateLanding(float Alpha)
	{
		float Time = Alpha * LaunchTrajectory.Time;
		SetActorLocation(
			StartLocation + (LaunchTrajectory.Velocity * Time) + FVector(0, 0, -Gravity) * 0.5 * Math::Square(Time)
		);
	}

	UFUNCTION()
	private void Landed()
	{
		SetActorLocation(LandLocation);

		ShellFeedback.Play();

		for(AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(ShellShake,this,ActorCenterLocation, 600.0, 1000.0);

		ChaseTimer = 0.0;
		ChaseVelocity = LaunchTrajectory.Velocity;
		ChaseVelocity.Z = 0.0;
		YawVelocity = 0.0;

		bChasing = true;
		bLockedOnPlayer = false;
		UMeltdownBossPhaseThreeDecimatorSpikeBombEventHandler::Trigger_OnLanded(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bChasing)
		{
			ChaseTimer += DeltaSeconds;

			FRotator ChaseDirection = FRotator::MakeFromX(ChaseVelocity);
			float ChaseSpeed = ChaseVelocity.Size();
			
			if (!bLockedOnPlayer && TargetPlayer.ActorLocation.Dist2D(ActorLocation) < 500.0)
				bLockedOnPlayer = true;

			if (!bLockedOnPlayer)
			{
				FRotator TargetDirection = FRotator::MakeFromZX(FVector::UpVector, TargetPlayer.ActorLocation - ActorLocation);
				FRotator NewDirection = Math::RInterpConstantTo(ChaseDirection, TargetDirection, DeltaSeconds, 180.0);

				YawVelocity = (NewDirection.Yaw - ChaseDirection.Yaw) / DeltaSeconds;
				ChaseDirection = NewDirection;
			}
			else
			{
				YawVelocity *= Math::Pow(0.5, DeltaSeconds);
				ChaseDirection.Yaw += YawVelocity * DeltaSeconds;
			}

			FVector ArenaLocation = Rader.ActorLocation;
			if (ActorLocation.Dist2D(ArenaLocation) > Rader.ArenaRadius)
				bFellOff = true;

			ChaseSpeed = Math::FInterpConstantTo(ChaseSpeed, TargetSpeed, DeltaSeconds, TargetSpeed);
			ChaseVelocity = ChaseDirection.ForwardVector * ChaseSpeed;

			FVector Location = GetActorLocation();
			Location += ChaseVelocity * DeltaSeconds;

			if (bFellOff)
			{
				FallVelocity += Gravity * DeltaSeconds;
				Location.Z -= FallVelocity * DeltaSeconds;
			}

			SetActorLocationAndRotation(Location, FRotator::MakeFromX(ChaseVelocity));
		}

		Mesh.AddRelativeRotation(FRotator(0, RotationSpeed * DeltaSeconds, 0));
	}
};

UCLASS(Abstract)
class UMeltdownBossPhaseThreeDecimatorSpikeBombEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnSpawn() {};

	UFUNCTION(BlueprintEvent)
	void OnLanded() {};
}
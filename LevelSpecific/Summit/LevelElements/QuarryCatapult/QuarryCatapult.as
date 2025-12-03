event void FOnFireProjectile(FVector Direction);


class AQuarryCatapult : AHazeActor
{
	FOnFireProjectile OnFireProjectile;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	UStaticMeshComponent BaseMeshComp;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	UStaticMeshComponent ArmMeshComp;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	UBillboardComponent SpawnProjectilePoint;

	UPROPERTY(DefaultComponent)
	UQuarryCatapultRotationComponent QuarryRotatingComp;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal Metal;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AQuarryCatapultProjectile> Projectile;


	float ArmRotationAmount = 70.0;
	float FireProjectileDelay = 0.5;
	float ResetCatapultDelay;
	float TimeSinceActivated;

	bool bIsActivated;
	bool bHasSpawnedProjectile = true;

	FRotator ArmRotTarget = FRotator(0.0, 0.0, 0.0);
	FVector Direction;

	//Projectile Firing Values
	float HorizontalSpeed = 9000.0;
	float Gravity = 8800.0;
	float Distance = 20000.0;

	UPROPERTY(EditAnywhere)
	ASummitTurningWheel TurningWheel;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Metal.AttachToComponent(ArmRoot, n"BaseRoot", EAttachmentRule::KeepWorld);
		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");		
		// ResetCatapultDelay = Metal.TimeBeforeStartingGrowth + 1.0;
		ResetCatapultDelay = UNightQueenMetalMeltingSettings::GetSettings(this).RegrowthDelay.GetFloatValue(Metal.MeltedAlpha) + 1.0;

	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{


		ArmRoot.RelativeRotation = Math::RInterpTo(ArmRoot.RelativeRotation, ArmRotTarget, DeltaSeconds, 6.0);

		if(Time::GameTimeSeconds < TimeSinceActivated + FireProjectileDelay && !bHasSpawnedProjectile)
		{
			FireProjectile();
		}


		if(Time::GameTimeSeconds < TimeSinceActivated + ResetCatapultDelay && bIsActivated)
			return;
		
		ArmRotTarget = FRotator(0.0, 0.0, 0.0);
		TimeSinceActivated = 0.0;
	}


	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		bIsActivated = true;
		bHasSpawnedProjectile = false;

		ArmRotTarget = FRotator(-ArmRotationAmount, 0.0, 0.0);
		
		TimeSinceActivated = Time::GameTimeSeconds;
	}



	private void FireProjectile()
	{
		bHasSpawnedProjectile = true;

		AQuarryCatapultProjectile SpawnedProjectile = SpawnActor(Projectile, SpawnProjectilePoint.WorldLocation, SpawnProjectilePoint.WorldRotation);

		SpawnedProjectile.Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(SpawnProjectilePoint.WorldLocation, BaseRoot.WorldLocation + ActorForwardVector * Distance, Gravity, HorizontalSpeed);	
		SpawnedProjectile.Gravity = Gravity;

		Debug::DrawDebugSphere(BaseRoot.WorldLocation + ActorForwardVector * Distance, 800.0, 12, FLinearColor::Red, 14.0, 10.0);
	}





}
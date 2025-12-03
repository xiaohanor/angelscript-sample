UCLASS(NotBlueprintable)
class UStormChaseFallingObstacleComponent : USceneComponent
{
	AHazeActor HazeOwner;

	bool bIsFalling = false;

	UPROPERTY(EditAnywhere)
	float MinFallSpeed = 3500.0;
	UPROPERTY(EditAnywhere)
	float MaxFallSpeed = 4000.0;
	float FallSpeed;
	float CurrentFallSpeed;

	UPROPERTY(EditAnywhere)
	float MinImpactSpeed = 1500.0;
	UPROPERTY(EditAnywhere)
	float MaxImpactSpeed = 2500.0;

	UPROPERTY(EditAnywhere)
	float MinRotSpeed = 15.0;
	UPROPERTY(EditAnywhere)
	float MaxRotSpeed = 25.0;
	float RotSpeed;

	float Drag = 0.994;

	FRotator RandRotation;
	FVector RandVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);

		ComponentTickEnabled = false;
		FallSpeed = Math::RandRange(MinFallSpeed, MaxFallSpeed);

		float RX = Math::RandRange(-1,1);
		float RY = Math::RandRange(-1,1);
		float RZ = Math::RandRange(0,1);
		RandVelocity = FVector(RX, RY, RZ).GetSafeNormal() * Math::RandRange(MinImpactSpeed, MaxImpactSpeed);

		float RPitch = Math::RandRange(-1, 1);	
		float RYaw = Math::RandRange(-1, 1);	
		float RRoll = Math::RandRange(-1, 1);	

		RotSpeed = Math::RandRange(MinRotSpeed, MaxRotSpeed);
		RandRotation = FRotator(RPitch, RYaw, RRoll) * RotSpeed;
		RelativeScale3D *= Math::RandRange(0.6, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentFallSpeed = Math::FInterpConstantTo(CurrentFallSpeed, FallSpeed, DeltaSeconds, FallSpeed * 0.8);
		FVector GravityVelocity = FVector::DownVector * CurrentFallSpeed; 
		FVector MovementDelta = (GravityVelocity + RandVelocity) * DeltaSeconds;
		RandVelocity -= RandVelocity * Drag * DeltaSeconds;
		Owner.AddActorWorldOffset(MovementDelta);
		Owner.AddActorLocalRotation(RandRotation * DeltaSeconds);
	}

	void StartFalling()
	{
		bIsFalling = true;
		ComponentTickEnabled = true;
		UStormChaseFallingRockObstacleEffectHandler::Trigger_StartFalling(HazeOwner);
	}
};
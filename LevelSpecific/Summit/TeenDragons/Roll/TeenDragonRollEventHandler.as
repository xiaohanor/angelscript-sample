UCLASS(Abstract)
class UTeenDragonRollEventHandler : UHazeEffectEventHandler
{
	// When the roll begins its windup in place
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollWindupStarted() {}

	// When the roll starts moving after the windup is done
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollMovementStarted() {}

	// When the roll has hit something in the world
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollImpact(FRollParams ImpactParams) {}

	// When the roll has hit something in the world that causes a knockback
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollImpactWallKnocback(FRollParams ImpactParam) {}

	// When the roll ends. This can happen without an impact, but will always happen even if there was an impact also.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollEnded() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJump() {}
}

struct FTeenDragonRollOnKnockedBackFromWallParams
{
	UPROPERTY()
	FVector WallHitLocation;

	UPROPERTY()
	FVector WallNormal;

	UPROPERTY()
	float SpeedIntoWall;
}

struct FTeenDragonRollOnReflectedOffWallParams
{
	UPROPERTY()
	FVector WallHitLocation;

	UPROPERTY()
	FVector WallNormal;

	UPROPERTY()
	float SpeedIntoWall;

	UPROPERTY()
	FVector ForwardGoingIntoWall;

	UPROPERTY()
	FVector ForwardLeavingWall;
}

struct FTeenDragonRollOnJumpedParams
{
	UPROPERTY()
	FVector GroundLocation;

	UPROPERTY()
	FVector GroundNormal;
}

struct FTeenDragonRollOnLandedParams
{
	UPROPERTY()
	FVector GroundLocation;

	UPROPERTY()
	FVector GroundNormal;

	UPROPERTY()
	float LandingSpeed;
}

struct FTeenDragonRollOnBouncedParams
{
	UPROPERTY()
	FVector GroundLocation;

	UPROPERTY()
	FVector GroundNormal;

	UPROPERTY()
	float LandingSpeed;
}

struct FTeenDragonRollOnStartedMovingParams
{
	UPROPERTY()
	UHazeSkeletalMeshComponentBase DragonMesh;
}

UCLASS(Abstract)
class UTeenDragonRollVFX : UTeenDragonRollEventHandler
{
	UPROPERTY()
	UNiagaraSystem AirSystem;
	UPROPERTY()
	UNiagaraSystem GroundSystem;
	UPROPERTY()
	UStaticMesh WindMesh;
	UPROPERTY()
	FTransform WindMeshTransform;
	UPROPERTY()
	UMaterialInterface WindMeshMaterial;

	UPROPERTY()
	float MinWindSpeed = 0.5;
	UPROPERTY()
	float MaxWindSpeed = 1.0;

	UPROPERTY()
	float MinWindOpacity = 1.0;
	UPROPERTY()
	float MaxWindOpacity = 3.0;

	const float WindSpeedAccelerationDuration = 1.5;
	const float WindCylinderRotationDuration = 0.5;

	FHazeAcceleratedFloat AccWindSpeed;
	FHazeAcceleratedRotator AccWindCylinderRotation;

	UStaticMeshComponent WindCylinder;
	UNiagaraComponent AirSystemComp;
	UNiagaraComponent GroundSystemComp;
	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonRollSettings RollSettings;

	UFUNCTION(BlueprintOverride)
	void RollMovementStarted() 
	{
		// DragonComp = UPlayerTeenDragonComponent::Get(Owner);
		// RollSettings = UTeenDragonRollSettings::GetSettings(Owner);

		// if (AirSystemComp == nullptr)
		// {
		// 	AirSystemComp = Niagara::SpawnLoopingNiagaraSystemAttached(AirSystem, DragonComp.Owner.RootComponent);
		// 	AirSystemComp.WorldLocation += DragonComp.Owner.ActorUpVector * 100.0;
		// 	AirSystemComp.WorldLocation += DragonComp.Owner.ActorForwardVector * 100.0;
		// }

		// if (GroundSystemComp == nullptr)
		// {
		// 	GroundSystemComp = Niagara::SpawnLoopingNiagaraSystemAttached(GroundSystem, Owner.RootComponent);
		// 	GroundSystemComp.WorldLocation += FVector::UpVector * 50.0;
		// }

		// AirSystemComp.Activate();
		// GroundSystemComp.Activate();

		// if (WindCylinder == nullptr)
		// {
		// 	WindCylinder = UStaticMeshComponent::Create(Owner, n"WindCylinder");
		// 	WindCylinder.SetRelativeTransform(WindMeshTransform);
		// 	WindCylinder.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		// 	WindCylinder.SetStaticMesh(WindMesh);
		// 	WindCylinder.SetMaterial(0, WindMeshMaterial);
		// }

		// WindCylinder.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRollEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKnockedBackFromWall(FTeenDragonRollOnKnockedBackFromWallParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReflectedOffWall(FTeenDragonRollOnReflectedOffWallParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanded(FTeenDragonRollOnLandedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounced(FTeenDragonRollOnBouncedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJumped(FTeenDragonRollOnJumpedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedMovingOnGround(FTeenDragonRollOnStartedMovingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedMovingOnGround() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedMovingInAir(FTeenDragonRollOnStartedMovingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedMovingInAir() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWindUpStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWindUpStopped() {}

	// UFUNCTION(BlueprintOverride)
	// void RollEnded() 
	// {
	// 	if(AirSystemComp != nullptr)
	// 		AirSystemComp.Deactivate();
	// 	if (GroundSystemComp != nullptr)
	// 		GroundSystemComp.Deactivate();
	// 	if (WindCylinder != nullptr)
	// 		WindCylinder.SetHiddenInGame(true);
	// }

	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaTime)
	// {
	// 	if (WindCylinder != nullptr && !WindCylinder.bHiddenInGame)
	// 	{
	// 		float MovementSpeed = Owner.ActorVelocity.Size();
	// 		float SpeedAlpha = Math::NormalizeToRange(MovementSpeed, RollSettings.MinimumRollSpeed, RollSettings.MaximumRollSpeed);

	// 		/** It's how the cylinder is rotated
	// 			¯\_(ツ)_/¯ */  

	// 		FRotator WindCylinderTargetRotation = FRotator::MakeFromYZ(-Owner.ActorVelocity, FVector::UpVector);
	// 		AccWindCylinderRotation.AccelerateTo(WindCylinderTargetRotation, WindCylinderRotationDuration, DeltaTime);
	// 		WindCylinder.WorldRotation = AccWindCylinderRotation.Value;

	// 		TEMPORAL_LOG(Owner)
	// 			.Value("Roll effect handler: Speed Alpha", SpeedAlpha)
	// 		;

	// 		float TargetWindSpeed = Math::Lerp( 
	// 				MinWindSpeed, MaxWindSpeed, SpeedAlpha
	// 			);
			
	// 		AccWindSpeed.AccelerateTo(TargetWindSpeed, WindSpeedAccelerationDuration, DeltaTime);
	// 		WindCylinder.SetScalarParameterValueOnMaterials(
	// 			n"WindSpeed",
	// 			AccWindSpeed.Value
	// 		);

	// 		WindCylinder.SetScalarParameterValueOnMaterials(
	// 			n"GlobalOpacity",
	// 			Math::Lerp(
	// 				MinWindOpacity, MaxWindOpacity, SpeedAlpha
	// 			)
	// 		);
	// 	}
	// }
}
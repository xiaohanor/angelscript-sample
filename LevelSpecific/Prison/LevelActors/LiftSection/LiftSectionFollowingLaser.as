UCLASS(Abstract)
class ALiftSectionFollowingLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	USceneComponent LaserStartLocation;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFX;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFXImpact;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFXImpact2;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMesh;
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshFlameActive;
	default SetActorHiddenInGame(true);


	UFUNCTION(BlueprintOverride)
	void ConstructionScript(){}


float TimeSinceLastHit = 0;

	bool bIsActive = false;
	float FollowSpeed = 10;
	UPROPERTY(EditAnywhere)
	bool bTargetMio = true;
	UPROPERTY()
	FVector TargetLocation;

	AHazePlayerCharacter PlayerTarget;

	UPROPERTY()
	FVector BeamHitLocation;

	FHazeAcceleratedFloat AcceleratedfloatX;
	FHazeAcceleratedFloat AcceleratedfloatY;
	FHazeAcceleratedFloat AcceleratedfloatZ;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsActive == false)
			return;

		if(bTargetMio)
		{
			TargetLocation = Game::GetMio().GetActorLocation();
			PlayerTarget = Game::GetMio();
		}
		else
		{
			TargetLocation = Game::GetZoe().GetActorLocation();
			PlayerTarget = Game::GetZoe();
		}

		AcceleratedfloatX.SpringTo(TargetLocation.X, 200, 0.8, DeltaTime);
		AcceleratedfloatY.SpringTo(TargetLocation.Y, 30, 0.8, DeltaTime);
		AcceleratedfloatZ.SpringTo(TargetLocation.Z, 30, 0.8, DeltaTime);

		VFXImpact.SetWorldLocation(FVector(AcceleratedfloatX.Value, AcceleratedfloatY.Value, AcceleratedfloatZ.Value));
		VFXImpact2.SetWorldLocation(FVector(AcceleratedfloatX.Value, AcceleratedfloatY.Value, AcceleratedfloatZ.Value));
		VFX.SetNiagaraVariableVec3("BeamEnd", FVector(AcceleratedfloatX.Value, AcceleratedfloatY.Value, AcceleratedfloatZ.Value));

		BeamHitLocation = FVector(AcceleratedfloatX.Value, AcceleratedfloatY.Value, AcceleratedfloatZ.Value);

		VFX.SetNiagaraVariableVec3("BeamStart", GetActorLocation());

		if(BeamHitLocation.PointsAreNear(TargetLocation, 75) && TimeSinceLastHit < GameTimeSinceCreation)
		{
			PlayerTarget.DamagePlayerHealth(0.0833333);
			TimeSinceLastHit = GameTimeSinceCreation + 0.005f;
		}

		if(PlayerTarget.IsPlayerDead())
			PlayerTarget = PlayerTarget.GetOtherPlayer();


	}


	UFUNCTION()
	void StartLaser(AHazeActor Actor)
	{
		if (Actor == Game::GetMio())
		{
			bTargetMio = true;
		}
		else if (Actor == Game::GetZoe())
		{
			bTargetMio = false;
		}

		if(bIsActive)
			return;
			
		VFX.Activate(true);
		VFXImpact.Activate(true);
		VFXImpact2.Activate(true);

		AcceleratedfloatX.Value = LaserStartLocation.GetWorldLocation().X;
		AcceleratedfloatY.Value = LaserStartLocation.GetWorldLocation().Y;
		AcceleratedfloatZ.Value = LaserStartLocation.GetWorldLocation().Z;
		VFX.SetNiagaraVariableVec3("BeamStart", GetActorLocation());

		
		//SetActorHiddenInGame(false);
		bIsActive = true;
	}
	UFUNCTION()
	void StopLaser()
	{
		//SetActorHiddenInGame(true);
		VFX.Deactivate();
		VFXImpact.Deactivate();
		VFXImpact2.Deactivate();
		bIsActive = false;
	}
}


class UBuilderComponent : UActorComponent
{
	AHazePlayerCharacter UsingPlayer;

	UPROPERTY()
	TSubclassOf<ABuildingBlocks> BuildingBlockShape1_v1;
	UPROPERTY()
	TSubclassOf<ABuildingBlocks> BuildingBlockShape2_v1;
	UPROPERTY()
	TSubclassOf<ABuildingBlocks> BuildingBlockShape3_v1;

	ABuildingBlocks BuildingBlock1;
	ABuildingBlocks BuildingBlock2;
	ABuildingBlocks BuildingBlock3;

	UPROPERTY()
	ABuildingBlocks CurrentBuildingBlock;
	UPROPERTY()
	AActor BuildingGirdPieceAligner;

	int AmountPlaced = 0;

	/*
	//Replace later maybe------
	UPROPERTY()
	TSubclassOf<UJakobKoppsHitMarkerWidget> HitMarkerClass;
	UJakobKoppsHitMarkerWidget HitMarker;
	//-----------------------
	UPROPERTY()
	TSubclassOf<AHenrikPowerGloveLeft> PowerGloveClassLeft;
	AHenrikPowerGloveLeft PowerGloveLeft;
	*/


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UsingPlayer = Cast<AHazePlayerCharacter>(GetOwner());

		/*
		PowerGloveLeft = SpawnActor(PowerGloveClassLeft);
		PowerGloveLeft.SetUpPowerGlove(UsingPlayer);
		PowerGloveRight = SpawnActor(PowerGloveClassRight);
		PowerGloveRight.SetUpPowerGlove(UsingPlayer);

	//	FakeChargeMesh = SpawnActor(FakeChargeMeshClass);
	//	FakeChargeMesh.SetUp(UsingPlayer);

		PowerGloveLeft.SetActorHiddenInGame(true);

		FadeInAim();
		//Game::GetCody().SetCapabilityActionState(n"HenrikShieldChargerAiming", EHazeActionState::ActiveForOneFrame);
		*/
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}

	void PlaceCurrentBuildingBlock()
	{
		CurrentBuildingBlock.PlaceBlock();

		if(AmountPlaced >= 3)
		{
			AmountPlaced = 0;
		}

		AmountPlaced ++;


		if(AmountPlaced == 1)
		{
			BuildingBlock2 = SpawnActor(BuildingBlockShape2_v1);
			CurrentBuildingBlock = BuildingBlock2;
		}
		if(AmountPlaced == 2)
		{
			BuildingBlock3 = SpawnActor(BuildingBlockShape3_v1);
			CurrentBuildingBlock = BuildingBlock3;
		}
		if(AmountPlaced == 3)
		{
			BuildingBlock1 = SpawnActor(BuildingBlockShape1_v1);
			CurrentBuildingBlock = BuildingBlock1;
		}
		



		CurrentBuildingBlock.StartLocationActor = BuildingGirdPieceAligner;
	}
	void SpawnNewBuildingBlock(FVector StartLocation, FVector TargetLocation)
	{
		

		/*
	//	GravityBall.ThrowAtTarget(Location, Normal, TargetActor);
		if(bShootingFromRightHand)
		{
			ProjectileSpawnActorLocation = PowerGloveRight;
			PlayThrowAnimationRight();
		}	
		else
		{
			ProjectileSpawnActorLocation = PowerGloveRight;
			PlayThrowAnimationLeft();
		}
			
	
		AShieldBusterProjectile SpawnedProjectile= SpawnActor(ShieldBusterProjectileClass, ProjectileSpawnActorLocation.GetActorLocation(), UsingPlayer.ActorForwardVector.Rotation(), n"none", true);

		SpawnedProjectile.bShootingFromRightHand = bShootingFromRightHand;
		SpawnedProjectile.ChargeValue = ChargeValue;
		if(bHasTarget == true)
			SpawnedProjectile.ThrowAtTarget(Location, Normal, TargetActor);
		else
			SpawnedProjectile.ThrowAtNoTarget(Location, UsingPlayer);

		FinishSpawningActor(SpawnedProjectile);

		if(bShootingFromRightHand)
			bShootingFromRightHand = false;
		else
			bShootingFromRightHand = true;

		FHazeCameraImpulse CamImpulse;
		CamImpulse.AngularImpulse = FRotator(45, 0, 0);
		CamImpulse.CameraSpaceImpulse = FVector(-125.0, 0.0, 0.0);
		CamImpulse.WorldSpaceImpulse = FVector(0.0, 0.0, 300.0);
		CamImpulse.ExpirationForce = 30.0;
		CamImpulse.Dampening = 0.9;
		UsingPlayer.ApplyCameraImpulse(CamImpulse);
		*/
	}

	UFUNCTION()
	void SetUp(AActor ActorGirdPieceAligner)
	{
		BuildingGirdPieceAligner = ActorGirdPieceAligner;
		BuildingBlock1 = SpawnActor(BuildingBlockShape1_v1);
		BuildingBlock1.StartLocationActor = BuildingGirdPieceAligner;
		CurrentBuildingBlock = BuildingBlock1;
	}
}

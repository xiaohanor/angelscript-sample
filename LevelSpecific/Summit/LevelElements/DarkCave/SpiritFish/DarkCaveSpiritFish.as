class ADarkCaveSpiritFish : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	FMoveToParams MoveToParams;
	default MoveToParams.Type = EMoveToType::NoMovement;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkCaveSpiritFishTargetableComponent Targetable;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY()
	UNiagaraSystem PoofSystem;

	UHazeSplineComponent SplineComp;
	
	float MinPermaOffset = -600.0;
	float MaxPermaOffset = 600.0;
	float PermaOffset;

	float MinRightOffset = 300.0;
	float MaxRightOffset = 500.0;
	float RightOffsetAmount;

	float MinOffsetSinSpeed = 1.0;
	float MaxOffsetSinSpeed = 2.0;
	float OffsetSinSpeed;

	float MinMoveSpeed = 500.0;
	float MaxMoveSpeed = 900.0;
	float TargetMoveSpeed;
	float MoveSpeed;

	float MinHopRate = 4.0;
	float MaxHopRate = 5.0;
	float HopTime;

	float MinHopHeight = 250.0;
	float MaxHopHeight = 400.0;

	FSplinePosition SplinePos;

	FHazeAcceleratedVector AccelDirection;

	FVector HopLocation;

	ADarkCaveSpiritFishManager Manager;

	UHazeActorNetworkedSpawnPoolComponent SpawnPoolComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSpawnInitialize(FRandomStream Stream, ADarkCaveSpiritFishManager SpawningManager, UHazeSplineComponent Spline, float SplineDistance)
	{
		Manager = SpawningManager;
		SplineComp = Spline;

		PermaOffset = Stream.RandRange(MinPermaOffset, MaxPermaOffset);
		RightOffsetAmount = Stream.RandRange(MinRightOffset, MaxRightOffset);
		OffsetSinSpeed = Stream.RandRange(MinOffsetSinSpeed, MaxOffsetSinSpeed);
		TargetMoveSpeed = Stream.RandRange(MinMoveSpeed, MaxMoveSpeed);

		SplinePos = SplineComp.GetSplinePositionAtSplineDistance(SplineDistance);

		MoveSpeed = TargetMoveSpeed;

		float SinMultiplier = Math::Sin(Time::GameTimeSeconds * OffsetSinSpeed);
		float Offset = PermaOffset + (RightOffsetAmount * SinMultiplier);
		FVector TruePos = SplinePos.WorldLocation + SplinePos.WorldRightVector * Offset;

		AccelDirection.SnapTo((TruePos - ActorLocation).GetSafeNormal());
		SpawnPoolComp = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(Manager.SpiritFishClass, Manager);
		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MoveSpeed = Math::FInterpConstantTo(MoveSpeed, TargetMoveSpeed, DeltaSeconds, TargetMoveSpeed);

		float SinMultiplier = Math::Sin(Time::GameTimeSeconds * OffsetSinSpeed);
		float Offset = PermaOffset + (RightOffsetAmount * SinMultiplier);

		if(HasControl()
		&& Time::GameTimeSeconds > HopTime)
		{
			int RandSeed = Math::RandRange(-MAX_int32, MAX_int32);
			NetSetHop(RandSeed);
		}
		
		if (SplinePos.Move(MoveSpeed * DeltaSeconds))
		{
			FVector TruePos = SplinePos.WorldLocation + SplinePos.WorldRightVector * Offset;
			TruePos += HopLocation;
			AccelDirection.AccelerateTo((TruePos - ActorLocation).GetSafeNormal(), 0.4, DeltaSeconds);
			ActorLocation += AccelDirection.Value.GetSafeNormal() * MoveSpeed * DeltaSeconds;
			ActorRotation = AccelDirection.Value.Rotation();

			HopLocation = Math::VInterpConstantTo(HopLocation, FVector(0), DeltaSeconds, 500.0);
		}
		else
		{
			SpawnPoolComp.UnSpawn(this);
			AddActorDisable(this);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetHop(int Seed)
	{
		FRandomStream Stream = FRandomStream(Seed);

		HopLocation = FVector::UpVector * Stream.RandRange(MinHopHeight, MaxHopHeight);
		HopTime = Time::GameTimeSeconds + Stream.RandRange(MinHopRate, MaxHopRate);

		USpiritFishEventHandler::Trigger_FishHop(this);
	}
	
	// UFUNCTION()
	// private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	//                                   AHazePlayerCharacter Player)
	// {
	// 	FVector EndLoc = ActorLocation + ActorForwardVector * MoveSpeed * 0.5;
	// 	UTeenDragonSpiritFishPounceComponent::Get(Player).ActivatePounce(FTeenDragonSpiritFishPounceData(EndLoc, 500.0, this));
	// }

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbPouncedOn()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(PoofSystem, ActorLocation);
		USpiritFishEventHandler::Trigger_PouncedOn(this);
		if(HasControl())		
			SpawnPoolComp.UnSpawn(this);
		AddActorDisable(this);
	}
};
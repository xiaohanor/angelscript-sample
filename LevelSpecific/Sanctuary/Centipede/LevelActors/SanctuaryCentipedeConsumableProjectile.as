event void FOnSanctuaryCentipedeProjectileConsumedSignature();

class ASanctuaryCentipedeConsumableProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCentipedeBiteResponseComponent BiteResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ConsumableMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ProjectileMeshComp;
	default ProjectileMeshComp.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = ProjectileMeshComp)
	UNiagaraComponent ProjectileVFXComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CentipedeStomachEffectRoot;
	default CentipedeStomachEffectRoot.bHiddenInGame = true;

	float InterpolateHomingDuration = 0.5;
	float InterpolateHomingTimer = 0.0;

	UPROPERTY()
	UNiagaraSystem EatVFX;

	UPROPERTY()
	FOnSanctuaryCentipedeProjectileConsumedSignature OnConsumedEvent;

	ETraceTypeQuery TraceType = ETraceTypeQuery::WeaponTraceEnemy;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike FoodTravelTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike FoodRespawnTimeLike;

	UPROPERTY(Category = Settings)
	float Speed = 1000.0;

	UPROPERTY(Category = Settings)
	float RespawnTime = 10.0;

	UPROPERTY()
	float TargetRadius = 100.0;

	UPROPERTY(Category = Settings)
	float Force = 1.0;

	FVector BiteResponseCompRelativeLocation;

	FVector StartDirection;
	FVector Direction;

	UCentipedeProjectileTargetableComponent TargetableComponent;

	AHazePlayerCharacter EatPlayer;
	AHazePlayerCharacter ShootPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		BiteResponseComp.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStarted");
		FoodTravelTimeLike.BindUpdate(this, n"FoodTravelUpdate");
		FoodTravelTimeLike.BindFinished(this, n"FoodTravelFinished");
		FoodRespawnTimeLike.BindUpdate(this, n"FoodRespawnTimeLikeUpdate");
		FoodRespawnTimeLike.BindFinished(this, n"FoodRespawnTimeLikeFinished");

		BiteResponseCompRelativeLocation = BiteResponseComp.RelativeLocation;
	}

	UFUNCTION()
	private void HandleBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		//Assign players

		EatPlayer = BiteParams.Player;
		ShootPlayer = BiteParams.Player.OtherPlayer;


		//Enable and disable meshes and bite comp

		OnConsumedEvent.Broadcast();
		BiteResponseComp.Disable(this);
		UCentipedeDrinkingEffectComponent::Get(UPlayerCentipedeComponent::Get(EatPlayer).Centipede).BulgeAdd(this);
		ConsumableMeshComp.SetHiddenInGame(true);
		CentipedeStomachEffectRoot.SetHiddenInGame(false, true);
		
		Niagara::SpawnOneShotNiagaraSystemAtLocation(EatVFX, BiteResponseComp.WorldLocation);

		FoodTravelTimeLike.PlayFromStart();
		UPlayerCentipedeComponent::Get(ShootPlayer).NumPassingProjectiles += 1;
		UPlayerCentipedeComponent::Get(ShootPlayer).bPassingProjectile = true;

		//Snap eat head towards bite response comp

		FVector SnapLocation = BiteResponseComp.WorldLocation + 
								(EatPlayer.ActorLocation - BiteResponseComp.WorldLocation).GetSafeNormal() * 
								(Centipede::PlayerMeshMandibleOffset * 0.7);

		EatPlayer.SmoothTeleportActor(SnapLocation, EatPlayer.ActorRotation, this, 0.1);
		
		BiteResponseComp.SetRelativeLocation(FVector(10000000.0));
	}

	UFUNCTION()
	private void FoodTravelUpdate(float Alpha)
	{
		UPlayerCentipedeComponent CentipedeComponent = UPlayerCentipedeComponent::Get(EatPlayer);
		FVector Location = CentipedeComponent.GetLocationAtBodyFraction(Alpha * 0.9 + 0.1) + FVector::UpVector * 20.0;
		UCentipedeDrinkingEffectComponent::Get(UPlayerCentipedeComponent::Get(EatPlayer).Centipede).BulgeUpdate(this, Location);
		CentipedeStomachEffectRoot.SetWorldLocation(Location);
	}

	UFUNCTION()
	private void FoodTravelFinished()
	{
		Direction = ShootPlayer.ActorForwardVector;
		StartDirection = ShootPlayer.ActorForwardVector;

		SetActorTickEnabled(true);

		UCentipedeDrinkingEffectComponent::Get(UPlayerCentipedeComponent::Get(EatPlayer).Centipede).BulgeRemove(this);
		CentipedeStomachEffectRoot.SetHiddenInGame(true, true);
		
		ProjectileMeshComp.SetHiddenInGame(false);
		ProjectileVFXComp.Activate(true);
		ProjectileMeshComp.SetWorldLocation(ShootPlayer.ActorLocation);
		ProjectileMeshComp.SetWorldRotation(Direction.Rotation());
		ProjectileMeshComp.AddLocalRotation(FRotator(-90.0, 0.0, 0.0));

		Timer::SetTimer(this, n"RequestDespawnProjectile", 5.0);

		UPlayerCentipedeComponent::Get(ShootPlayer).NumPassingProjectiles -= 1;
		UPlayerCentipedeComponent::Get(ShootPlayer).bPassingProjectile = UPlayerCentipedeComponent::Get(ShootPlayer).NumPassingProjectiles > 0;

		TargetableComponent = UPlayerCentipedeComponent::Get(ShootPlayer).AutoTargetedComponent;

		PrintToScreen("Target = " + UPlayerCentipedeComponent::Get(ShootPlayer).AutoTargetedComponent, 5.0);
		
		BiteResponseComp.Disable(this);
	}


	UFUNCTION()
	void RequestDespawnProjectile()
	{
		if (!ProjectileMeshComp.bHiddenInGame)
			DespawnProjectile();
	}

	UFUNCTION()
	private void DespawnProjectile()
	{
			ProjectileMeshComp.SetHiddenInGame(true);
			ProjectileVFXComp.Deactivate();

			SetActorTickEnabled(false);

			Timer::SetTimer(this, n"RespawnFood", RespawnTime);
	}

	UFUNCTION()
	private void RespawnFood()
	{
			ConsumableMeshComp.SetHiddenInGame(false);
			FoodRespawnTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void FoodRespawnTimeLikeUpdate(float CurrentValue)
	{
		ConsumableMeshComp.SetRelativeScale3D(FVector(Math::Lerp(0.0001, 0.7, CurrentValue))); // 0.0001 because zero scale gives exception
	}

	UFUNCTION()
	private void FoodRespawnTimeLikeFinished()
	{
		BiteResponseComp.Enable(this);
		BiteResponseComp.SetRelativeLocation(BiteResponseCompRelativeLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Set direction if projectile has a target
		if (TargetableComponent != nullptr)
		{
			const FVector ToTarget = (TargetableComponent.WorldLocation - ProjectileMeshComp.WorldLocation).GetSafeNormal();
			const float Alpha = Math::Clamp(InterpolateHomingTimer / InterpolateHomingDuration, 0.0, 1.0);
			Direction = Math::Lerp(StartDirection, ToTarget, Alpha);
			InterpolateHomingTimer += DeltaSeconds;

			if (TargetableComponent.WorldLocation.Distance(ProjectileMeshComp.WorldLocation) < TargetRadius)
			{
				auto ResponseComp = UCentipedeProjectileResponseComponent::Get(TargetableComponent.Owner);

				if (ResponseComp != nullptr)
				{
					ResponseComp.ProjectileImpact(Direction, 10.0);
				}
				else
					PrintToScreen("PROJECTILE HIT ACTOR WITH TARGETABLE COMP BUT NO PROJECTILE RESPONSE COMP", 10.0, FLinearColor::Red);

				RequestDespawnProjectile();
			}
		}

		//Set location and rotation
		ProjectileMeshComp.SetWorldRotation(FRotator::MakeFromZ(Direction));

		FVector Delta = Direction * Speed * DeltaSeconds;
		FHazeTraceSettings Trace = Trace::InitChannel(TraceType);
		Trace.UseLine();
		Trace.IgnoreActor(this);
		Trace.DebugDrawOneFrame();
		FVector SlightOffsetFromGround = FVector(0.0, 0.0, 30.0);
		FVector CheckFromLocation = ProjectileMeshComp.WorldLocation + SlightOffsetFromGround;
		// Debug::DrawDebugSphere(CheckFromLocation, 50.0, 12, ColorDebug::Ruby, 3.0, 1.0);
		auto Hit = Trace.QueryTraceSingle(CheckFromLocation, CheckFromLocation + Delta);
		if (Hit.bBlockingHit && Hit.Actor != nullptr)
		{
			auto ResponseComp = USanctuaryGrimbeastProjectileResponseComponent::Get(Hit.Actor);
			if (ResponseComp != nullptr)
			{
				ResponseComp.OnProjectileHit.Broadcast(this);
				RequestDespawnProjectile();
			}
		}
		ProjectileMeshComp.AddWorldOffset(Delta);
	}
};
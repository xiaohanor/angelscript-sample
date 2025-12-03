asset SummitStoneBallGravitySettings of UMovementGravitySettings
{
	GravityAmount = 6000.0;
}

event void FOnSummitStoneBallExploded(ASummitStoneBall StoneBall);

class ASummitStoneBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitStoneBallDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	default MeshComp.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereCollision;
	default SphereCollision.SetCollisionProfileName(n"BlockAllDynamic");
	default SphereCollision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitStoneBallEnterMovementCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitStoneBallMovementCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitStoneBallRotationCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitStoneBallExplodeCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitStoneBallFuseRegenerateCapability);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorComp;
	default SyncedActorComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedActorComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UTeenDragonMovementResponseComponent MovementResponseComp;
	default MovementResponseComp.bGroundImpactValid = false;
	default MovementResponseComp.bWallImpactValid = true;
	default MovementResponseComp.bCeilingImpactValid = true;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UDeathTriggerComponent EnterDeathVolume;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	
	UPROPERTY(DefaultComponent)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent PushDirMio;
	default PushDirMio.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float RollImpactMinSpeed = 2200.0;

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float HorizontalImpulseScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float VerticalImpulseScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float AngularVelocityMultiplier = 0.75;

	/** How much it aims towards where the roll direction was and away from player
	 * Time axle: 0->1 normalized angle between roll direction and vector from player
	 * Value axle: 0->1 how much it should aim in the direction of the vector from the player 
	 */
	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	FRuntimeFloatCurve AimCurve;
	default AimCurve.AddDefaultKey(0.0, 0.0);
	default AimCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float AngleAtWhichAimIsFullyVectorFromPlayer = 70.0;

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float HorizontalSpeedGroundDeceleration = 1.5;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float RotationMultiplier = 0.5;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float ExplosionRadius = 1050.0;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float ExplosionForPlayers = 750.0;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float ExplosionScaleUpPulseFrequencyStart = 1.0;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float ExplosionScaleUpPulseFrequencyEnd = 20.0;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	TArray<UNiagaraSystem> ExplosionEffects;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	UForceFeedbackEffect Rumble;

	UPROPERTY()
	FOnSummitStoneBallExploded OnExploded;

	UPROPERTY(EditAnywhere, Category = "Fuse")
	UMaterialInterface FuseMaterial;

	UPROPERTY(EditAnywhere, Category = "Fuse")
	float FuseDuration = 3.0;
	
	UPROPERTY(EditAnywhere, Category = "Fuse")
	float LitScaleUpMagnitude = 0.05;

	UPROPERTY(EditAnywhere, Category = "Fuse")
	float FuseStartHealth = 0.5;

	UPROPERTY(EditAnywhere, Category = "Fuse")
	float FuseRegenerateDelay = 1.0;

	UPROPERTY(EditAnywhere, Category = "Fuse")
	float FuseRegenerationSpeed = 1.0;

	UPROPERTY(EditAnywhere, Category = "Movement Push")
	TPerPlayer<float> MovementPushSpeed;
	default MovementPushSpeed[EHazePlayer::Mio] = 250.0;
	default MovementPushSpeed[EHazePlayer::Zoe] = 500.0;

	float TimeLastHitByAcid;
	TOptional<float> TimeToExplodeFromAdjacentExplosion;

	UFUNCTION(BlueprintPure)
	float GetCurrentFuseHealth()
	{
		return CurrentFuseHealth;
	}

	float CurrentFuseHealth;

	FVector AngularVelocity;

	bool bHasHitDespawnVolume = false;
	bool bHasEntered = false;
	bool bIsExploding = false;

	ASummitStoneBallStatue Statue;

	UMaterialInterface StartMaterial;
	
	FVector PushDirZoe;
	TPerPlayer<uint> FrameLastPushed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentFuseHealth = FuseStartHealth;

		StartMaterial = MeshComp.GetMaterial(0);

		SetActorControlSide(Game::Zoe);

		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		MovementResponseComp.OnMovedInto.AddUFunction(this, n"OnMovedInto");

		ApplyDefaultSettings(SummitStoneBallGravitySettings);

		PushDirMio.OverrideControlSide(Game::Mio);
	}

	UFUNCTION()
	private void OnMovedInto(FTeenDragonMovementImpactParams Params)
	{
		FVector PushDir = Params.VelocityTowardsImpact.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		if(Params.PlayerInstigator.IsMio())
			PushDirMio.SetValue(PushDir);
		else
			PushDirZoe = PushDir;

		FrameLastPushed[Params.PlayerInstigator] = Time::FrameNumber;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;
			if(Time::FrameNumber > FrameLastPushed[Player])
			{
				if(Player.IsMio())
					PushDirMio.SetValue(FVector::ZeroVector);
				else
					PushDirZoe = FVector::ZeroVector;
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByRoll(FRollParams Params)
	{
		float SpeedAtHit = Math::Max(Params.SpeedAtHit, RollImpactMinSpeed);

		FVector DirFromPlayer = (ActorLocation - Params.PlayerInstigator.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		float AngleBetween = Math::RadiansToDegrees(DirFromPlayer.AngularDistance(Params.RollDirection));
		float Alpha = Math::Clamp(AngleBetween / AngleAtWhichAimIsFullyVectorFromPlayer, 0.0, 1.0);
		Alpha = AimCurve.GetFloatValue(Alpha);
		FVector AimDir = FQuat::Slerp(Params.RollDirection.ToOrientationQuat(), DirFromPlayer.ToOrientationQuat(), Alpha).ForwardVector;

		FVector HorizontalImpulse = AimDir * SpeedAtHit * HorizontalImpulseScale;
		FVector VerticalImpulse = FVector::UpVector * SpeedAtHit * VerticalImpulseScale;
		FVector Impulse = HorizontalImpulse	+ VerticalImpulse;

		AngularVelocity += Impulse.CrossProduct(FVector::UpVector) * AngularVelocityMultiplier;
		MoveComp.AddPendingImpulse(Impulse);

		TEMPORAL_LOG(Params.PlayerInstigator, "Explody Fruit")
			.DirectionalArrow("Dir From Player", ActorLocation, DirFromPlayer * 500, 10, 500, FLinearColor::White)
			.DirectionalArrow("Roll Direction", ActorLocation, Params.RollDirection * 500, 10, 500, FLinearColor::Black)
			.DirectionalArrow("Aim Dir", ActorLocation, AimDir * 500, 10, 500, FLinearColor::Red)
			.DirectionalArrow("Horizontal Impulse" , ActorLocation, HorizontalImpulse, 10, 500, FLinearColor::Green)
			.DirectionalArrow("Vertical Impulse" , ActorLocation, VerticalImpulse, 10, 500, FLinearColor::Blue)
			.DirectionalArrow("Impulse", ActorLocation, Impulse, 10, 500, FLinearColor::Teal)
			.Value("Alpha", Alpha)
			.Value("Angle", AngleBetween)
		;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAcidHit(FAcidHit Hit)
	{
		if(CurrentFuseHealth <= 0)
			return;
		
		// Print(f"{Hit.Damage=}");
		AlterFuseHealth(-Hit.Damage);
		TimeLastHitByAcid = Time::GameTimeSeconds;
	}

	void AlterFuseHealth(float FuseChange)
	{
		SetFuseHealth(CurrentFuseHealth + FuseChange);
	}

	void SetFuseHealth(float NewHealth)
	{
		CurrentFuseHealth = NewHealth;
		CurrentFuseHealth = Math::Clamp(CurrentFuseHealth, 0, FuseStartHealth);
	}

	UFUNCTION(CrumbFunction)
	void CrumbResetPostRespawn(ASummitStoneBallStatue SpawningStatue)
	{
		Statue = SpawningStatue;
		bHasEntered = false;
		MeshComp.SetMaterial(0, StartMaterial);
		CurrentFuseHealth = FuseStartHealth;
		TimeToExplodeFromAdjacentExplosion.Reset();
		MeshOffsetComp.SetRelativeScale3D(FVector::OneVector);
		bHasHitDespawnVolume = false;
		USummitStoneBallEffectHandler::Trigger_OnRespawned(this);

		RemoveActorDisable(this);
	}
	
	void Explode()
	{
		FHazeTraceSettings Trace;
		Trace.UseSphereShape(ExplosionRadius);
		Trace.TraceWithProfileFromComponent(SphereCollision);
		Trace.IgnoreActor(this);
		FVector ExplodeLocation = ActorLocation;
		auto Overlaps = Trace.QueryOverlaps(ExplodeLocation);

		TArray<AActor> ExplodedActors;

		const float MultiExplosionDelayDuration = 0.1;
		float MultiExplosionDelay = MultiExplosionDelayDuration;

		AActor WallActor;
		for(auto Overlap : Overlaps)
		{
			if(ExplodedActors.Contains(Overlap.Actor))
				continue;
			
			auto OverlappingBall = Cast<ASummitStoneBall>(Overlap.Actor);
			if(OverlappingBall != nullptr)
			{
				OverlappingBall.TimeToExplodeFromAdjacentExplosion.Set(Time::GameTimeSeconds + MultiExplosionDelay);
				MultiExplosionDelay += MultiExplosionDelayDuration;
			}

			if(Overlap.Actor.IsA(ASummitExplodyFruitWallCrack))
			{
				WallActor = Overlap.Actor;
			}

			auto ResponseComp = USummitStoneBallResponseComponent::Get(Overlap.Actor);
			if(ResponseComp != nullptr)
			{
				FSummitStoneBallExplosionParams Params;
				Params.ExplosionLocation = ExplodeLocation;
				Params.HitComponent = Overlap.Component;
				ResponseComp.OnStoneBallExploded.Broadcast(Params);
			}

			ExplodedActors.AddUnique(Overlap.Actor);
		}

		if(WallActor != nullptr)
		{
			FSummitStoneBallOnExplodedNearWallParams WallExplosionParams;
			WallExplosionParams.WallActor = WallActor;
			USummitStoneBallEffectHandler::Trigger_OnBallExplodedNearWall(this, WallExplosionParams);
		}
		else
			USummitStoneBallEffectHandler::Trigger_OnBallExploded(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000, 20000);
			float Alpha = Math::Saturate(1 - (Player.ActorLocation - ActorLocation).Size() / 15000);
			Player.PlayForceFeedback(Rumble, false, true, this, Alpha);

			if(Player.ActorLocation.DistSquared(ActorLocation) < Math::Square(ExplosionForPlayers))
			{
				FVector Direction = (Player.ActorLocation - ActorLocation).GetSafeNormal();
				Player.KillPlayer(FPlayerDeathDamageParams(Direction, 25.0), DeathEffect);
			}
		}

		if(Statue != nullptr)
		{
			Statue.SpawnPoolComp.UnSpawn(this);
			AddActorDisable(this);
			Statue.BallsSpawned--;
		}
		else
		{
			AddActorDisable(this);
		}

		OnExploded.Broadcast(this);
		bIsExploding = false;
	}
};

#if EDITOR
class USummitStoneBallDummyComponent : UActorComponent {};
class USummitStoneBallComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitStoneBallDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitStoneBallDummyComponent>(Component);
		if(Comp == nullptr)
			return;

		auto StoneBall = Cast<ASummitStoneBall>(Comp.Owner);
		if(StoneBall == nullptr)
			return;
		
		SetRenderForeground(false);

		FVector ExplosionOrigin = StoneBall.ActorLocation;
		DrawWireSphere(ExplosionOrigin, StoneBall.ExplosionRadius, FLinearColor::Green, 10, 24, false);
		DrawWorldString("Explosion Radius", ExplosionOrigin + FVector::UpVector * (StoneBall.ExplosionRadius + 50), FLinearColor::Green, 1.5, 5000);


		DrawWireSphere(ExplosionOrigin, StoneBall.ExplosionForPlayers, FLinearColor::Red, 10, 24, false);
		DrawWorldString("Explosion Radius For Players", ExplosionOrigin + FVector::UpVector * (StoneBall.ExplosionForPlayers + 50), FLinearColor::Red, 1.5, 5000);
	}
}
#endif
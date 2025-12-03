event void FonLanded();

class AMeltdownBossPhaseOneSmashAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileRoot;
	default ProjectileRoot.RelativeLocation = FVector(0, 0, 1200.0);

	UPROPERTY(DefaultComponent)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SmashShake;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> SmashDeath;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UMeltdownBossCubeGridDisplacementComponent Displacement;
	default Displacement.Type = EMeltdownBossCubeGridDisplacementType::Shape;
	default Displacement.bInfiniteHeight = true;
	default Displacement.bModifyCubeGridCollision = true;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float Radius = 200;

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float Speed = 4000;

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float HitDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float RestoreDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float HitDisplacement = -1000;

	UPROPERTY(EditAnywhere, Category = "Tracking")
	float TrackingAccelerationDuration = 5;

	bool bIsTelegraphing = false;
	bool bHasFired = false;
	bool bHasHit = false;

	float FireTimer = 0.0;
	float FireCountdown = 0.0;
	float HitTimer = 0.0;
	
	AHazePlayerCharacter TrackPlayer;
	float TrackTotalDuration = 0.0;
	float TrackPredictDistance;
	float TrackTimer = 0.0;

	bool bAutoDestroy = false;

	FVector DefaultOffset;
	FHazeAcceleratedVector TrackedLocation;

	UPROPERTY()
	FRuntimeFloatCurve SpawnCurve_Height;
	UPROPERTY()
	FRuntimeFloatCurve SpawnCurve_Width;

	float SpawnTimer = 0.0;

	UPROPERTY()
	FonLanded AttackLanded;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Displacement.Shape = FHazeShapeSettings::MakeSphere(Radius); 
		Displacement.LerpDistance = 100.0;
		Displacement.Displacement = FVector(0, 0, 1);
	}

	UFUNCTION()
	void StartAttack(float TelegraphTime = 2.0, AHazePlayerCharacter PlayerToTrack = nullptr, float TrackDuration = 0.0, float PredictDistance = 0.0)
	{
		FireCountdown = TelegraphTime;
		TrackPlayer = PlayerToTrack;
		TrackTimer = TrackDuration;
		TrackTotalDuration = TrackDuration;
		TrackPredictDistance = PredictDistance;
		StartTelegraph();
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void DevStartAttack()
	{
		StartAttack(2.0, Game::Mio, 1.0);
	}

	UFUNCTION(DevFunction)
	void StartTelegraph()
	{
		RemoveActorDisable(this);
		bIsTelegraphing = true;
		bHasFired = false;
		bHasHit = false;

		ProjectileRoot.SetHiddenInGame(false, true);
		ProjectileRoot.RelativeLocation = DefaultOffset;

		TrackedLocation.SnapTo(ActorLocation);

		Displacement.Shape = FHazeShapeSettings::MakeSphere(Radius); 
		Displacement.Displacement = FVector(0, 0, 1);
		Displacement.Redness = -1.0;

		UpdatePlayerTracking(0.0, true);
		UMeltdownBossPhaseOneSmashAttackEffectHandler::Trigger_SpawnSmasher(this);

		AMeltdownBoss Rader = ActorList::GetSingle(AMeltdownBossPhaseOne);
		UMeltdownBossPhaseOneSmashAttackEffectHandler::Trigger_SpawnSmasher(Rader);

		ProjectileRoot.WorldScale3D = FVector(0, 0, 0);
		SpawnTimer = 0.0;
	}

	UFUNCTION(DevFunction)
	void StartFiring()
	{
		RemoveActorDisable(this);
		bIsTelegraphing = false;
		bHasFired = true;
		bHasHit = false;

		ProjectileRoot.SetHiddenInGame(false, true);
		ProjectileRoot.RelativeLocation = DefaultOffset;

		Displacement.ActivateDisplacement();
		Displacement.Shape = FHazeShapeSettings::MakeSphere(Radius); 
		Displacement.Displacement = FVector(0, 0, 1);
		Displacement.Redness = 1.0;

		UMeltdownBossPhaseOneSmashAttackEffectHandler::Trigger_StartFalling(this);
	}

	UFUNCTION(DevFunction)
	void HitImpact()
	{
		RemoveActorDisable(this);
		bIsTelegraphing = false;
		bHasFired = false;
		bHasHit = true;
		HitTimer = HitDuration + RestoreDuration;
		AttackLanded.Broadcast();
		Game::GetClosestPlayer(ActorLocation).PlayWorldCameraShake(SmashShake,this, ActorLocation,200,600);

		ProjectileRoot.SetHiddenInGame(true, true);
		Displacement.ActivateDisplacement();

		for (auto Player : Game::Players)
		{
			if (Player.ActorLocation.Distance(Displacement.WorldLocation) < Radius)
				Player.KillPlayer(DeathEffect = SmashDeath);
		}

		FMeltdownBossPhaseOneSmashAttackHitParams HitParams;
		HitParams.HitLocation = Displacement.WorldLocation;
		UMeltdownBossPhaseOneSmashAttackEffectHandler::Trigger_SmasherHitFloor(this, HitParams);
	}

	UFUNCTION(BlueprintEvent)
	void OnHitShake()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		DefaultOffset = ProjectileRoot.RelativeLocation;

		Displacement.bModifyCubeGridCollision = false;
		Displacement.Shape = FHazeShapeSettings::MakeSphere(Radius); 
		Displacement.LerpDistance = 100.0;
		Displacement.Displacement = FVector(0, 0, 1);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bHasHit)
		{
			Displacement.bModifyCubeGridCollision = true;
			HitTimer -= DeltaSeconds;
			if (HitTimer <= 0.0)
			{
				AddActorDisable(this);
				if (bAutoDestroy)
					DestroyActor();
			}
			else if (HitTimer < RestoreDuration)
			{
				Displacement.Displacement.Z = Math::Lerp(HitDisplacement, 0.0, 1.0 - (HitTimer / RestoreDuration));
				Displacement.Redness = 0.0;
				Displacement.bDisplacementAsleep = false;
			}
			else
			{
				Displacement.Displacement.Z = Math::Max(Displacement.Displacement.Z - (DeltaSeconds * Speed), HitDisplacement);
				Displacement.Redness = 1.0;
				Displacement.bDisplacementAsleep = Displacement.Displacement.Z <= HitDisplacement;

				FVector KillLocation = TelegraphRoot.WorldLocation + Displacement.Displacement;
				PlayerHealth::KillPlayersInRadius(KillLocation, Radius);
				// Debug::DrawDebugSphere(KillLocation, Radius, LineColor = FLinearColor::Red);
			}

			FBox KillBox = FBox(FVector(-Radius - 100, -Radius - 100, HitDisplacement), FVector(Radius + 100, Radius + 100, -100));
			FTransform KillTransform(TelegraphRoot.WorldLocation);

			for (auto Player : Game::Players)
			{
				if (KillBox.IsInside(KillTransform.InverseTransformPosition(Player.ActorLocation)))
					Player.KillPlayer();
			}
			// Debug::DrawDebugBox(KillBox.Center + KillTransform.Location, KillBox.Extent, KillTransform.Rotator(), FLinearColor::Red);
		}
		else if (bHasFired)
		{
			Displacement.Displacement = FVector(0.0, 0.0, Math::Sin(Time::GameTimeSeconds * 15.0) * 10.0 * 3.0 + 30.0);
			Displacement.bModifyCubeGridCollision = false;

			FVector NewLocation = ProjectileRoot.RelativeLocation;
			NewLocation.Z -= DeltaSeconds * Speed;
			ProjectileRoot.RelativeLocation = NewLocation;

			if (NewLocation.Z <= 0.0)
				HitImpact();
		}
		else if (bIsTelegraphing)
		{
			Displacement.ActivateDisplacement();
			Displacement.bModifyCubeGridCollision = false;

			if (TrackTimer > 0)
			{
				TrackTimer -= DeltaSeconds;
				UpdatePlayerTracking(DeltaSeconds, false);

				float TelegraphPct = 1.0 - Math::Saturate(TrackTimer / TrackTotalDuration);
				Displacement.Displacement = FVector(0.0, 0.0, Math::Sin(Time::GameTimeSeconds * 15.0) * 10.0 + 30.0 * TelegraphPct);
				Displacement.Redness = -0.5;
			}
			else
			{
				Displacement.Displacement = FVector(0.0, 0.0, Math::Sin(Time::GameTimeSeconds * 15.0) * 10.0 * 3.0 + 30.0);
				Displacement.Redness = 1.0;
			}

			if (FireCountdown > 0.0)
			{
				FireCountdown -= DeltaSeconds;
				if (FireCountdown <= 0.0)
					StartFiring();
			}
		}

		SpawnTimer += DeltaSeconds;

		float SpawnWidth = SpawnCurve_Width.GetFloatValue(SpawnTimer);
		float SpawnHeight = SpawnCurve_Height.GetFloatValue(SpawnTimer);
		ProjectileRoot.WorldScale3D = FVector(SpawnWidth, SpawnWidth, SpawnHeight);
	}

	void UpdatePlayerTracking(float DeltaTime, bool bSnapTracking)
	{
		if (TrackPlayer == nullptr)
			return;

		FVector TargetLocation = TrackPlayer.ActorLocation;
		TargetLocation.Z = ActorLocation.Z;

		if (TrackPredictDistance > 0)
		{
			FVector Velocity = TrackPlayer.ActorHorizontalVelocity;
			TargetLocation += Velocity.GetSafeNormal2D() * TrackPredictDistance;
		}

		if (TrackingAccelerationDuration <= 0.0 || bSnapTracking)
		{
			TrackedLocation.SnapTo(TargetLocation);
		}
		else
		{
			TrackedLocation.AccelerateTo(TargetLocation, TrackingAccelerationDuration, DeltaTime);
		}

		SetActorLocation(TrackedLocation.Value);
	}
};

struct FMeltdownBossPhaseOneSmashAttackHitParams
{
	UPROPERTY()
	FVector HitLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseOneSmashAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnSmasher() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFalling() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmasherHitFloor(FMeltdownBossPhaseOneSmashAttackHitParams HitParams) {}
}

UCLASS(Abstract)
class UMeltdownBossPhaseOneRaderSmashAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnSmasher() {}
}
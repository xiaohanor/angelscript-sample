UCLASS(Abstract)
class AMeltdownBossPhaseTwoSpaceBatAsteroid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent FX_Mesh;
	default FX_Mesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent FX_Trail;
	default FX_Trail.bAutoActivate = false;

	UPROPERTY()
	UMaterialInterface FX_Overlay;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent ShootComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ActorList;

	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaesTwoSpaceBatFireTrail> FireTrailClass;

	AMeltdownBossPhaseTwo Rader;
	AHazePlayerCharacter TargetPlayer;

	bool bHasHit = false;
	float Timer = 0.0;
	FRotator RotationRate;

	float SpawnDistance = 8000.0;

	FVector Direction;
	float Speed = 5000.0;
	int Health = 2;

	FVector SpawnDirection;
	FVector StartLocation;

	AMeltdownBossPhaesTwoSpaceBatFireTrail CurrentFireTrail;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShootComp.OnGlitchHit.AddUFunction(this, n"GlitchHit");
		DamageTrigger.OnPlayerDamagedByTrigger.AddUFunction(this, n"OnDamagedPlayer");
		FX_Mesh.SetAbsolute(false, true, true);
		FX_Trail.SetAbsolute(false, true, true);
	}

	UFUNCTION()
	private void OnDamagedPlayer(AHazePlayerCharacter Player)
	{
		Player.AddKnockbackImpulse(
			Direction, 900, 900
		);
	}

	UFUNCTION()
	private void GlitchHit(FMeltdownGlitchImpact Impact)
	{
		if (!bHasHit)
			return;

		UMeltdownBossPhaseTwoAsteroidEffectHandler::Trigger_HitByGlitch(this, Impact);
		Health -= 1;
		if (Health <= 0)
		{
			UMeltdownBossPhaseTwoAsteroidEffectHandler::Trigger_DestroyedByPlayerHit(this);
			DestroyActor();
		}
	}

	void Spawn()
	{
		StartLocation = SpawnDirection * SpawnDistance;

		ActorLocation = StartLocation;
		RotationRate = FRotator::MakeFromEuler(Math::VRand());
		UMeltdownBossPhaseTwoAsteroidEffectHandler::Trigger_SpawnAsteroid(this);
	}

	void BatHit()
	{
		bHasHit = true;
		RotationRate = FRotator::MakeFromEuler(Math::VRand());

		FVector TargetLocation = TargetPlayer.ActorLocation;
		// TargetLocation += TargetPlayer.ActorHorizontalVelocity.GetSafeNormal2D() * 600.0;
		TargetLocation.Z = Rader.SpaceArenaLocation.ActorLocation.Z + 200.0;

		Direction = (TargetLocation - ActorLocation).GetSafeNormal2D();
		UMeltdownBossPhaseTwoAsteroidEffectHandler::Trigger_HitByBat(this);
		FX_Trail.Activate(true);
		FX_Mesh.SetWorldRotation(FRotator::MakeFromX(Direction));
		FX_Mesh.SetHiddenInGame(false);
		//Mesh.SetOverlayMaterial(FX_Overlay);
	}

	void Explode()
	{
		UMeltdownBossPhaseTwoAsteroidEffectHandler::Trigger_Explode(this);
		FX_Trail.Deactivate();
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;

		SetActorScale3D(FVector(
			Math::GetMappedRangeValueClamped(
				FVector2D(0.0, 1.0),
				FVector2D(0.01, 1.0),
				Timer,
			)
		));
		SetActorHiddenInGame(false);

		if (!bHasHit)
		{
			FTransform AlignLocation = Rader.Mesh.GetSocketTransform(n"Align");
			FVector TargetLocation = AlignLocation.Location + Math::Lerp(StartLocation, FVector::ZeroVector, Timer / 0.8);
			TargetLocation.Z = Rader.SpaceArenaLocation.ActorLocation.Z + 300;

			ActorLocation = TargetLocation;

			AddActorWorldRotation(RotationRate * DeltaSeconds * 300.0);
		}
		else
		{
			AddActorWorldRotation(RotationRate * DeltaSeconds * 600.0);

			if (Timer >= 5.0)
			{
				// Asteroid has expired
				Explode();
			}
			else
			{
				FVector NewLocation = ActorLocation + Direction * Speed * DeltaSeconds;
				SetActorLocation(NewLocation);

				// Check if we're scraping the arena at the moment
				FVector ArenaLocation = ActorLocation;
				ArenaLocation.Z = Rader.SpaceArenaLocation.ActorLocation.Z;

				bool bIsScrapingArena = (ActorLocation.Z - ArenaLocation.Z) <= 400.0
					&& ArenaLocation.Dist2D(Rader.SpaceArenaLocation.ActorLocation) <= 1500;

				// Debug::DrawDebugSphere(ActorLocation, 400);
				// Debug::DrawDebugSphere(ArenaLocation, 400, LineColor = FLinearColor::Red);
				// Debug::DrawDebugSphere(Rader.SpaceArenaLocation.ActorLocation, 1500, LineColor = FLinearColor::Green);

				if (bIsScrapingArena)
				{
					if (CurrentFireTrail == nullptr)
					{
						CurrentFireTrail = SpawnActor(FireTrailClass, ArenaLocation - (Direction * 10.0));
					}

					CurrentFireTrail.ActorLocation = ArenaLocation;
					CurrentFireTrail.UpdateTrail();
				}
				else
				{
					if (CurrentFireTrail != nullptr)
					{
						CurrentFireTrail.StopMoving();
						CurrentFireTrail = nullptr;
					}
				}
			}
		}
	}

};

UCLASS(Abstract)
class AMeltdownBossPhaesTwoSpaceBatFireTrail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_Trail;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalTrailComponent FX_DecalTrail;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ActorList;

	const float Lifetime = 5.0;
	float Timer = 0.0;

	FVector StartLocation;

	void StopMoving()
	{
		FX_Trail.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintEvent)
	void ClearTrail() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if (Timer > Lifetime)
		{
			DestroyActor();
			return;
		}
		if (Timer > (Lifetime-2))
		{
			ClearTrail();
		}
	}

	void UpdateTrail()
	{
		FVector CenterLocation = (ActorLocation + StartLocation) * 0.5;
		float Length = ActorLocation.Dist2D(StartLocation);
		float Width = 400.0;

		DamageTrigger.SetWorldLocationAndRotation(CenterLocation, FRotator::MakeFromX(ActorLocation - StartLocation));
		DamageTrigger.ChangeShape(
			FHazeShapeSettings::MakeBox(FVector(Length * 0.5, Width * 0.5, 20))
		);
	}
}
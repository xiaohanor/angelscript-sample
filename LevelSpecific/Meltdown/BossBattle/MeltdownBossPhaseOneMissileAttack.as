event void FOnMeltdownMissileHit();
event void FOnMeltdownMissileLaunched();

enum EMeltdownBossPhaseOneMissileAttackType
{
	Shockwave,
	Explosion,
}

class AMeltdownBossPhaseOneMissileAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent, Attach = "ProjectileRoot")
	UStaticMeshComponent ProjectileMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UMeltdownBossCubeGridDisplacementComponent TelegraphDisplacement;
	default TelegraphDisplacement.Type = EMeltdownBossCubeGridDisplacementType::Shape;
	default TelegraphDisplacement.Shape = FHazeShapeSettings::MakeBox(FVector(150.0, 150.0, 500.0));

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float Speed = 8000;
	UPROPERTY(EditAnywhere, Category = "Missile Projectile")
	float Gravity = 2000;

	UPROPERTY(EditAnywhere, Category = "Attack")
	EMeltdownBossPhaseOneMissileAttackType AttackType = EMeltdownBossPhaseOneMissileAttackType::Shockwave;

	UPROPERTY(EditAnywhere, Category = "Attack", Meta = (EditCondition = "AttackType == EMeltdownBossPhaseOneMissileAttackType::Shockwave", EditConditionHides))
	float ShockwaveSpeed = 500.0;
	UPROPERTY(EditAnywhere, Category = "Attack", Meta = (EditCondition = "AttackType == EMeltdownBossPhaseOneMissileAttackType::Shockwave", EditConditionHides))
	float ShockwaveMaxRadius = 3000.0;
	UPROPERTY(EditAnywhere, Category = "Attack", Meta = (EditCondition = "AttackType == EMeltdownBossPhaseOneMissileAttackType::Shockwave", EditConditionHides))
	FVector ShockwaveDisplacement = FVector(0, 0, 100);
	UPROPERTY(EditAnywhere, Category = "Attack", Meta = (EditCondition = "AttackType == EMeltdownBossPhaseOneMissileAttackType::Shockwave", EditConditionHides))
	float ShockwaveWidth = 100.0;
	UPROPERTY(EditAnywhere, Category = "Attack", Meta = (EditCondition = "AttackType == EMeltdownBossPhaseOneMissileAttackType::Shockwave", EditConditionHides))
	float ShockwaveKillHeight = 100.0;

	UPROPERTY(EditAnywhere, Category = "Attack", Meta = (EditCondition = "AttackType == EMeltdownBossPhaseOneMissileAttackType::Explosion", EditConditionHides))
	float ExplosionRadius = 300.0;
	UPROPERTY(EditAnywhere, Category = "Attack", Meta = (EditCondition = "AttackType == EMeltdownBossPhaseOneMissileAttackType::Explosion", EditConditionHides))
	float ExplosionDuration = 0.3;
	UPROPERTY(EditAnywhere, Category = "Attack", Meta = (EditCondition = "AttackType == EMeltdownBossPhaseOneMissileAttackType::Shockwave", EditConditionHides))
	FVector ExplosionDisplacement = FVector(0, 0, 400);

	UPROPERTY()
	FOnMeltdownMissileLaunched MissileLaunched;

	UPROPERTY()
	FOnMeltdownMissileHit MissileHit;

	UPROPERTY(EditAnywhere, Category = "Trigger")
	float StartDelay = 0.0;
	UPROPERTY(EditAnywhere, Category = "Trigger")
	float ResetDelay = 10.0;

	bool bFired = false;
	bool bImpacted = false;

	FVector InitialLocation;
	FVector InitialVelocity;
	float FireDuration;
	float FireTimer;
	AMeltdownBossPhaseOneShockwave Shockwave;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TelegraphDisplacement.DeactivateDisplacement();
		ProjectileRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFired)
		{
			UpdateProjectileLocation(DeltaSeconds);
			UpdateTelegraphDisplacement(DeltaSeconds);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		TelegraphDisplacement.DeactivateDisplacement();
		if (Shockwave != nullptr)
		{
			Shockwave.DestroyActor();
			Shockwave = nullptr;
		}
	}

	UFUNCTION(DevFunction)
	void FireMissile()
	{
		MissileLaunched.Broadcast();
		bFired = true;
		bImpacted = false;

		ProjectileRoot.SetHiddenInGame(false, true);

		TelegraphDisplacement.ActivateDisplacement();

		FMeltdownBossPhaseOneMissileThrowParams ThrowParams;
		ThrowParams.MissileLocation = ProjectileRoot.WorldLocation;
		ThrowParams.TargetLocation = TelegraphRoot.WorldLocation;

		Trajectory::FOutCalculateVelocity Trajectory = Trajectory::CalculateParamsForPathWithHorizontalSpeed(
			ProjectileRoot.WorldLocation, TelegraphRoot.WorldLocation, Gravity, Speed
		);

		InitialLocation = ProjectileRoot.WorldLocation;
		InitialVelocity = Trajectory.Velocity;

		FireDuration = Trajectory.Time;
		FireTimer = 0;

		UMeltdownBossPhaseOneMissileAttackEffectHandler::Trigger_ThrowMissile(this, ThrowParams);

		BP_FireMissile();
	}

	UFUNCTION(BlueprintEvent)
	void BP_FireMissile() {}

	UFUNCTION(DevFunction)
	void MissileImpact()
	{
		MissileHit.Broadcast();

		bFired = false;
		bImpacted = true;

		ProjectileRoot.SetHiddenInGame(true, true);

		TelegraphDisplacement.DeactivateDisplacement();

		FMeltdownBossPhaseOneMissileHitParams HitParams;
		HitParams.HitLocation = TelegraphRoot.WorldLocation;
		UMeltdownBossPhaseOneMissileAttackEffectHandler::Trigger_MissileHit(this, HitParams);

		BP_MissileImpact();

		if (AttackType == EMeltdownBossPhaseOneMissileAttackType::Shockwave)
		{
			Shockwave = AMeltdownBossPhaseOneShockwave::Spawn(
				TelegraphRoot.WorldLocation
			);
			Shockwave.Speed = ShockwaveSpeed;
			Shockwave.MaxRadius = ShockwaveMaxRadius;
			Shockwave.Displacement = ShockwaveDisplacement;
			Shockwave.Width = ShockwaveWidth;
			Shockwave.bAutoDestroy = true;
			Shockwave.ActivateShockwave();
		}
		else if (AttackType == EMeltdownBossPhaseOneMissileAttackType::Explosion)
		{
			auto Explosion = AMeltdownBossPhaseOneExplosion::Spawn(
				TelegraphRoot.WorldLocation
			);
			Explosion.Duration = ExplosionDuration;
			Explosion.Radius = ExplosionRadius;
			Explosion.Displacement = ExplosionDisplacement;
			Explosion.bAutoDestroy = true;
			Explosion.ActivateExplosion();
		}

		// Kill any player in the telegraphed area
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			if (TelegraphDisplacement.Shape.IsPointInside(
					TelegraphDisplacement.WorldTransform,
					Player.ActorLocation))
			{
				Player.DamagePlayerHealth(1.0);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_MissileImpact() {}

	void UpdateProjectileLocation(float DeltaTime)
	{
		FireTimer += DeltaTime;

		FVector StepVelocity = InitialVelocity - FVector(0, 0, Gravity) * FireTimer;
		FVector StepLocation = InitialLocation + InitialVelocity * FireTimer - FVector(0, 0, Gravity) * Math::Square(FireTimer) * 0.5;

		ProjectileRoot.SetWorldLocationAndRotation(
			StepLocation, FRotator::MakeFromX(StepVelocity)
		);

		if (FireTimer >= FireDuration)
			MissileImpact();
	}

	void UpdateTelegraphDisplacement(float DeltaTime)
	{
		float TelegraphPct = FireTimer / FireDuration;
		TelegraphDisplacement.Displacement = FVector(0.0, 0.0, Math::Sin(Time::GameTimeSeconds * 25.0) * 40.0 + 100.0 * TelegraphPct);
		TelegraphDisplacement.Redness = -TelegraphPct;
	}


	float IncomingAlpha()
	{
		if(FireDuration != 0)
			return FireTimer / FireDuration;
		return 0;
	}

};

struct FMeltdownBossPhaseOneMissileSpawnParams
{
	UPROPERTY()
	FVector MissileLocation;
	UPROPERTY()
	FVector TargetLocation;
}

struct FMeltdownBossPhaseOneMissileThrowParams
{
	UPROPERTY()
	FVector MissileLocation;
	UPROPERTY()
	FVector TargetLocation;
}

struct FMeltdownBossPhaseOneMissileHitParams
{
	UPROPERTY()
	FVector HitLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseOneMissileAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnMissile(FMeltdownBossPhaseOneMissileSpawnParams SpawnParams) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowMissile(FMeltdownBossPhaseOneMissileThrowParams ThrowParams) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MissileHit(FMeltdownBossPhaseOneMissileHitParams HitParams) {}
}
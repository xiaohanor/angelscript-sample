
enum EStoneBeastWeakpointState
{
	Default,
	BrokenOne,
	BrokenTwo,
	BrokenThree,
}

class AStoneBossWeakpoint : AHazeActor
{
	EStoneBeastWeakpointState BrokenState;

	UPROPERTY()
	FOnStoneBossWeakpointDestroyed OnStoneBossWeakpointDestroyed;

	UPROPERTY()
	FOnStoneBossWeakpointDamaged OnStoneBossWeakPointDamaged;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CoreMesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BlockingCrystals1;
	default BlockingCrystals1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BlockingCrystals2;
	default BlockingCrystals2.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BlockingCrystals3;
	default BlockingCrystals3.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UDragonSwordCombatTargetComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent SwordResponseComp;
	default SwordResponseComp.ResponseDetailLevel = EDragonSwordResponseDetailLevel::Full;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> HitCameraShake;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> DestroyedCameraShake;

	UPROPERTY(EditAnywhere)
	bool bCheckRuptureCollectives = false;

	UPROPERTY(EditAnywhere)
	float PlayerDamage = 0.03;
	float SinglePlayerDamageMultiplier = 0.55;
	float DoubleDamageThresholdTime = 1.2;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ExplosionRadiusCurve;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh BrokenMesh1;
	UPROPERTY(EditDefaultsOnly)
	UStaticMesh BrokenMesh2;
	UPROPERTY(EditDefaultsOnly)
	UStaticMesh BrokenMesh3;

	UPROPERTY(DefaultComponent)
	UHealthBarInWorldComponent HealthBarComp;

	bool bWeakpointEnabled = false;

	float WeakpointHealth = 1.0;
	float WeakpointDamagePointIntervals;

	TPerPlayer<float> TimeSinceLastHit;
	AStoneBeastHealthManager StoneBeastHealthManager;

	UPROPERTY()
	UMaterialParameterCollection GlobalParameters;

	TArray<AActor> AttachedActors;
	TArray<ACrystalSpikeCollectiveExplosionActor> RuptureCollectiveExplosions;

	float ExplosionRadius = 50;

	float CurveMaxTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StoneBeastHealthManager = TListedActors<AStoneBeastHealthManager>().GetSingle();
		SwordResponseComp.OnHit.AddUFunction(this, n"OnHit");
		EnableWeakpoint();
		GetAttachedActors(AttachedActors);

		RuptureCollectiveExplosions = TListedActors<ACrystalSpikeCollectiveExplosionActor>().GetArray();
	}

	UFUNCTION()
	private void OnHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		if (!bWeakpointEnabled)
			return;

		auto CurrentPlayer = Cast<AHazePlayerCharacter>(Instigator);
		TimeSinceLastHit[CurrentPlayer] = Time::GameTimeSeconds;

		float CurrentDamage = PlayerDamage;

		if (TimeSinceLastHit[CurrentPlayer] - TimeSinceLastHit[CurrentPlayer.OtherPlayer] > DoubleDamageThresholdTime)
		{
			CurrentDamage = PlayerDamage * SinglePlayerDamageMultiplier;
		}

		WeakpointHealth -= CurrentDamage;
		float RemainingDamage = 0.0;
		if (WeakpointHealth < 0.0)
			RemainingDamage -= WeakpointHealth;

		if (WeakpointHealth < 0.25 && BrokenState != EStoneBeastWeakpointState::BrokenThree)
		{
			BrokenState = EStoneBeastWeakpointState::BrokenThree;
			CoreMesh.SetStaticMesh(BrokenMesh3);
			UStoneBossWeakpointEffectHandler::Trigger_OnDamaged(this, FStoneBossWeakpointDamagedParams(3));
		}
		else if (WeakpointHealth <= 0.5 && WeakpointHealth > 0.25 && BrokenState != EStoneBeastWeakpointState::BrokenTwo)
		{
			BrokenState = EStoneBeastWeakpointState::BrokenTwo;
			CoreMesh.SetStaticMesh(BrokenMesh2);
			UStoneBossWeakpointEffectHandler::Trigger_OnDamaged(this, FStoneBossWeakpointDamagedParams(2));
		}
		else if (WeakpointHealth <= 0.8 && WeakpointHealth > 0.5 && BrokenState != EStoneBeastWeakpointState::BrokenOne)
		{
			BrokenState = EStoneBeastWeakpointState::BrokenOne;
			CoreMesh.SetStaticMesh(BrokenMesh1);
			UStoneBossWeakpointEffectHandler::Trigger_OnDamaged(this, FStoneBossWeakpointDamagedParams(1));
		}

		HealthBarComp.CurrentHealth = WeakpointHealth;

		CurrentDamage -= RemainingDamage;

		// StoneBeastHealthManager.DamageStoneBeast(CurrentDamage * StoneBeastHealthManager.MaxStoneBeastHealth);

		FStoneBossWeakpointHitParams Params;
		Params.Location = HitData.ImpactPoint;
		Params.Normal = HitData.ImpactNormal;
		//Debug::DrawDebugSphere(HitData.ImpactPoint, 50.0, 12, FLinearColor::Red, 5.0, 1.0);
		//Debug::DrawDebugDirectionArrow(HitData.ImpactPoint, HitData.ImpactNormal, 200.0, 20, FLinearColor::Blue, 5.0, 1.0);
		UStoneBossWeakpointEffectHandler::Trigger_OnHit(this, Params);

		BP_OnWeakpointDamaged(WeakpointHealth * StoneBeastHealthManager.MaxStoneBeastHealth);

		OnStoneBossWeakPointDamaged.Broadcast(WeakpointHealth * StoneBeastHealthManager.MaxStoneBeastHealth);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayCameraShake(HitCameraShake, this, 1.0);

		if (WeakpointHealth <= 0.0 && HasControl())
		{
			CrumbDestroyWeakpoint();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnWeakpointDamaged(float RemainingHealth) {}

	UFUNCTION(DevFunction, CrumbFunction)
	void CrumbDestroyWeakpoint()
	{
		StoneBeastHealthManager.DamageStoneBeast(0.25 * StoneBeastHealthManager.MaxStoneBeastHealth);
		bWeakpointEnabled = false;

		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayCameraShake(DestroyedCameraShake, this);

		float _;
		ExplosionRadiusCurve.GetTimeRange(_, CurveMaxTime);
		FStoneBossWeakpointDestroyedParams Params;
		Params.Location = ActorLocation;
		OnStoneBossWeakpointDestroyed.Broadcast();
		OnWeakpointDestroyed();
		UStoneBossWeakpointEffectHandler::Trigger_OnDestroyed(this, Params);

		ActionQueueComp.Duration(CurveMaxTime, this, n"ScaleExplosion");
		ActionQueueComp.Event(this, n"FinishExplosion");
		ActionQueueComp.Duration(0.5, this, n"KillRemainingCritters");
		HealthBarComp.SetHealthBarEnabled(false);
		for (AActor Actor : AttachedActors)
		{
			Actor.AddActorDisable(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnWeakpointDestroyed() {};

	// UFUNCTION()
	// private void Disable()
	// {
	// 	AddActorDisable(this);
	// }

	UFUNCTION()
	private void KillRemainingCritters(float Alpha)
	{
		FHazeTraceSettings OverlapSettings;
		OverlapSettings.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);
		OverlapSettings.IgnoreActors(Game::Players);
		OverlapSettings.UseSphereShape(ExplosionRadius);

		auto Overlaps = OverlapSettings.QueryOverlaps(ActorLocation);
		for (auto Overlap : Overlaps)
		{
			auto Critter = Cast<AAISummitStoneBeastCritter>(Overlap.Actor);
			if (Critter != nullptr && !Critter.HealthComp.IsDying())
			{
				Damage::AITakeDamage(Critter, 100, this);
			}
		}
	}

	UFUNCTION()
	private void FinishExplosion()
	{
		ActionQueueComp.Empty();
	}

	UFUNCTION()
	void ScaleExplosion(float Alpha)
	{
		float CurveTime = Alpha * CurveMaxTime;
		ExplosionRadius = Math::Max(KINDA_SMALL_NUMBER, ExplosionRadiusCurve.GetFloatValue(CurveTime));
		FVector Location = ActorLocation;
		Material::SetVectorParameterValue(GlobalParameters, n"StoneBeastEmissiveSphere", FLinearColor(Location.X, Location.Y, Location.Z, ExplosionRadius));
		FHazeTraceSettings OverlapSettings;
		OverlapSettings.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);
		OverlapSettings.IgnoreActors(Game::Players);
		OverlapSettings.UseSphereShape(ExplosionRadius);

		auto Overlaps = OverlapSettings.QueryOverlaps(ActorLocation);
		for (auto Overlap : Overlaps)
		{
			auto Critter = Cast<AAISummitStoneBeastCritter>(Overlap.Actor);
			if (Critter != nullptr && !Critter.HealthComp.IsDying())
			{
				Damage::AITakeDamage(Critter, 100, this);
			}
		}

		if (bCheckRuptureCollectives)
		{
			for (ACrystalSpikeCollectiveExplosionActor RuptureCollective : RuptureCollectiveExplosions)
			{
				if (!RuptureCollective.bWasActivated && RuptureCollective.GetDistanceTo(this) < ExplosionRadius)
					RuptureCollective.DestroyRuptureCollective();
			}
		}
	}

	void ClearVeinEffect()
	{
		Material::SetVectorParameterValue(GlobalParameters, n"StoneBeastEmissiveSphere", FLinearColor::Transparent);
	}

	void EnableWeakpoint()
	{
		bWeakpointEnabled = true;
	}
};
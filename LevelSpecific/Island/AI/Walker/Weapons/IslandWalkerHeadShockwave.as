UCLASS(Abstract)
class AIslandWalkerHeadShockwave : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Effect;

	UIslandWalkerSettings Settings;
	float Radius;
	float StartExpiringTime = BIG_NUMBER;

	AHazeActor WalkerHead;

	TArray<AHazePlayerCharacter> AvailableTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StopShockwave();
		Settings = UIslandWalkerSettings::GetSettings(WalkerHead);
	}

	void StartShockwave(FVector Location)
	{
		SetActorLocation(Location);
		Radius = Settings.HeadCrashAttackStartRadius;
		Root.SetWorldScale3D(GetCurrentScale());
		Mesh.SetRelativeLocation(FVector(0.0, 0.0, Root.WorldScale.Z * 1.8));

		Mesh.RemoveComponentVisualsBlocker(this);
		Effect.RemoveComponentVisualsBlocker(this);
		Effect.Activate();
		SetActorTickEnabled(true);	
		AvailableTargets = Game::Players;	

		// Immediately kill any players inside the shockwave (i.e. beneath the walker)
		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			if(!AvailableTargets[i].ActorLocation.IsWithinDist2D(ActorLocation, Radius))
				continue;
			if (AvailableTargets[i].ActorLocation.Z > ActorLocation.Z + Settings.HeadCrashAttackWaveHeight)
				continue;
			AvailableTargets[i].DealTypedDamage(WalkerHead, 1.0, EDamageEffectType::Explosion, EDeathEffectType::Explosion, false);
			UPlayerDamageEventHandler::Trigger_TakeBigDamage(AvailableTargets[i]);
			AvailableTargets.RemoveAt(i);
		}

		StartExpiringTime = BIG_NUMBER;
	}	

	void StopShockwave()
	{
		Effect.Deactivate();
		StartExpiringTime = Time::GameTimeSeconds;
	}

	void Expire()
	{
		Mesh.AddComponentVisualsBlocker(this);
		Effect.AddComponentVisualsBlocker(this); 
		SetActorTickEnabled(false);		
	}

	FVector GetCurrentScale()
	{
		FVector Scale = FVector(Radius * 0.01);
		Scale.Z = Settings.HeadCrashAttackWaveHeight * 0.06;

		float CurTime = Time::GameTimeSeconds;
		if (CurTime > StartExpiringTime)
			Scale.Z *= 1.0 - Math::Clamp(((Time::GameTimeSeconds - StartExpiringTime) / Math::Max(0.01, (Settings.HeadCrashAttackWaveExpirationDelay - 0.01))), 0.01, 1.0);

		return Scale;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Radius += Settings.HeadCrashAttackSpeed * DeltaTime;		
		Root.SetWorldScale3D(GetCurrentScale());

		if (Time::GameTimeSeconds > StartExpiringTime + Settings.HeadCrashAttackWaveExpirationDelay)
			Expire();
		if (Time::GameTimeSeconds > StartExpiringTime)
			return;

		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = AvailableTargets[i];
			if (!Player.HasControl())
				continue;
			if (!Player.ActorLocation.IsWithinDist2D(ActorLocation, Radius))
				continue;
			if (Player.ActorLocation.IsWithinDist2D(ActorLocation, Radius - Settings.HeadCrashAttackWaveWidth))
				continue;
			if (Player.ActorLocation.Z > ActorLocation.Z + Settings.HeadCrashAttackWaveHeight)
				continue;
			if (Player.IsAnyCapabilityActive(PlayerGrappleTags::GrappleEnter))
				continue; // Never hit while grappling to head
			CrumbHitPlayer(Player);		
		}

		if (Radius > Settings.HeadCrashAttackEndRadius)
			StopShockwave();
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player)
	{
		FKnockdown Knockdown;
		FVector Dir = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		Dir = Dir * 0.9 + FVector::UpVector * 0.1;
		Knockdown.Move = Dir * Settings.HeadCrashAttackKnockbackForce;
		Knockdown.Duration = Settings.HeadCrashAttackKnockbackDuration;
		Player.ApplyKnockdown(Knockdown);
		
		// Deal damage, but don't kill player unless they're very hurt already
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
		float Damage = Settings.HeadCrashAttackDamage;
		if ((HealthComp.Health.CurrentHealth > 0.1) && (HealthComp.Health.CurrentHealth < Damage))
			Damage = HealthComp.Health.CurrentHealth * 0.9;
		Player.DealTypedDamage(WalkerHead, Damage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
		UPlayerDamageEventHandler::Trigger_TakeBigDamage(Player);

		AvailableTargets.RemoveSingle(Player);
	}
}

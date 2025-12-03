UCLASS(Abstract)
class AIslandWalkerShockwave : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Effect;

	AHazeActor Instigator;
	UIslandWalkerSettings Settings;
	float Radius;
	TArray<AHazePlayerCharacter> AvailableTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StopShockwave();
		Settings = UIslandWalkerSettings::GetSettings(Instigator);
	}

	void StartShockwave(FVector Location)
	{
		SetActorLocation(Location);
		Radius = Settings.JumpAttackRadius;
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
			if(!AvailableTargets[i].ActorLocation.IsWithinDist(ActorLocation, Radius))
				continue;
			AvailableTargets[i].DealTypedDamage(Instigator, 1.0, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
			UPlayerDamageEventHandler::Trigger_TakeBigDamage(AvailableTargets[i]);
			AvailableTargets.RemoveAt(i);
		}
	}	

	void StopShockwave()
	{
		Mesh.AddComponentVisualsBlocker(this);
		Effect.Deactivate();
		Effect.AddComponentVisualsBlocker(this); // TODO: Delay this to allow effect to dissipate		
		SetActorTickEnabled(false);		
	}

	FVector GetCurrentScale()
	{
		FVector Scale = FVector(Radius * 0.01);
		Scale.Z = Settings.JumpAttackShockwaveHeight * 0.06;
		return Scale;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Radius += Settings.JumpAttackShockwaveSpeed * DeltaTime;		
		Root.SetWorldScale3D(GetCurrentScale());

		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = AvailableTargets[i];
			if (!Player.HasControl())
				continue;
			if(!Player.ActorLocation.IsWithinDist2D(ActorLocation, Radius))
				continue;
			if(Player.ActorLocation.IsWithinDist2D(ActorLocation, Radius - Settings.JumpAttackShockwaveWidth))
				continue;
			if(Player.ActorLocation.Z > ActorLocation.Z + Settings.JumpAttackShockwaveHeight)
				continue;
			CrumbHitPlayer(Player);		
		}

		if (Radius > Settings.JumpAttackShockwaveStopRadius)
			StopShockwave();
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player)
	{
		FKnockdown Knockdown;
		FVector Dir = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		Dir = Dir * 0.9 + FVector::UpVector * 0.1;
		Knockdown.Move = Dir * Settings.JumpAttackShockwaveKnockbackForce;
		Knockdown.Duration = Settings.JumpAttackShockwaveKnockbackDuration;
		Player.ApplyKnockdown(Knockdown);
		
		// Deal damage, but don't kill player unless they're very hurt already
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
		float Damage = Settings.JumpAttackShockwaveDamage;
		if ((HealthComp.Health.CurrentHealth > 0.1) && (HealthComp.Health.CurrentHealth < Damage))
			Damage = HealthComp.Health.CurrentHealth * 0.9;
		HealthComp.DamagePlayer(Damage, nullptr, nullptr);
		UPlayerDamageEventHandler::Trigger_TakeBigDamage(Player);

		AvailableTargets.RemoveSingle(Player);
	}
}

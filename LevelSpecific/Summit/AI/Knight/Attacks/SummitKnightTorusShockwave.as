struct FKnightTorusShockwaveSettings
{
	float StartRadius = 500.0;
	float EndRadius = 5000.0;
	float ExpansionSpeed = 1000.0;
	float Damage = 0.8;
	float DamageHeight = 100.0;
	float DamageWidth = 200.0;
	float StumbleForce = 2000.0;
	float ExpirationDelay = 5.0;
}

UCLASS(Abstract)
class ASummitKnightTorusShockwave : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Effect;

	FKnightTorusShockwaveSettings Settings;
	float Radius;
	float StartExpiringTime = BIG_NUMBER;

	USummitKnightComponent KnightComp;
	AHazeActor Instigator;
	bool bWasStarted = false;

	TArray<AHazePlayerCharacter> AvailableTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.AddComponentVisualsBlocker(this);
		Effect.AddComponentVisualsBlocker(this); 
	}

	void StartShockwave(USummitKnightComponent Knight, FVector Location, FKnightTorusShockwaveSettings ShockwaveSettings)
	{
		if (HasControl())
			CrumbStartShockwave(Knight, Location, ShockwaveSettings);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartShockwave(USummitKnightComponent Knight, FVector Location, FKnightTorusShockwaveSettings ShockwaveSettings)
	{
		bWasStarted = true;
		KnightComp = Knight;
		Instigator = Cast<AHazeActor>(Knight.Owner);
		Settings = ShockwaveSettings;
		SetActorLocation(Location);
		Radius = Settings.StartRadius;
		Root.SetWorldScale3D(GetCurrentScale());
		Mesh.SetRelativeLocation(FVector(0.0, 0.0, Root.WorldScale.Z * 3));

		Mesh.RemoveComponentVisualsBlocker(this);
		Effect.RemoveComponentVisualsBlocker(this);
		Effect.Activate();
		SetActorTickEnabled(true);	
		AvailableTargets = Game::Players;	

		// Immediately kill any players inside the shockwave
		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			if(!AvailableTargets[i].ActorLocation.IsWithinDist(ActorLocation, Radius))
				continue;
			AvailableTargets[i].DealTypedDamage(Instigator, 1.0, EDamageEffectType::Explosion, EDeathEffectType::Explosion, false);
			UPlayerDamageEventHandler::Trigger_TakeBigDamage(AvailableTargets[i]);
			USummitKnightEventHandler::Trigger_OnSlamShockwaveHit(Instigator, FSummitKnightPlayerParams(AvailableTargets[i]));
			AvailableTargets.RemoveAt(i);
		}

		StartExpiringTime = BIG_NUMBER;
	}	

	void StopShockwave()
	{
		Effect.Deactivate();
		StartExpiringTime = Time::GameTimeSeconds;
		Mesh.AddComponentVisualsBlocker(this);
	}

	bool IsExpiring()
	{
		if (Time::GameTimeSeconds > StartExpiringTime)
			return true;
		return false;
	}

	void Expire()
	{
		Effect.AddComponentVisualsBlocker(this); 
		SetActorTickEnabled(false);		
	}

	FVector GetCurrentScale()
	{
		FVector Scale = FVector(Radius * 0.01);
		Scale.Z = Settings.DamageHeight * 0.06;
		return Scale;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Radius += Settings.ExpansionSpeed * DeltaTime;		
		Root.SetWorldScale3D(GetCurrentScale());

		if (Time::GameTimeSeconds > StartExpiringTime + Settings.ExpirationDelay)
			Expire();
		if (Time::GameTimeSeconds > StartExpiringTime)
			return;

		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = AvailableTargets[i];
			if (!Player.HasControl())
				continue;
			if(!Player.ActorLocation.IsWithinDist2D(ActorLocation, Radius))
				continue;
			if(Player.ActorLocation.IsWithinDist2D(ActorLocation, Radius - Settings.DamageWidth))
				continue;
			if(Player.ActorLocation.Z > ActorLocation.Z + Settings.DamageHeight)
				continue;
			CrumbHitPlayer(Player);		
		}

		if (Radius > Settings.EndRadius)
			StopShockwave();
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player)
	{
		FVector Dir = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		Dir = Dir * 0.9 + FVector::UpVector * 0.1;
		KnightComp.StumbleDragon(Player, Dir * Settings.StumbleForce, 0.0, 1.0, 200.0);
		
		// Deal damage, but don't kill player unless they're very hurt already
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
		float Damage = Settings.Damage;
		if ((HealthComp.Health.CurrentHealth > 0.1) && (HealthComp.Health.CurrentHealth < Damage))
			Damage = HealthComp.Health.CurrentHealth * 0.9;
		HealthComp.DamagePlayer(Damage, nullptr, nullptr);
		UPlayerDamageEventHandler::Trigger_TakeBigDamage(Player);
		USummitKnightEventHandler::Trigger_OnSlamShockwaveHit(Instigator, FSummitKnightPlayerParams(Player));

		AvailableTargets.RemoveSingle(Player);
	}

	bool HitAnything() const
	{
		if (!bWasStarted)
			return false;
		if (AvailableTargets.Num() == Game::Players.Num())
			return false;
		return true;
	}
}

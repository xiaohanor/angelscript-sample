event void FBallBossShockwaveManagerDeactivated();

class ASkylineBallBossShockwaveManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float BallBossRadius = 1000.0;

	UPROPERTY(EditAnywhere)
	float SpawnInterval = 0.5;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossShockwave> ShockwaveClass;

	UPROPERTY()
	float Damage = 0.3;

	UPROPERTY()
	float DamageInterval = 0.5;

	UPROPERTY()
	UNiagaraSystem PlayerImpactVFXSystem;

	ASkylineBallBoss BallBoss;

	TPerPlayer<float> LastTimeHitPlayer;

	FBallBossShockwaveManagerDeactivated OnDeactivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BallBoss = Cast<ASkylineBallBoss>(AttachParentActor);

		//BallBoss.OnMioReachedOutside.AddUFunction(this, n"Activate");
		//BallBoss.OnMioReachedInside.AddUFunction(this, n"Deactivate");
		BallBoss.OnPhaseChanged.AddUFunction(this, n"HandleStateChanged");

		SetActorControlSide(Game::Mio);
	}

	UFUNCTION()
	private void HandleStateChanged(ESkylineBallBossPhase NewPhase)
	{
		if (NewPhase >= ESkylineBallBossPhase::TopMioOnEyeBroken || NewPhase == ESkylineBallBossPhase::TopShieldShockwave)
			Deactivate();
	}

	void DamagePlayer(AHazePlayerCharacter Player)
	{
		if (Time::GetGameTimeSince(LastTimeHitPlayer[Player]) > DamageInterval)
		{
			LastTimeHitPlayer[Player] = Time::GameTimeSeconds;

			auto MoveComp = UPlayerMovementComponent::Get(Player);

			Player.DamagePlayerHealth(Damage);
			//Niagara::SpawnOneShotNiagaraSystemAtLocation(PlayerImpactVFXSystem, 
			//												MoveComp.GroundContact.Location,
			//												MoveComp.GroundContact.ImpactNormal.Rotation());											
		}
	}

	UFUNCTION()
	void Activate()
	{
		Timer::SetTimer(this, n"SpawnShockwave", SpawnInterval, true, 0.5);
	}

	UFUNCTION()
	void SpawnShockwave()
	{
		if (BallBoss.GetPhase() >= ESkylineBallBossPhase::TopMioOnEyeBroken || BallBoss.GetPhase() == ESkylineBallBossPhase::TopShieldShockwave)
		{
			Deactivate();
			return;
		}

		FVector SpawnLocation = (Math::GetRandomPointOnSphere() * BallBossRadius) + BallBoss.ActorLocation;
		FRotator SpawnRotation = (SpawnLocation - BallBoss.ActorLocation).Rotation();

		if (HasControl())
			CrumbSpawnShockwave(SpawnLocation, SpawnRotation);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnShockwave(FVector Location, FRotator Rotation)
	{
		auto SpawnedActor = SpawnActor(ShockwaveClass, Location, Rotation);
		SpawnedActor.AttachToActor(BallBoss, NAME_None, EAttachmentRule::KeepWorld);
		SpawnedActor.BallBossRadius = BallBossRadius;
		SpawnedActor.BallBoss = BallBoss;
		OnDeactivated.AddUFunction(SpawnedActor, n"Deactivate");
	}

	UFUNCTION()
	void Deactivate()
	{
		Timer::ClearTimer(this, n"SpawnShockwave");
		OnDeactivated.Broadcast();
	}
};
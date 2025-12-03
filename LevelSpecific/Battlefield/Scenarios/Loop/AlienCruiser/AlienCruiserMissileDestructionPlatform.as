event void FOnAlienCruiserPlatformDestroyed();

class AAlienCruiserMissileDestructionPlatform : AHazeActor
{
	UPROPERTY()
	FOnAlienCruiserPlatformDestroyed OnAlienCruiserPlatformDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent IceExplosionSystem;
	default IceExplosionSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CollisionBox;
	default	CollisionBox.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UAlienCruiserMissileResponseComponent MissileResponseComp;
	
	/** How many impacts before it breaks */
	UPROPERTY(EditAnywhere, Category = "Settings")
	int PlatformStartHealth = 4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDebug = false;

	int CurrentHealth;

	const float PlayerTraceLength = 4000.0;
	const float LeftRightGrindFindOffsetLength = 10000.0;

	AAlienCruiser Cruiser;

	ABattlefieldSlowMoGrappleManager GrappleManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentHealth = PlatformStartHealth;
		MissileResponseComp.OnMissileExploded.AddUFunction(this, n"OnMissileExploded");

		Cruiser = TListedActors<AAlienCruiser>().GetSingle();

		OnActorBeginOverlap.AddUFunction(this, n"BeginOverlap");

		GrappleManager = TListedActors<ABattlefieldSlowMoGrappleManager>().GetSingle();
	}

	UFUNCTION(NotBlueprintCallable)
	private void BeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		if (IsActorDisabled())
			return;
		
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(!Cruiser.HasBeenLaunched[Player])
			LaunchPlayer(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMissileExploded(FAlienCruiserMissileExplosionResponseParams Params)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if(Cruiser.HasBeenLaunched[Player])
				continue;

			float PlayerDot = Player.ActorLocation.DotProduct(ActorForwardVector);
			float MissileDot = Params.MissileLocationAtImpact.DotProduct(ActorForwardVector);
			if (PlayerDot > MissileDot - 200) 
				LaunchPlayer(Player);
		}
		
		CurrentHealth--;

		if(CurrentHealth <= 0)
		{
			DestroyPlatform();
			OnAlienCruiserPlatformDestroyed.Broadcast();
		}
	}

	void DestroyPlatform()
	{
		AddActorVisualsBlock(this);
		PlatformMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CollisionBox.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
		IceExplosionSystem.Activate();
		UAlienCruiserDestructionPlatformEventHandler::Trigger_OnPlatformDestroyed(this);
	}

	FVector GetImpulseRight(AHazePlayerCharacter Player)
	{
		FVector DeltaOffset = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector);
		DeltaOffset = DeltaOffset.ConstrainToDirection(ActorRightVector);
		float Dot = DeltaOffset.DotProduct(-ActorRightVector);
		float ImpulseForce = (DeltaOffset.Size() / 230.0) * Dot;

		if (Player.IsMio())
			ImpulseForce = Math::Clamp(ImpulseForce, 250.0, 2000.0);
		else if (Player.IsZoe())
			ImpulseForce = Math::Clamp(ImpulseForce, -2000.0, -250.0);

		return Player.ActorRightVector * ImpulseForce; 
	}

	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		GrappleManager.PlayerLaunched(Player);
		FVector NewImpulse = FVector(0,0,4200.0);
		NewImpulse += GrappleManager.ActorForwardVector * 700.0;

		NewImpulse += GetImpulseRight(Player); 

		Player.AddMovementImpulse(NewImpulse, n"Forced");
		Cruiser.HasBeenLaunched[Player] = true;
	}
};
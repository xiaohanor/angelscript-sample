enum ESummitStoneBeastZapperLightningCrystalState
{
	Moving,			// Towards target
	Telegraphing, 	// Looking dangerous, no movement
	Activated,		// Time to strike
	None,			// Void
}

class ASummitStoneBeastZapperLightningCrystalActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UDecalComponent DecalComp;
	default DecalComp.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFXTemp;

	// Reference to owner's spawn pool
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;

	USummitStoneBeastZapperSettings Settings;

	AAISummitStoneBeastZapper ZapperOwner;

	AHazeActor TargetActor;

	FVector StraightPathLocation;
	FVector MoveDir;
	FVector InitialDir;
	FVector DesiredDir;

	private float SpawnTime;
	private float ActivationTime;
	private float TelegraphTimer;
	private FVector DefaultScale; // Default scale specified in actor BP
	private FVector DefaultDecalScale;	
	private float Speed;

	private bool bHasMadeImpact = false;

	FHazeAcceleratedFloat AccelFloat;

	ESummitStoneBeastZapperLightningCrystalState State = ESummitStoneBeastZapperLightningCrystalState::None;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		Mesh.SetHiddenInGame(true);
		DecalComp.SetHiddenInGame(true);
		DefaultScale = Mesh.GetRelativeScale3D();
		Mesh.SetRelativeScale3D(DefaultScale);
		DefaultDecalScale = DecalComp.GetRelativeScale3D();		
		AccelFloat.SnapTo(0.5);		
	}
	
	UFUNCTION()
	private void OnRespawn()
	{	
		State = ESummitStoneBeastZapperLightningCrystalState::Moving;

		SpawnTime = Time::GameTimeSeconds;		
		Mesh.SetHiddenInGame(true);
		Mesh.SetRelativeScale3D(DefaultScale);
		Mesh.SetRelativeLocation(FVector::ZeroVector);
		
		DecalComp.SetHiddenInGame(false);
		VFXTemp.SetHiddenInGame(false);
		VFXTemp.SetFloatParameter(n"ColorStrength", 0.1);

		DecalComp.SetRelativeScale3D(FVector(0.1, 0.1, 0.1));
		bHasMadeImpact = false;
		if(IsActorDisabled())
			RemoveActorDisable(this);
	}
	
	// Get launching Zapper's specific settings and spawnpool.
	void Setup(FSummitStoneBeastZapperLightningCrystalParams& Params)
	{
		Settings = Params.Settings;
		SpawnPool = Params.SpawnPool; // Will this still function when owner unspawns?
		TargetActor = Params.TargetActor;
		ZapperOwner = Params.ZapperOwner;		

		MoveDir = Params.InitialMoveDir;
		DesiredDir = (Params.AttackLocation - ZapperOwner.ActorLocation).GetSafeNormal();
		ActorLocation = ZapperOwner.ActorLocation;
		StraightPathLocation = ActorLocation;

		Speed = Settings.LightningCrystalSpeed + Math::RandRange(0,50);
	}

	private void SetDecalHiddenInGame(bool bHideDecal)
	{
		DecalComp.SetHiddenInGame(bHideDecal);
		VFXTemp.SetHiddenInGame(bHideDecal);
	}


	private void ActivateTelegraphing()
	{
		if (State == ESummitStoneBeastZapperLightningCrystalState::Activated)
			return;

		State = ESummitStoneBeastZapperLightningCrystalState::Telegraphing;
		TelegraphTimer = Settings.LightningCrystalTelegraphDuration;
		VFXTemp.SetFloatParameter(n"ColorStrength", 1000.0);
	}

	private void ActivateLightning()
	{
		if (State == ESummitStoneBeastZapperLightningCrystalState::Activated)
			return;

		State = ESummitStoneBeastZapperLightningCrystalState::Activated;

		Mesh.SetHiddenInGame(false);
		DecalComp.SetHiddenInGame(true);
		VFXTemp.SetHiddenInGame(true);
		ActivationTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SpawnTime < SMALL_NUMBER)
			return;

		// Scale down decal
		float InterpSpeed = 1 / Settings.LightningCrystalLifetime;
		DecalComp.RelativeScale3D = Math::VInterpConstantTo(DecalComp.RelativeScale3D, DefaultDecalScale, DeltaSeconds, InterpSpeed);

		if (State == ESummitStoneBeastZapperLightningCrystalState::Moving)
		{
			// Activate lightning if player is near
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (ActorLocation.Dist2D(Player.ActorLocation) < Settings.LightningCrystalProximityActivationRadius)						
					ActivateTelegraphing();
			}

			// Activate lightning if time has run out
			if (Time::GetGameTimeSince(SpawnTime) > Settings.LightningCrystalLifetime)
				ActivateTelegraphing();

			// TODO: determine whether to move one tick after state change.

			// Move
			AccelFloat.AccelerateTo(1.5, 3.0, DeltaSeconds);
			MoveDir = MoveDir.MoveTowards( (TargetActor.ActorLocation - ActorLocation).GetSafeNormal(), DeltaSeconds * AccelFloat.Value); // Slightly homing
			// MoveDir = MoveDir.MoveTowards( DesiredDir, DeltaSeconds * 0.75); // Move towards parallel movement
			StraightPathLocation += MoveDir * Speed * DeltaSeconds;
			
			FVector Offset;
			//Offset = FVector(Math::Cos(Time::GetGameTimeSince(ActivationTime) * 10), Math::Sin(Time::GetGameTimeSince(ActivationTime) * 10), 0) * 5; // bounding movement
			
			FVector SidewaysDir = MoveDir.CrossProduct(FVector::UpVector).GetSafeNormal();
			//Offset = SidewaysDir * Math::RandRange(-1, 1) * 5; // erratic movement
			Offset = SidewaysDir * Math::Sin(Time::GetGameTimeSince(ActivationTime) * 11) * 15; // sinusoidal movement
			
			//Offset = Math::GetRandomPointOnCircle_XY() * 5; // erratic movement
			
			ActorLocation = StraightPathLocation + Offset;
		}		
		else if (State == ESummitStoneBeastZapperLightningCrystalState::Telegraphing)
		{
			// TODO: effects

			TelegraphTimer -= DeltaSeconds;
			if (TelegraphTimer < 0.0)
				ActivateLightning();
		}

		if (State == ESummitStoneBeastZapperLightningCrystalState::Activated)
		{
			// Lightning wobbling
			FVector TargetScale;		
			TargetScale.X = Math::RandRange(0.001, 0.05);
			TargetScale.Y = Math::RandRange(0.001,0.05);
			TargetScale.Z = Math::RandRange(0.075, 0.2);
			Mesh.RelativeScale3D = Math::VInterpConstantTo(Mesh.RelativeScale3D, TargetScale, DeltaSeconds, 10);

			// Ground impact
			if (!bHasMadeImpact)
			{
				bHasMadeImpact = true;
				FSummitStoneBeastZapperLightningImpactParams Params;
				Params.Location = ActorLocation;
				USummitStoneBeastZapperEffectHandler::Trigger_OnLightningImpact(ZapperOwner, Params);
				
				// Damage players
				for (AHazePlayerCharacter Player : Game::Players)
				{
					if (ActorLocation.Dist2D(Player.ActorLocation) < Settings.AttackDamageRadius)							
						Player.DamagePlayerHealth(10.0);
				}
			}
			else if (Time::GetGameTimeSince(ActivationTime) > 0.5) // lightning expires
			{
				// Expire
				Mesh.SetHiddenInGame(true);
				AddActorDisable(this);
				RespawnComp.UnSpawn();
				SpawnPool.UnSpawn(this);	
				return;		
			}
		}

		
#if EDITOR
		if (ZapperOwner.bHazeEditorOnlyDebugBool)
		{
			// detection range
			Debug::DrawDebugCylinder(ActorLocation, ActorLocation + FVector::UpVector * 1000.0, Settings.LightningCrystalProximityActivationRadius, 12, FLinearColor::DPink);
			// damage range
			Debug::DrawDebugCylinder(ActorLocation, ActorLocation + FVector::UpVector * 1000.0, Settings.AttackDamageRadius);
		}
#endif
	
	}
}


struct FSummitStoneBeastZapperLightningCrystalParams
{
	AAISummitStoneBeastZapper ZapperOwner;
	
	// TBD: if we want to home in on target actor.
	AHazeActor TargetActor;

	// Owner's Settings
	USummitStoneBeastZapperSettings Settings;

	// Owner's SpawnPool for LightningCrystals
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;

	// Initial target attack location.
	FVector AttackLocation;

	// Initial move direction.
	FVector InitialMoveDir;
}
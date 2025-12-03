class ASummitDecimatorTopdownShockwaveActor : AHazeActor
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

	
	UPROPERTY(DefaultComponent)
	USceneComponent ShockwaveRoot;

	UPROPERTY(DefaultComponent, Attach = "ShockwaveRoot")
	UStaticMeshComponent ShockwaveDisc;
	default ShockwaveDisc.CollisionProfileName = n"NoCollision";
	default ShockwaveDisc.bCanEverAffectNavigation = false;


	UPROPERTY(DefaultComponent, Attach = "ShockwaveRoot")
	UStaticMeshComponent ShockwaveTorus;
	default ShockwaveTorus.CollisionProfileName = n"NoCollision";
	default ShockwaveTorus.bCanEverAffectNavigation = false;	

	TPerPlayer<bool> HitPlayers;

	USummitDecimatorTopdownSettings Settings;

	private AAISummitDecimatorTopdown DecimatorOwner;

	private FVector OriginalScale;
	private float CurrentScale = 1.0;
	private float TorusWidth = 300;
	private float TorusRadius = 1080;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalScale = ShockwaveRoot.GetWorldScale();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		CurrentScale = 0.2;

		TorusWidth = ShockwaveTorus.CreateDynamicMaterialInstance(0).GetScalarParameterValue(n"Radius");
	}
	
	UFUNCTION()
	private void OnRespawn()
	{
		CurrentScale = 0.2;
		ShockwaveRoot.SetWorldScale3D(OriginalScale);
		SetActorTickEnabled(true);
		RemoveActorDisable(this);
		HitPlayers[Game::Mio] = false;
		HitPlayers[Game::Zoe] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		// Need to set Owner and Settings		
		if(Settings == nullptr)
			return;

		// Lerp the scale
		CurrentScale += DeltaSeconds * 2.0;
		CurrentScale = Math::Min(10, CurrentScale);
		FVector Scale = FVector(CurrentScale, CurrentScale, CurrentScale);
		Scale.Z = Math::Min(1, CurrentScale);
		ShockwaveRoot.SetWorldScale3D(Scale);

		
		float OuterRadius = CurrentScale * TorusRadius;
		float InnerRadius = CurrentScale * (TorusRadius-TorusWidth*0.6); // Arbitrary multiplier for generously jumpable hitbox
		
		//Debug::DrawDebugDisk(ActorLocation, FVector::UpVector, InnerRadius, MaxNumCircles = 1, bDrawInForeground = true);
		//Debug::DrawDebugDisk(ActorLocation, FVector::UpVector, OuterRadius, LineColor = FLinearColor::Blue, MaxNumCircles = 1, bDrawInForeground = true);
		
		// Handle Player damage
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if (!Player.HasControl()) // only stumble and deal damage to control side player
				continue;
			if (HitPlayers[Player]) // only hit once
				continue;
			if(!Player.ActorLocation.IsWithinDist(ActorLocation, OuterRadius)) // outside of danger zone
				continue;
			if (Player.ActorLocation.IsWithinDist(ActorLocation, InnerRadius)) // within safe zone
				continue;
			if (Player.ActorLocation.Z > ActorLocation.Z + 150) // danger zone height, todo: setting
				continue;

			Player.DealTypedDamage(DecimatorOwner, 0.5, EDamageEffectType::FireImpact, EDeathEffectType::FireImpact);

			HitPlayers[Player] = true;
			FTeenDragonStumble Stumble;
			Stumble.Duration = 0.5;
			FVector Dir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			Dir.Z = 0;
			Stumble.Move = Dir * 500;
			Stumble.Apply(Player);
		}
		
		// Handle Spikebomb damage
		UHazeTeam SpikeBombTeam = HazeTeam::GetTeam((DecimatorTopdownSpikeBombTags::SpikeBombTeamTag));
		if (SpikeBombTeam != nullptr)
		{
			for (AHazeActor Member : SpikeBombTeam.GetMembers())
			{
				if (Member == nullptr)
					continue;
				
				// Check if inside danger zone
				if(!Member.ActorLocation.IsWithinDist(ActorLocation, OuterRadius)) // outside of danger zone
					continue;
				if (Member.ActorLocation.IsWithinDist(ActorLocation, InnerRadius)) // within safe zone
					continue;
				if (Member.ActorLocation.Z > ActorLocation.Z + 250) // danger zone height
					continue;
			
				// Enable explosion
				USummitDecimatorShockwaveSpikeBombResponseComponent ShockwaveResponseComp = USummitDecimatorShockwaveSpikeBombResponseComponent::Get(Member);
				if (ShockwaveResponseComp != nullptr)
					ShockwaveResponseComp.OnHitByShockwave.Broadcast();
			}
		}

		if (CurrentScale >= 10) // todo: setting
			Expire();
		
#if EDITOR
		if (DecimatorOwner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugCircle(ActorLocation, OuterRadius, LineColor = FLinearColor::Red);
			Debug::DrawDebugCircle(ActorLocation, InnerRadius, LineColor = FLinearColor::Green);
		}
#endif
	
	}

	void Expire()
	{	
		SetActorTickEnabled(false);
		AddActorDisable(this);
		if (VFXTemp != nullptr)
			VFXTemp.Deactivate();

		// Make this available for respawn
		RespawnComp.UnSpawn();
	}

	void SetOwner(AAISummitDecimatorTopdown Owner) property
	{
		DecimatorOwner = Owner;
		Settings = USummitDecimatorTopdownSettings::GetSettings(DecimatorOwner);
	}

}
class USummitKnightRotatingCrystalBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	USummitKnightRotatingCrystalLauncher Launcher;
	UHazeCharacterSkeletalMeshComponent Mesh;
	USummitKnightAnimationComponent KnightAnimComp;
	
	FBasicAIAnimationActionDurations Durations;
	bool bSpawnedCrystals;
	float LaunchTime;
	int NumLaunched;
	TArray<ASummitKnightRotatingCrystal> ActiveCrystals;
	FVector CenterLaunchDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		Launcher = USummitKnightRotatingCrystalLauncher::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		Launcher.PrepareProjectiles(1);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
		{
			if (!Settings.bRotatingCrystalWaitForExpiration) 
				return true;
			if (ActiveCrystals.Num() == 0)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		//USummitKnightEventHandler::Trigger_OnTelegraphRotatingCrystal(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));

		Durations.Telegraph = Settings.RotatingCrystalTelegraphDuration;
		Durations.Anticipation = Settings.RotatingCrystalAnticipationDuration;
		Durations.Action = Settings.RotatingCrystalAttackDuration;
		Durations.Recovery = Settings.RotatingCrystalRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SpikeTrail, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::SpikeTrail, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		LaunchTime = Durations.Telegraph + Durations.Anticipation;
		NumLaunched = 0;
		ActiveCrystals.Empty(Settings.RotatingCrystalNumber);
		bSpawnedCrystals = false;
	}

	FName GetAlignSocket(int Index)
	{
		int iSocket = (Index % 3);
		if (iSocket == 1)
			return n"ProjectileAlign1";
		if (iSocket == 2)	
			return n"ProjectileAlign3";
		return n"ProjectileAlign2";
	} 

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < LaunchTime)
			DestinationComp.RotateTowards(Game::Mio);

		if (!bSpawnedCrystals && (ActiveDuration > Durations.Telegraph * 0.5))
		{
			// Spawn crystals at align points in preparation or launching them
			for (int i = 0; i < Settings.RotatingCrystalNumber; i++)
			{
				UBasicAIProjectileComponent Projectile = Launcher.Launch(FVector::ZeroVector);
				auto Crystal = Cast<ASummitKnightRotatingCrystal>(Projectile.Owner);
				Crystal.Prepare(Mesh, GetAlignSocket(i));	
				ActiveCrystals.AddUnique(Crystal);
				UHazeActorRespawnableComponent::Get(Crystal).OnUnspawn.AddUFunction(this, n"OnCrystalExpire");
			}
			bSpawnedCrystals = true;
		}

		if (ActiveDuration > LaunchTime)
		{
			NumLaunched++;
			if (NumLaunched < Settings.RotatingCrystalNumber)
				LaunchTime += (Durations.Action / float(Settings.RotatingCrystalNumber - 1)); 
			else
				LaunchTime = BIG_NUMBER;

			FVector LaunchDir;
			if (NumLaunched == 1)
			{
				// Set up initial launch direction	
				FRotator ToTargetRot = (Game::Mio.ActorLocation - Owner.ActorLocation).Rotation();
				FRotator LaunchRot = FRotator::ZeroRotator;
				LaunchRot.Yaw = ToTargetRot.Yaw + Math::RandRange(-0.2, 0.2) * Settings.RotatingCrystalLaunchSpreadDegrees;
				CenterLaunchDirection = LaunchRot.Vector();
				LaunchDir = CenterLaunchDirection;
			}
			else
			{
				// Shift launch direction over spread, alternating left and right
				FRotator LaunchRot = CenterLaunchDirection.Rotation();
				float Dir = (NumLaunched % 2) * 2.0 - 1.0;
				float YawDelta = (Settings.RotatingCrystalLaunchSpreadDegrees ) / float(Settings.RotatingCrystalNumber - 1);
				LaunchRot.Yaw += Dir * YawDelta * Math::FloorToFloat((NumLaunched + 0.01) / 2.0);
				LaunchDir = LaunchRot.Vector();
			}

			ActiveCrystals[NumLaunched - 1].LaunchAt(Game::Mio, LaunchDir);
			//USummitKnightEventHandler::Trigger_OnLaunchRotatingCrystal(Owner, FSummitKnightLaunchProjectileParams(ActiveCrystals[NumLaunched - 1].ActorLocation));
		}	
	}

	UFUNCTION()
	private void OnCrystalExpire(AHazeActor RespawnableActor)
	{
		auto UnspawnedCrystal = Cast<ASummitKnightRotatingCrystal>(RespawnableActor);
		if (!ensure(ActiveCrystals.Contains(UnspawnedCrystal)))
			return;
		UHazeActorRespawnableComponent::Get(RespawnableActor).OnUnspawn.UnbindObject(this);
		ActiveCrystals.RemoveSwap(UnspawnedCrystal);
	}
}


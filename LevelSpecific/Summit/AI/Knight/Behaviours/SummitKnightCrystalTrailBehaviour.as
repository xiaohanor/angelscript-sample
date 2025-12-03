class USummitKnightCrystalTrailBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	USummitKnightCrystalTrailLauncher Launcher;
	UHazeCharacterSkeletalMeshComponent Mesh;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightComponent KnightComp;
	
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;

	FBasicAIAnimationActionDurations Durations;
	bool bSpawnedCrystals;
	float LaunchTime;
	float PreLaunchTime = BIG_NUMBER;
	TArray<ASummitKnightCrystalTrail> ActiveTrails;
	FVector CenterLaunchDirection;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		Launcher = USummitKnightCrystalTrailLauncher::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		CenterLaunchDirection = Owner.ActorForwardVector;

		Launcher.PrepareProjectiles(Settings.CrystalTrailNumber * 2);
		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Owner.GetComponentsByClass(Blades);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Launcher.PrepareProjectiles(Settings.CrystalTrailNumber * 4);

		Durations.Telegraph = Settings.CrystalTrailTelegraphDuration;
		Durations.Anticipation = Settings.CrystalTrailAnticipationDuration;
		Durations.Action = Settings.CrystalTrailActionDuration;
		Durations.Recovery = Settings.CrystalTrailRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SpikeTrail, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::SpikeTrail, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		LaunchTime = Durations.PreActionDuration;
		PreLaunchTime = Durations.PreActionDuration * 0.8;
		ActiveTrails.Empty(Settings.CrystalTrailNumber);
		bSpawnedCrystals = false;

		Blades[0].Equip();

		USummitKnightEventHandler::Trigger_OnTelegraphTrackingFlames(Owner);
		KnightComp.bSpawningCrystalTrails = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		// Expire any active trails that hasn't been released
		for (ASummitKnightCrystalTrail Trail : ActiveTrails)
		{
			if (Time::GameTimeSeconds < Trail.ReleaseTime)
				Trail.StartExpireTime = Time::GameTimeSeconds;
		}
		KnightComp.bCanDodge.Clear(this);

		USummitKnightEventHandler::Trigger_OnStopTrackingFlames(Owner);		
	}

	FName GetAlignSocket(int Index)
	{
		int iSocket = (Index % 3);
		if (iSocket == 1)
			return n"ProjectileAlign3";
		if (iSocket == 2)	
			return n"ProjectileAlign2";
		return n"ProjectileAlign1";
	} 

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < Durations.PreActionDuration)
			DestinationComp.RotateTowards(KnightComp.GetSpellFocus());

		if (!bSpawnedCrystals && (ActiveDuration > Durations.Telegraph * 0.5) && HasControl())
			CrumbSpawnProjectiles();

		if (ActiveDuration > PreLaunchTime)
		{
			PreLaunchTime = BIG_NUMBER;
			USummitKnightEventHandler::Trigger_OnStartLaunchingTrackingFlames(Owner);
		}

		if (ActiveDuration > LaunchTime)
			CrumbLaunch();

		// No dodging while hand is down
		bool bShouldAllowDodge = (ActiveDuration < Durations.PreActionDuration - 0.5) || (ActiveDuration > Durations.PreRecoveryDuration);
		if (KnightComp.bCanDodge.Get() && !bShouldAllowDodge)
			KnightComp.bCanDodge.Apply(false, this); 
		if (!KnightComp.bCanDodge.Get() && bShouldAllowDodge)
			KnightComp.bCanDodge.Clear(this);

		KnightComp.ActiveCrystalTrails = ActiveTrails;
	}


	UFUNCTION(CrumbFunction)
	void CrumbSpawnProjectiles()
	{
		// Crumbed so we can be sure these projectiles have been prepared.
		// Spawn crystals at align points in preparation for launching them
		for (int i = 0; i < Settings.CrystalTrailNumber; i++)
		{
			UBasicAIProjectileComponent Projectile = Launcher.Launch(FVector::ZeroVector);
			auto CrystalTrail = Cast<ASummitKnightCrystalTrail>(Projectile.Owner);
			CrystalTrail.Prepare(Mesh, GetAlignSocket(i), ((i % 2) == 0) ? Game::Mio : Game::Zoe, 1.0, i);	
			ActiveTrails.AddUnique(CrystalTrail);
			UHazeActorRespawnableComponent::Get(CrystalTrail).OnUnspawn.AddUFunction(this, n"OnCrystalExpire");
		}
		bSpawnedCrystals = true;
	}


	UFUNCTION(CrumbFunction)
	void CrumbLaunch()
	{
		LaunchTime = BIG_NUMBER;

		FVector Center = KnightComp.GetArenaLocation(Owner.ActorLocation + Owner.ActorForwardVector * 2500.0);
		FVector Side = (Owner.ActorForwardVector + Owner.ActorRightVector * 3.0).GetSafeNormal2D();
		for (int i = 0; i < ActiveTrails.Num(); i++)
		{
			float Offset = -((i % 2) * 2.0 - 1.0) * ((Math::IntegerDivisionTrunc(i, 2) + 0.5) * 300.0);
			FVector SpawnLoc = Center + Side * Offset;
			ActiveTrails[i].Release(KnightComp.Arena, SpawnLoc, Settings.CrystalTrailLandPause + 0.6 * i);
			AHazePlayerCharacter Target = ActiveTrails[i].Target;
			USummitKnightEventHandler::Trigger_OnLaunchTrackingFlames(Owner, FSummitKnightTrackingFlamesParams(Target, i));
		}
	}

	UFUNCTION()
	private void OnCrystalExpire(AHazeActor RespawnableActor)
	{
		auto UnspawnedCrystal = Cast<ASummitKnightCrystalTrail>(RespawnableActor);
		if (!ActiveTrails.Contains(UnspawnedCrystal))
			return;
		UHazeActorRespawnableComponent::Get(RespawnableActor).OnUnspawn.UnbindObject(this);
		ActiveTrails.RemoveSingleSwap(UnspawnedCrystal);

		if(ActiveTrails.IsEmpty())
		{
			KnightComp.bSpawningCrystalTrails = false;
			USummitKnightEventHandler::Trigger_OnAllTrackingFlamesExpired(Cast<AHazeActor>(KnightComp.Owner));
		}
	}
}

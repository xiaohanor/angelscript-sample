class USummitKnightAreaDenialFireballBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	USummitKnightAreaDenialFireballLauncher Launcher;
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;

	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	
	FBasicAIAnimationActionDurations Durations;
	float LaunchTime;
	int NumLaunched;
	int NumToLaunch;

	FVector NextTargetLocation;
	int iCurrentNearZone = -1;
	int iCurrentFarZone = -1;
	AHazePlayerCharacter TrackedPlayer;
	ASummitShieldWallMiddleLayer OuterShieldWall;
	
	TArray<ASummitKnightAreaDenialFireball> Fireballs;
	TArray<USummitKnightAreaDenialSphereComponent> TargetComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		Launcher = USummitKnightAreaDenialFireballLauncher::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		OuterShieldWall = SummitKnightShieldwall::FindClosestMiddleShieldwall(Owner.ActorLocation);
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

		Durations.Telegraph = Settings.AreaDenialFireballTelegraphDuration;
		Durations.Anticipation = Settings.AreaDenialFireballAnticipationDuration;
		Durations.Action = Settings.AreaDenialFireballAttackDuration;
		Durations.Recovery = Settings.AreaDenialFireballRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::HomingFireballs, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::HomingFireballs, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		LaunchTime = Durations.Telegraph + Durations.Anticipation;
		NumLaunched = 0;
		NumToLaunch = 3; // This will be replaced by number of targets in denial zone
		Fireballs.Empty();

		FVector OwnLoc = Owner.ActorLocation;
		TrackedPlayer = Game::Mio;
		if (OwnLoc.DistSquared2D(Game::Mio.ActorLocation) > OwnLoc.DistSquared2D(Game::Zoe.ActorLocation))
			TrackedPlayer = Game::Zoe;

		Blades[0].Equip();

		//USummitKnightEventHandler::Trigger_OnTelegraphAreaDenialFireball(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLoc = NextTargetLocation;
		if (Fireballs.Num() == 0) 
		{
			// Haven't started attack yet, aim at where we will center attack once it starts
			FVector OwnLoc = Owner.ActorLocation;
			if (OwnLoc.DistSquared2D(TrackedPlayer.ActorLocation) > Math::Square(1.2) * OwnLoc.DistSquared2D(TrackedPlayer.OtherPlayer.ActorLocation))
				TrackedPlayer = TrackedPlayer.OtherPlayer;
			TargetLoc = TrackedPlayer.ActorLocation;
			if (Game::Mio.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, 5000.0))
				TargetLoc = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		}

		if ((Fireballs.Num() == 0) || (Settings.AreaDenialFireballTurnTowardsNextTargetLocation))
			DestinationComp.RotateTowards(TargetLoc);	

		if (ActiveDuration > LaunchTime)
		{
			NumLaunched++;

			if (NumLaunched == 1)
			{
				SetupTargetPattern(TargetLoc);
				NextTargetLocation = GetTargetLocation(0); 
			}

			if (NumLaunched < NumToLaunch)
				LaunchTime += Durations.Action / float(NumToLaunch - 1);
			else 
				LaunchTime = BIG_NUMBER;


			UBasicAIProjectileComponent Projectile = Launcher.Launch(Launcher.WorldRotation.ForwardVector * 1000.0);
			auto Fireball = Cast<ASummitKnightAreaDenialFireball>(Projectile.Owner);
			Fireballs.AddUnique(Fireball);
			USummitKnightAreaDenialSphereComponent CurTargetComp = TargetComps[(NumLaunched - 1) % TargetComps.Num()];
			CurTargetComp.Owner.SetActorLocation(KnightComp.GetArenaLocation(CurTargetComp.Owner.ActorLocation));
			Fireball.LaunchAt(CurTargetComp, Launcher);
		
			// Update next target location so we can turn towards it in preparation for next projectile
			if (NumLaunched < NumToLaunch)
				NextTargetLocation = GetTargetLocation(NumLaunched);

			//USummitKnightEventHandler::Trigger_OnLaunchAreaDenialFireball(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
		}	
	}

	void SetupTargetPattern(FVector CenterLoc)
	{
		FVector OwnLoc = KnightComp.GetArenaLocation(Owner.ActorLocation);
		FVector CenterDir = (CenterLoc - OwnLoc).GetSafeNormal2D();

		float OuterShieldwallRadius = (OuterShieldWall != nullptr) ? OuterShieldWall.Radius : 5000.0;

		TargetComps.Empty();
		ASummitKnightAreaDenialZone TargetZone;
		if (CenterLoc.IsWithinDist(OwnLoc, OuterShieldwallRadius))	
			TargetZone = UseNextZone(iCurrentNearZone, Launcher.NearZones); // Use near zone

		if (!IsValid(TargetZone))
			TargetZone = UseNextZone(iCurrentFarZone, Launcher.FarZones); // Use far zone

		if (IsValid(TargetZone))
		{
			// Pivot zone around us to center direction
			FVector PrevDir = (TargetZone.ActorLocation - OwnLoc);
			PrevDir.Z = 0.0;
			FTransform PrevTransform = FTransform(PrevDir.Rotation(), OwnLoc);
			FTransform LocalTransform = TargetZone.ActorTransform * PrevTransform.Inverse();
			FTransform PivotedTransform = FTransform(CenterDir.Rotation(), OwnLoc);
			TargetComps.Add(TargetZone.SphereComp);
			NumToLaunch = TargetComps.Num();
		}
		else
		{
			// Backup in case we don't have any placed zones
			NumToLaunch = 3;
			Owner.GetComponentsByClass(TargetComps);
			for (int i = TargetComps.Num(); i < NumToLaunch; i++)
			{
				TargetComps.Add(USummitKnightAreaDenialSphereComponent::Create(Owner));
				TargetComps.Last().DetachFromParent();
			}
			FVector StartLoc = OwnLoc + CenterDir * OuterShieldwallRadius;
			TargetComps[0].SetWorldLocation(StartLoc);
			float Divisor = float(Math::Max(1, NumToLaunch - 2));
			float Range = 1000.0;
			float Radius = 500.0;
			if (NumToLaunch > 3)
				Range -= Radius; // Not quite correct, fix if actually used
			FVector SideDir = CenterDir.CrossProduct(FVector::UpVector);
			for (int i = 1; i < NumToLaunch; i++)
			{
				float Alpha = (i - 1) / Divisor;
				float Fwd = Math::Sin(Alpha * PI); // 0 -> 1 -> 0
				float Side = Math::Cos(Alpha * PI); // 1 -> 0 -> -1
				FVector TearDropLoc = StartLoc + CenterDir * (Fwd * Radius + Range) + SideDir * Side * Radius;
				//TargetComps[i].SetWorldLocation(KnightComp.GetArenaLocation(TearDropLoc));
			}
		}
	}

	ASummitKnightAreaDenialZone UseNextZone(int& InOutCurrentZone, TArray<ASummitKnightAreaDenialZone> Zones)
	{
		InOutCurrentZone++;
		for (int i = 0; i < Zones.Num(); i++)
		{
			int iZone = (InOutCurrentZone + i) % Zones.Num();
			if (!IsValid(Zones[iZone]))
				continue;
			return Zones[iZone];		
		}
		return nullptr;
	}

	FVector GetTargetLocation(int TargetIndex)
	{
		return KnightComp.GetArenaLocation(TargetComps[TargetIndex % TargetComps.Num()].WorldLocation);
	}
}


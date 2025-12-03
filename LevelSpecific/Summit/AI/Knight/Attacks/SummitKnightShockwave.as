class USummitKnightShockwaveLauncher : UBasicAIProjectileLauncherComponent
{
}

class ASummitKnightShockwave : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	USummitKnightSettings Settings;
	USummitKnightComponent KnightComp;
	FVector Destination;

	TArray<AHazePlayerCharacter> PotentialTargets;

	void LaunchAt(FVector Dest)
	{
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);
		SetActorLocation(KnightComp.GetArenaLocation(ActorLocation));
		FVector LauncherLoc = ProjectileComp.Launcher.ActorLocation;
		FVector ToDestDir = (Dest - LauncherLoc).GetSafeNormal2D();
		Destination = KnightComp.GetArenaLocation(LauncherLoc + ToDestDir * Settings.ShockwaveExpireRange * 1.2);
		PotentialTargets = Game::Players;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Move inexorably towards destination, dealing damage to targets
		// TODO: Network this!		
		ActorLocation += ProjectileComp.Velocity * DeltaTime;

		FVector HitStart = ActorLocation - ProjectileComp.Velocity * 0.5;
		for (int i = PotentialTargets.Num() - 1; i >= 0; i--)
		{
			if (!PotentialTargets[i].HasControl())
				continue;
			// Is shockwave passing us by?
			FVector TargetLineLoc;
			float Dummy;
			if (Math::ProjectPositionOnLineSegment(HitStart, ActorLocation, PotentialTargets[i].ActorLocation, TargetLineLoc, Dummy))
			{
				// Are we near enough? 
				TargetLineLoc.Z = PotentialTargets[i].ActorLocation.Z; // Can't jump over
				if (TargetLineLoc.IsWithinDist(PotentialTargets[i].ActorLocation, Settings.ShockwaveWidth * 0.5))
				{
					CrumbHitPlayer(PotentialTargets[i]);
					PotentialTargets.RemoveAtSwap(i);
				}
			}
		}

		float LaunchDistance = ProjectileComp.Launcher.ActorLocation.Dist2D(ActorLocation);
		if (LaunchDistance > Settings.ShockwaveExpireRange)
			CrumbExpire();

#if EDITOR
		// ProjectileComp.Launcher.bHazeEditorOnlyDebugBool = true
		if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
		{
			float Radius = Settings.ShockwaveWidth * 0.5;
			FVector Center = ActorLocation - ProjectileComp.Velocity.GetSafeNormal2D() * Radius;
			Debug::DrawDebugCapsule(Center, 2000.0, Radius, ActorRotation, FLinearColor::Red, 20.0);			
		}
#endif		
	}

	//UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player)
	{
		// TODO: Network this: Damage and stumble are both networked internally, but hit effect is not
		Player.DealTypedDamage(KnightComp.Owner, Settings.ShockwaveDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge, false);

		FVector HitDir = ProjectileComp.Velocity.GetSafeNormal2D();
		FVector HitSide = HitDir.CrossProduct(FVector::UpVector);
		if (HitSide.DotProduct(Player.ActorLocation - ActorLocation) > 0.0)
			HitDir = HitDir * 0.5 + HitSide * 0.5;
		else 	
			HitDir = HitDir * 0.5 - HitSide * 0.5;

		FVector StumbleMove = HitDir * Settings.ShockwaveStumbleDistance;
		KnightComp.StumbleDragon(Player, StumbleMove);

		FSummitKnightProjectileDamageParams DamageEventParams;
		DamageEventParams.Player = Player; 
		DamageEventParams.Damage = Settings.ShockwaveDamage; 
		DamageEventParams.Direction = HitDir;
		USummitKnightProjectileDamageEventHandler::Trigger_OnPlayerDamage(this, DamageEventParams);
	}

	//UFUNCTION(CrumbFunction)
	void CrumbExpire()
	{
		USummitKnightShockwaveEventHandler::Trigger_OnExpired(this);
		ProjectileComp.Expire();
	}	
}

UCLASS(Abstract)
class USummitKnightShockwaveEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}
}


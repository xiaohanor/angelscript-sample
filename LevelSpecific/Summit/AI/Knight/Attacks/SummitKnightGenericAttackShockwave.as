class USummitKnightGenericAttackShockwaveLauncher : UBasicAINetworkedProjectileLauncherComponent
{
}

class ASummitKnightGenericAttackShockwave : AHazeActor
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

	TArray<AHazePlayerCharacter> PotentialTargets;
	bool bWasEverLaunched = false;
	float StartExpiringTime = BIG_NUMBER;
	bool bIsLaunched;

	void LaunchLocal(FVector Location, AHazeActor Launcher)
	{
		bIsLaunched = true;
		ProjectileComp.Launcher = Launcher;
		Settings = USummitKnightSettings::GetSettings(Launcher);
		KnightComp = USummitKnightComponent::Get(Launcher);
		ActorLocation = KnightComp.Arena.GetAtArenaHeight(Location);
		USummitKnightGenericAttackShockwaveEventHandler::Trigger_OnLaunch(this);

		PotentialTargets = Game::Players;
		bWasEverLaunched = true;
		StartExpiringTime = BIG_NUMBER;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bIsLaunched)
			return;

		if (IsExpiring())
		{
			if (Time::GameTimeSeconds > StartExpiringTime + 5.0)
			{
				ProjectileComp.Expire();
				bIsLaunched = false;
			}
			return;
		}

		// Move inexorably towards destination, dealing damage to targets
		ActorLocation += ProjectileComp.Velocity * DeltaTime;

		FVector HitStart = ActorLocation - ProjectileComp.Velocity * 0.5;
		float DamageRadius = Settings.GenericAttackShockwaveWidth * 0.5;
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
				if (TargetLineLoc.IsWithinDist(PotentialTargets[i].ActorLocation, DamageRadius))
					CrumbHitPlayer(PotentialTargets[i]);
			}
		}
		KnightComp.SmashObstaclesInTeardrop(HitStart, ActorLocation, DamageRadius, DamageRadius);

		// Expire when passing out of arena
		if (HasControl() && !KnightComp.Arena.IsInsideArena(ActorLocation, -200.0) && (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > 0.5))
			CrumbStartExpiring();

		for(AHazePlayerCharacter Player : Game::Players)
		{
			const float EffectDistance = 1000;
			float Distance = ActorLocation.Distance(Player.ActorLocation);
			if(Distance < EffectDistance)
			{
				float FFFrequency = 200.0;
				float FFIntensity = 1;
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF, 1 - Distance / EffectDistance);
			}
		}

#if EDITOR
		// ProjectileComp.Launcher.bHazeEditorOnlyDebugBool = true
		if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
		{
			float Radius = Settings.GenericAttackShockwaveWidth * 0.5;
			FVector Center = ActorLocation - ProjectileComp.Velocity.GetSafeNormal2D() * Radius;
			Debug::DrawDebugCapsule(Center, 2000.0, Radius, ActorRotation, FLinearColor::Red, 20.0);			
		}
#endif		
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player)
	{
		PotentialTargets.Remove(Player);

		Player.DealTypedDamage(KnightComp.Owner, Settings.GenericAttackShockwaveDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge, true);

		if (Player.HasControl() && Player.IsPlayerDead())
			CrumbDeathFromShockwave(Player);

		FVector HitDir = ProjectileComp.Velocity.GetSafeNormal2D();
		FVector HitSide = HitDir.CrossProduct(FVector::UpVector);
		if (HitSide.DotProduct(Player.ActorLocation - ActorLocation) > 0.0)
			HitDir = HitDir * 0.5 + HitSide * 0.5;
		else 	
			HitDir = HitDir * 0.5 - HitSide * 0.5;

		FVector StumbleMove = HitDir * Settings.GenericAttackShockwaveStumbleDistance;
		KnightComp.StumbleDragon(Player, StumbleMove);

		FSummitKnightProjectileDamageParams DamageEventParams;
		DamageEventParams.Player = Player; 
		DamageEventParams.Damage = Settings.GenericAttackShockwaveDamage; 
		DamageEventParams.Direction = HitDir;
		USummitKnightProjectileDamageEventHandler::Trigger_OnPlayerDamage(this, DamageEventParams);

		USummitKnightEventHandler::Trigger_OnSingleSlashShockwaveHit(ProjectileComp.Launcher, FSummitKnightPlayerParams(Player));
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeathFromShockwave(AHazePlayerCharacter Player)
	{
		KnightComp.bDeathCouldHaveBeenDashAvoided[Player] = true; 
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartExpiring()
	{
		StartExpiringTime = Time::GameTimeSeconds;
		USummitKnightGenericAttackShockwaveEventHandler::Trigger_OnExpired(this);
	}	

	bool IsExpiring()
	{
		if (Time::GameTimeSeconds > StartExpiringTime - SMALL_NUMBER)
			return true;
		return false;
	}

	bool HasHitAnyTargets() const 
	{	
		if (!bWasEverLaunched)
			return false;
		if (PotentialTargets.Num() == Game::Players.Num())
			return false;
		return true;
	}
}

UCLASS(Abstract)
class USummitKnightGenericAttackShockwaveEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}

	UFUNCTION()
	void HackTweakEffect(UNiagaraComponent Effect)
	{
		Effect.SetWorldScale3D(FVector(1.0, 0.2, 1.0));
	}
}


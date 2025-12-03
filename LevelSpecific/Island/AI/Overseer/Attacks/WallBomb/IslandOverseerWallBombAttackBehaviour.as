
class UIslandOverseerWallBombAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(n"Attack");

	UIslandOverseerWallBombLauncherComponent ProjectileLauncher;
	UIslandOverseerSettings Settings;
	AIslandOverseerSideChaseStopPoint LimitPoint;

	FBasicAIAnimationActionDurations Durations;
	AHazeCharacter Character;
	float TargetHeight;
	bool bBlue;
	int Fired;
	int TotalFired;
	float PreviousDistance;
	TArray<AIslandOverseerWallBomb> Bombs;
	int AdditionalBombs;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		ProjectileLauncher = UIslandOverseerWallBombLauncherComponent::Get(Owner);
		ProjectileLauncher.Wielder = Owner;
		ProjectileLauncher.PrepareProjectiles(Settings.WallBombAmount * 3);
		LimitPoint = TListedActors<AIslandOverseerSideChaseStopPoint>()[0];
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		TArray<AIslandOverseerWallBomb> RemoveBombs = Bombs;
		for(AIslandOverseerWallBomb Bomb : RemoveBombs)
		{
			if(Bomb.IsActorDisabled())
				Bombs.Remove(Bomb);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandOverseerWallBombAttackBehaviourParams& Params) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!DoFire())
			return false;
		Params.TargetHeight = (TotalFired % 2) == 0 ? Math::RandRange(200, 600) : Math::RandRange(800, 1200);
		return true;
	}

	private bool DoFire() const
	{
		if(Fired > 0)
			return true;
		if(!Bombs.IsEmpty())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandOverseerWallBombAttackBehaviourParams Params)
	{
		Super::OnActivated();

		if(!HasControl())
			return;

		TargetHeight = Params.TargetHeight;
		TotalFired++;

		float Distance = Settings.WallBombBaseTargetDistance + Fired * 100;

		float ZoeDistance = 0;
		float MioDistance = 0;
		if(!Game::Mio.IsPlayerDead())
			MioDistance = Owner.ActorLocation.Distance(Game::Mio.ActorLocation);
		if(!Game::Zoe.IsPlayerDead())
			ZoeDistance = Owner.ActorLocation.Distance(Game::Zoe.ActorLocation);

		Distance += Math::Max(ZoeDistance, MioDistance);
		Distance = Math::Max(Distance, PreviousDistance + 100);
		PreviousDistance = Distance;

		FVector DeployWallLocation = Owner.ActorLocation + (Owner.ActorForwardVector * Distance) + (Owner.ActorUpVector * TargetHeight);

		FVector LaunchLocation = ProjectileLauncher.GetNextLaunchLocation();
		FVector Dir = (DeployWallLocation - LaunchLocation).GetSafeNormal();
		
		if(Owner.ActorForwardVector.DotProduct(LimitPoint.ActorLocation - DeployWallLocation) < 0)
		{
			DeactivateBehaviour();
			return;
		}

		if(HasControl())
			CrumbLaunchProjectile(Dir, LaunchLocation, DeployWallLocation);
		
		DeactivateBehaviour();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunchProjectile(FVector Dir, FVector LaunchLocation, FVector DeployWallLocation)
	{
		UBasicAIProjectileComponent Projectile = ProjectileLauncher.Launch(Dir * Settings.WallBombLaunchSpeed);
		Projectile.Damage = Settings.WallBombPlayerDamage;
		Projectile.Owner.SetActorLocation(LaunchLocation);
		auto WallBomb = Cast<AIslandOverseerWallBomb>(Projectile.Owner);
		WallBomb.SetWallLocation(DeployWallLocation);
		WallBomb.OwningActor = Owner;
		WallBomb.SetColor(bBlue);
		Bombs.AddUnique(WallBomb);
		Fired++;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if(Fired >= Settings.WallBombAmount + AdditionalBombs)
		{
			Fired = 0;
			AdditionalBombs++;
			PreviousDistance = 0;
			Cooldown.Set(Settings.WallBombCooldownDuration);
			bBlue = !bBlue;
		}
		else
		{
			Cooldown.Set(Settings.WallBombInterval);
		}
	}
}

struct FIslandOverseerWallBombAttackBehaviourParams
{
	float TargetHeight;
}
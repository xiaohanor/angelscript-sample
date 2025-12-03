
class UIslandOverseerMissileAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerMissileProjectileLauncherComponent ProjectileLauncher;
	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerPhaseComponent PhaseComp;
	UIslandOverseerSettings Settings;
	AHazeCharacter Character;

	float EndTime;
	float FiredTime;
	float Angle;
	int Wave;
	float WaveTime;
	int ProjectileIndex;
	bool bTelegraphing;
	float TelegraphTime;
	int AdditionalWaves;
	AHazePlayerCharacter TargetPlayer;
	TArray<FIslandOverseerMissileAttackProjectileData> Projectiles;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		ProjectileLauncher = UIslandOverseerMissileProjectileLauncherComponent::Get(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);

		PhaseComp = UIslandOverseerPhaseComponent::GetOrCreate(Owner);
		PhaseComp.OnPhaseChange.AddUFunction(this, n"PhaseChange");
	}

	UFUNCTION()
	private void PhaseChange(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase)
	{
		if(NewPhase != EIslandOverseerPhase::Door)
			return;

		for(FIslandOverseerMissileAttackProjectileData Projectile : Projectiles)
			Projectile.Projectile.Expire();
		Projectiles.Empty();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(EndTime != 0 && Time::GetGameTimeSince(EndTime) > 1)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		VisorComp.Open();
		Wave = 0;
		WaveTime = Time::GetGameTimeSeconds();
		AnimComp.RequestFeature(FeatureTagIslandOverseer::MissileAttack, EBasicBehaviourPriority::Medium, this);
		AnimComp.RequestSubFeature(SubTagIslandOverseerMissileAttack::Start, this, Settings.MissileAttackTelegraphDuration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		EndTime = 0;
		AdditionalWaves += Settings.MissileAttackAdditionalWaves;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(EndTime > 0)
			return;

		if(ActiveDuration < 0.5)
			return;

		if(WaveTime > 0)
		{
			SetupWave();
			Angle += 45;
			WaveTime = 0;
			return;
		}

		if(TelegraphTime > 0 && Time::GetGameTimeSince(TelegraphTime) < Settings.MissileAttackTelegraphDuration)
			return;

		if(bTelegraphing)
		{
			bTelegraphing = false;
			UIslandOverseerEventHandler::Trigger_OnBallAttackTelegraphStop(Owner);
			AnimComp.RequestSubFeature(SubTagIslandOverseerMissileAttack::Loop, this);
		}

		if(FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > Settings.MissileAttackLaunchInterval)
		{
			FireProjectile(Projectiles[ProjectileIndex]);

			ProjectileIndex++;
			if(ProjectileIndex >= Projectiles.Num())
			{
				Wave++;		
				if(Wave >= Settings.MissileAttackWaves + AdditionalWaves)
				{
					AnimComp.RequestSubFeature(SubTagIslandOverseerMissileAttack::End, this);
					EndTime = Time::GameTimeSeconds;
				}
				else
					WaveTime = Time::GameTimeSeconds;
			}
		}
	}

	private void FireProjectile(FIslandOverseerMissileAttackProjectileData Data)
	{		
		UBasicAIProjectileComponent Projectile = Data.Projectile;

		Projectile.Launcher = ProjectileLauncher.Wielder;
		Projectile.LaunchingWeapon = this;	
		Projectile.Owner.DetachRootComponentFromParent(true);
		ProjectileLauncher.LastLaunchedProjectile = Projectile;
		ProjectileLauncher.OnLaunchProjectile.Broadcast(Projectile);

		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Data.LaunchLocation, Data.TargetLocation, Settings.MissileAttackLaunchGravity, 250);
		Data.Projectile.Launch(LaunchVelocity);
		Projectile.Damage = Settings.MissileAttackPlayerDamage;
		Projectile.Gravity = Settings.MissileAttackLaunchGravity;
		Projectile.HazeOwner.RemoveActorVisualsBlock(this);
		FiredTime = Time::GetGameTimeSeconds();
	}

	private void SetupWave()
	{
		ProjectileIndex = 0;

		if(TargetPlayer == nullptr)
			TargetPlayer = Game::Mio;
		else
			TargetPlayer = TargetPlayer.OtherPlayer;

		if(TargetPlayer.IsPlayerDead())
			TargetPlayer = TargetPlayer.OtherPlayer;

		FVector TargetLocation = TargetPlayer.ActorLocation;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();
		Trace.IgnoreActor(TargetPlayer);
		FHitResult Hit = Trace.QueryTraceSingle(TargetPlayer.ActorLocation, TargetPlayer.ActorLocation - TargetPlayer.ActorUpVector * 500);
		if(Hit.bBlockingHit)
			TargetLocation = Hit.Location;

		Projectiles.Empty();
		float OffsetPerBall = 350;
		float Offset = -OffsetPerBall * Math::IntegerDivisionTrunc(Settings.MissileAttackProjectileAmount, 2);
		for(int i = 0; i < Settings.MissileAttackProjectileAmount; i++)
		{
			FIslandOverseerMissileAttackProjectileData Data;
			Data.TargetLocation = TargetLocation + FVector::ForwardVector.RotateAngleAxis(Angle, FVector::UpVector) * (Offset + (i * OffsetPerBall));
			Data.LaunchLocation = ProjectileLauncher.GetNextLaunchLocation();

			Data.Projectile = ProjectileLauncher.SpawnProjectile();
			Data.Projectile.Launcher = ProjectileLauncher.Wielder;
			Data.Projectile.LaunchingWeapon = this;	
			Data.Projectile.Prime();
			Data.Projectile.Owner.AttachRootComponentTo(ProjectileLauncher, NAME_None, EAttachLocation::KeepWorldPosition);
			Data.Projectile.Owner.SetActorLocation(Data.LaunchLocation);
			Data.Projectile.HazeOwner.AddActorVisualsBlock(this);

			ProjectileLauncher.OnPrimeProjectile.Broadcast(Data.Projectile);

			FIslandOverseerMissileProjectileOnTelegraphData TelegraphData;
			TelegraphData.TargetLocation = Data.TargetLocation;
			UIslandOverseerMissileProjectileEventHandler::Trigger_OnTelegraph(Data.Projectile.HazeOwner, TelegraphData);

			Projectiles.Add(Data);
		}

		bTelegraphing = true;
		TelegraphTime = Time::GameTimeSeconds;
		UIslandOverseerEventHandler::Trigger_OnBallAttackTelegraphStart(Owner);
	}
}

struct FIslandOverseerMissileAttackProjectileData
{
	UBasicAIProjectileComponent Projectile;
	FVector TargetLocation;
	FVector LaunchLocation;
}
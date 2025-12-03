class USummitKnightCrystalWallBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USummitKnightSettings Settings;
	USummitKnightCrystalWallLauncher Launcher;
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightStageComponent StageComp;
	
	FBasicAIAnimationActionDurations Durations;
	float LaunchTime;
	ASummitKnightCrystalWall ActiveWall;
	AHazePlayerCharacter Target;
	float CenterYaw;

	float WallSpeedFactor = 1.0;
	float AnimTimeScale = 1.0;

	USummitKnightCrystalWallBehaviour(float AnimPlayRate, float ProjectileSpeedFactor)
	{
		AnimTimeScale = AnimPlayRate;
		WallSpeedFactor = ProjectileSpeedFactor;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		Launcher = USummitKnightCrystalWallLauncher::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::Get(Owner);
		StageComp = USummitKnightStageComponent::Get(Owner);
		Target = Game::Mio;
		CenterYaw = Owner.ActorRotation.Yaw;

		Launcher.PrepareProjectiles(1);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
		{
			if (!Settings.bCrystalWallWaitForExpiration) 
				return true;
			if (ActiveWall == nullptr)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Launcher.PrepareProjectiles(1);

		//USummitKnightEventHandler::Trigger_OnTelegraphCrystalWall(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));

		Durations.Telegraph = Settings.CrystalWallTelegraphDuration;
		Durations.Anticipation = Settings.CrystalWallAnticipationDuration;
		Durations.Action = Settings.CrystalWallAttackDuration;
		Durations.Recovery = Settings.CrystalWallRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::MetalWall, NAME_None, Durations);
		Durations.ScaleAll(AnimTimeScale);
		AnimComp.RequestAction(SummitKnightFeatureTags::MetalWall, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		LaunchTime = Durations.Telegraph + Durations.Anticipation;

		ActiveWall = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Target);

		if (HasControl() && (ActiveDuration > LaunchTime))
			CrumbLaunch();
	}


	UFUNCTION(CrumbFunction)
	void CrumbLaunch()
	{
		LaunchTime = BIG_NUMBER;
		UBasicAIProjectileComponent Projectile = Launcher.Launch(Launcher.WorldRotation.ForwardVector * Settings.CrystalWallMoveSpeedTarget * 0.1);
		ActiveWall = Cast<ASummitKnightCrystalWall>(Projectile.Owner);	
		ActiveWall.Launch(KnightComp.Arena, WallSpeedFactor);
		UHazeActorRespawnableComponent::Get(ActiveWall).OnUnspawn.AddUFunction(this, n"OnWallExpire");
		//USummitKnightEventHandler::Trigger_OnLaunchCrystalWall(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
	}	


	UFUNCTION()
	private void OnWallExpire(AHazeActor RespawnableActor)
	{
		UHazeActorRespawnableComponent::Get(RespawnableActor).OnUnspawn.UnbindObject(this);
		if (RespawnableActor != ActiveWall)
			return;
		ActiveWall = nullptr;
	}
}


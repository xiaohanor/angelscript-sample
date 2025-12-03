class USummitKnightMetalWallBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USummitKnightSettings Settings;
	USummitKnightMetalWallLauncher Launcher;
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightStageComponent StageComp;
	
	FBasicAIAnimationActionDurations Durations;
	float LaunchTime;
	ASummitKnightMetalWall ActiveWall;
	AHazePlayerCharacter Target;
	float CenterYaw;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		Launcher = USummitKnightMetalWallLauncher::Get(Owner);
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
			if (!Settings.bMetalWallWaitForExpiration) 
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

		// Make sure we have a projectile available 
		Launcher.PrepareProjectiles(1);

	//	USummitKnightEventHandler::Trigger_OnTelegraphMetalWall(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));

		Durations.Telegraph = Settings.MetalWallTelegraphDuration;
		Durations.Anticipation = Settings.MetalWallAnticipationDuration;
		Durations.Action = Settings.MetalWallAttackDuration;
		Durations.Recovery = Settings.MetalWallRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::MetalWall, NAME_None, Durations);
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
		// Since this is crumbed we can be sure projectiles have been prepared.
		LaunchTime = BIG_NUMBER;
		UBasicAIProjectileComponent Projectile = Launcher.Launch(Launcher.WorldRotation.ForwardVector * Settings.MetalWallMoveSpeedTarget * 0.1);
		ActiveWall = Cast<ASummitKnightMetalWall>(Projectile.Owner);	
		ActiveWall.Launch(KnightComp.Arena);
		UHazeActorRespawnableComponent::Get(ActiveWall).OnUnspawn.AddUFunction(this, n"OnWallExpire");
		//USummitKnightEventHandler::Trigger_OnLaunchMetalWall(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
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

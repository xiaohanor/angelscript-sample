class USummitKnightSpinningSlashBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;

	bool bSpinning;	
	bool bRecovering;
	float StartDuration;
	float RecoverDuration;
	float LaunchTime;
	float LoopTime;

	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	USummitKnightSpinningSlashShockwaveLauncher Launcher;
	AHazePlayerCharacter TrackedPlayer;

	// We slide mesh forward some ways to reach arena
	UHazeSkeletalMeshComponentBase Mesh;
	FVector MeshLoc;

	float ShockwaveSpeedFactor = 1.0;
	float AnimTimeScale = 1.0;

	USummitKnightSpinningSlashBehaviour(float AnimPlayRate, float ProjectileSpeedFactor)
	{
		AnimTimeScale = AnimPlayRate;
		ShockwaveSpeedFactor = ProjectileSpeedFactor;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);

		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Launcher = USummitKnightSpinningSlashShockwaveLauncher::Get(Owner);
		Owner.GetComponentsByClass(Blades);

		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > GetRecoverTime() + RecoverDuration)	
			return true;
		return false;
	}

	float GetRecoverTime() const
	{
		return StartDuration + KnightAnimComp.SpinningSlashLoopDuration * Settings.SpinningSlashLoopNumber;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		StartDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::SpinningShockwave, SummitKnightSubTagsSpinningShockwave::Enter, Settings.SpinningSlashStartDuration);
		StartDuration *= AnimTimeScale;
		AnimComp.RequestFeature(SummitKnightFeatureTags::SpinningShockwave, SummitKnightSubTagsSpinningShockwave::Enter, EBasicBehaviourPriority::Medium, this, StartDuration);
		KnightAnimComp.SetSpinningSlashLoopDuration(Settings.SpinningSlashLoopDuration * AnimTimeScale);
		RecoverDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::SpinningShockwave, SummitKnightSubTagsSpinningShockwave::Exit, Settings.SpinningSlashRecoverDuration);

		Blades[0].Equip();

		bSpinning = false;
		bRecovering = false;
		LaunchTime = StartDuration;
		LoopTime = StartDuration;

		FVector OwnLoc = Owner.ActorLocation;
		TrackedPlayer = Game::Mio;
		if (OwnLoc.DistSquared2D(Game::Mio.ActorLocation) > OwnLoc.DistSquared2D(Game::Zoe.ActorLocation))
			TrackedPlayer = Game::Zoe;

		MeshLoc = Mesh.RelativeLocation;

		USummitKnightEventHandler::Trigger_OnSpinningSlashTelegraph(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Mesh.RelativeLocation = MeshLoc;
		if (HasControl() && (ActiveDuration < StartDuration))
			CrumbAborted();
		if (!bRecovering)
			USummitKnightEventHandler::Trigger_OnSpinningSlashEnd(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < StartDuration - 0.5)
		{
			FVector TargetLoc = TrackedPlayer.ActorLocation;
			if (Game::Mio.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, 5000.0))
				TargetLoc = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
			
			DestinationComp.RotateTowards(TargetLoc);	

			// Slide mesh to reach arena
			float Alpha = ActiveDuration / StartDuration;
			FVector SlideLoc = MeshLoc;
			SlideLoc.X = Math::EaseInOut(MeshLoc.X, Settings.SpinningSlashSlideForwardDistance, Alpha, 3.0);
			Mesh.RelativeLocation = SlideLoc;
		}
		else if (!bSpinning)
		{
			bSpinning = true;
			USummitKnightEventHandler::Trigger_OnSpinningSlashStart(Owner, FSummitKnightMeleeShockwaveParams(Blades[0]));
		}

		if ((ActiveDuration > LoopTime - 0.5) && !bRecovering)
		{
			// Trigger this at start of every loop (including first one)
			LoopTime += KnightAnimComp.SpinningSlashLoopDuration;
			USummitKnightEventHandler::Trigger_OnSpinningSlashStartLoop(Owner);
		}

		// Launch a shockwave for each spin 
		if (bSpinning && !bRecovering && (ActiveDuration > LaunchTime))
		{
			UBasicAIProjectileComponent Projectile = Launcher.Launch((KnightComp.Arena.Center - Owner.ActorLocation).GetSafeNormal2D() * Settings.SpinningSlashShockwaveMoveSpeed * ShockwaveSpeedFactor);	
			Cast<ASummitKnightSpinningSlashShockwave>(Projectile.Owner).Launch();

			// New launch next loop
			LaunchTime += KnightAnimComp.SpinningSlashLoopDuration;
		}

		if (ActiveDuration > GetRecoverTime())
		{
			if (!bRecovering)
			{
				// Start recovering
				bRecovering = true;
				AnimComp.RequestFeature(SummitKnightFeatureTags::SpinningShockwave, SummitKnightSubTagsSpinningShockwave::Exit, EBasicBehaviourPriority::Medium, this, RecoverDuration);
				USummitKnightEventHandler::Trigger_OnSpinningSlashEnd(Owner);
			}

			// Slide mesh back
			float Alpha = (ActiveDuration - GetRecoverTime()) / RecoverDuration;
			FVector SlideLoc = MeshLoc;
			SlideLoc.X = Math::EaseInOut(Settings.SpinningSlashSlideForwardDistance, MeshLoc.X, Alpha, 3.0);
			Mesh.RelativeLocation = SlideLoc;
		}

		if(bSpinning)
		{
			float FFFrequency = 50.0;
			float FFIntensity = 0.3;
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
			FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
			ForceFeedback::PlayWorldForceFeedbackForFrame(FF, Owner.ActorLocation, 1000, 3000);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbAborted()
	{
		USummitKnightEventHandler::Trigger_OnSpinningSlashAborted(Owner);
	}
}


class USummitDecimatorTopdownShockwaveJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownPhaseComponent PhaseComp;
	USummitDecimatorTopdownShockwaveLauncherComponent ShockwaveLauncherComp;
	UBasicAIAnimationComponent AnimComp;

	AAISummitDecimatorTopdown Decimator;

	USummitDecimatorTopdownSettings Settings;

	const float JumpAnimationSequenceLength = 4.067;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		ShockwaveLauncherComp = USummitDecimatorTopdownShockwaveLauncherComponent::Get(Owner);
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return false;

		if (PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::ShockwaveJumping)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return true;

		if (PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::ShockwaveJumping)
			return true;
		
		if (ActiveDuration > JumpAnimationSequenceLength)
			return true;

		return false;
	}

	FVector EntryForward;
	const float InitialSpeed = 10000;
	float HorizontalSpeed;
	float VerticalSpeed;
	FVector StartLocation;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		if (Owner.GetAttachParentActor() != nullptr )
			Owner.DetachFromActor(EDetachmentRule::KeepWorld);
				
		DecimatorTopdown::Animation::RequestFeatureShockwaveJumps(AnimComp, this);
		EntryForward = Owner.ActorForwardVector.GetSafeNormal2D();
		StartLocation = Owner.ActorLocation;
		NextLaunchTime = 0.45;
		NumJumps = 0;
		ShockwaveLauncherComp.SetRelativeLocation(FVector(100,0,0));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		PhaseComp.TryActivateNextAttackState();
		AnimComp.ClearFeature(this);
	}
	
	float NextLaunchTime;
	uint8 NumJumps;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (ActiveDuration > NextLaunchTime && NumJumps < 3)
		{
			ShockwaveLauncherComp.Launch();
			NextLaunchTime += 1.5 + NumJumps * 0.3;
			NumJumps++;
			Game::Mio.PlayCameraShake(Decimator.CameraShakeLight, this);
			Game::Zoe.PlayCameraShake(Decimator.CameraShakeLight, this);
		}
	}

};
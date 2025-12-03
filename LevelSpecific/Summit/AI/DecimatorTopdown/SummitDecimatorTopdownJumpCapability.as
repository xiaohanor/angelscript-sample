class USummitDecimatorTopdownJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownPhaseComponent PhaseComp;
	USummitDecimatorTopdownShockwaveLauncherComponent ShockwaveLauncherComp;
	USummitMeltComponent MeltComp;
	UBasicAIAnimationComponent AnimComp;
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	UAutoAimTargetComponent AutoAimComp;

	AAISummitDecimatorTopdown Decimator;
	AActor ArenaCenterScenePoint;
	USummitDecimatorTopdownSettings Settings;

	FVector ArenaCenterDir;
	float TimeScale = 1.0;
	float IdleTime;
	float RoarAnimationDuration = 0; // Temp set to 0. Actual sequence length is 4.333;
	float StartAnimationDelay = 0.35;
	const float JumpEnterAnimationSequenceLength = 5.067;

	bool bWasHit = false;
	bool bHasLanded = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		ShockwaveLauncherComp = USummitDecimatorTopdownShockwaveLauncherComponent::Get(Owner);
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
		ArenaCenterScenePoint = Owner.AttachmentRootActor;
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		TailAttackResponseComp = UTeenDragonTailAttackResponseComponent::Get(Owner);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		MeltComp = USummitMeltComponent::Get(Owner);
		AutoAimComp = UAutoAimTargetComponent::Get(Owner);
	}

	// Crumbed from player control side
	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!IsActive())
			return;

		if(!MeltComp.bMelted)
			return;

		if (PhaseComp.CurrentState != ESummitDecimatorState::JumpingDownRecover)
			return;

		if (bWasHit)
			return;

		Decimator.OnDecimatorDie.Broadcast();

		bWasHit = true;
		
		// Deactivate this capability
		PhaseComp.ChangeState(ESummitDecimatorState::TakingRollHitDamage);

		// Prepare animation state and collision response for next capability 
		AnimComp.ClearFeature(this);
		// Set to ignore collision. In tick will overlap check and knock away players anyway during spin in next state.
		DecimatorTopdown::Collision::SetPlayerIgnoreCollision(Decimator);
		AutoAimComp.bIsAutoAimEnabled = false;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::JumpingDown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::JumpingDown && PhaseComp.CurrentState != ESummitDecimatorState::JumpingDownRecover)
			return true;
		
		if (ActiveDuration > IdleTime + JumpEnterAnimationSequenceLength)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		if (Owner.GetAttachParentActor() != nullptr )
			Owner.DetachFromActor(EDetachmentRule::KeepWorld);

		ArenaCenterDir = (ArenaCenterScenePoint.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
		IdleTime = 90 / Settings.DecimatorTurnRate; // Time it takes for Decimator to face arena center

		AutoAimComp.bIsAutoAimEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!bWasHit) // Was already cleared in OnHitByRoll
		{
			AnimComp.ClearFeature(this);

			// Prevent pushing player through the floor by setting ignore collision.
			DecimatorTopdown::Collision::SetPlayerIgnoreCollision(Decimator);

			AutoAimComp.bIsAutoAimEnabled = false;
		}

		bHasLanded = false;
		bIsPlayingAnimation = false;
		bWasHit = false;

		// Only change state if no damage was taken during entry jump
		if (PhaseComp.CurrentState == ESummitDecimatorState::JumpingDown || PhaseComp.CurrentState == ESummitDecimatorState::JumpingDownRecover)
			PhaseComp.ChangeState(ESummitDecimatorState::RunningAttackSequence);
	}
		
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > StartAnimationDelay) // TODO: check if Idle Time would suffice
			StartAnimation();
		
		// Face arena
		if (ActiveDuration < IdleTime)
		{
			FVector NewDir = Owner.ActorForwardVector.RotateTowards(ArenaCenterDir, Settings.DecimatorTurnRate * DeltaTime);
			Owner.SetActorRotation(NewDir.Rotation());
			return;
		}
		else if (ActiveDuration < StartAnimationDelay + RoarAnimationDuration)
			return;

		if (ActiveDuration > (RoarAnimationDuration + 1.05 + IdleTime)) // TODO: replace with groundtrace
		{
			if (!bHasLanded)
			{
				ShockwaveLauncherComp.Launch();
				bHasLanded = true;
				Game::Mio.PlayCameraShake(Decimator.CameraShakeLight, this);
				Game::Zoe.PlayCameraShake(Decimator.CameraShakeLight, this);
				DecimatorTopdown::Collision::SetPlayerBlockingCollision(Decimator);
				PhaseComp.ChangeState(ESummitDecimatorState::JumpingDownRecover);
			}
		}
		


		float T = (ActiveDuration - IdleTime - RoarAnimationDuration) * TimeScale;
		float Eval = Decimator.EntryJumpCurve.GetFloatValue(T);
		
		FVector Location = Owner.ActorLocation;

		// Horizontal movement
		if ((ActiveDuration - IdleTime - RoarAnimationDuration) < 1.0)
			Location += ArenaCenterDir * 2500 * DeltaTime; // Forward movespeed
		
		// Vertical movement
		float JumpHeight = 2360;
		Location.Z = Decimator.HomeLocation.Z + Eval * JumpHeight;
		
		//PrintToScreen(f"{T=}");
		
		if (T > 1)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
			Trace.UseLine();

			FHitResult Obstruction = Trace.QueryTraceSingle(Owner.ActorLocation + FVector::UpVector * 100, Owner.ActorLocation + FVector::DownVector * 100);
			if (Obstruction.bBlockingHit)
				Owner.SetActorLocation(Obstruction.ImpactPoint);
		}
		else
		{
			Owner.SetActorLocation(Location);
		}

	}

	bool bIsPlayingAnimation = false;
	void StartAnimation()
	{
		if (bIsPlayingAnimation)
			return;

		bIsPlayingAnimation = true;

		DecimatorTopdown::Animation::RequestFeatureEnterPhaseThree(AnimComp, this);

		// FHazeSlotAnimSettings AnimSettings;
		// AnimSettings.BlendTime = 0.2;
		// AnimSettings.BlendOutTime = 0.2;
		// AnimSettings.PlayRate = 1.0;
		// Decimator.PlaySlotAnimation(Decimator.JumpEnterAnimation, AnimSettings); // temp
	}	
};
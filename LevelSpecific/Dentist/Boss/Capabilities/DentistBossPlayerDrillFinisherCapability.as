class UDentistBossPlayerDrillFinisherCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	UDentistBossSettings Settings;

	TPerPlayer<FHazeAcceleratedFloat> AccButtonMashProgress;
	TPerPlayer<float> PreviousPlayerButtonMashProgress;
	float PreviousButtonMashProgress;

	bool bDoubleInteractLockedIn = false;
	bool bButtonMashProgressCompleted = false;
	bool bTeethHitEventPlayed = false;

	const float TeethHitEventProgressThreshold = 0.5;
	const float FullBlendSpaceProgressPerSecond = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Settings = UDentistBossSettings::GetSettings(Dentist);

		Dentist.FinisherDoubleInteractActor.OnDoubleInteractionLockedIn.AddUFunction(this, n"OnDoubleInteractLockedIn");
		Dentist.FinisherDoubleInteractActor.OnEnterBlendedIn.AddUFunction(this, n"OnPlayerEnterInteractionBlendIn");
		Dentist.FinisherDoubleInteractActor.OnCancelBlendingIn.AddUFunction(this, n"OnPlayerCancelInteractionBlendIn");
		Dentist.FinisherDoubleInteractActor.OnCancelBlendingOut.AddUFunction(this, n"OnPlayerCancelInteractionBlendOut");
	}

	UFUNCTION()
	private void OnDoubleInteractLockedIn()
	{
		bDoubleInteractLockedIn = true;
		Dentist.FinisherDoubleInteractActor.AttachToComponent(Dentist.SkelMesh, n"LeftUpperForeArm", EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void OnPlayerEnterInteractionBlendIn(AHazePlayerCharacter Player,
	                                        ADoubleInteractionActor Interaction,
	                                        UInteractionComponent InteractionComponent)
	{
		Player.BlockCapabilities(n"ToothAnimation", this);

		if(Player.IsMio())
			Player.PlayBlendSpace(Settings.MioDrillFinisherPushBSParams);
		else
			Player.PlayBlendSpace(Settings.ZoeDrillFinisherPushBSParams);
		Player.SetBlendSpaceValues(0.0, -1.0, true);
	}

	UFUNCTION()
	private void OnPlayerCancelInteractionBlendIn(AHazePlayerCharacter Player,
	                                        ADoubleInteractionActor Interaction,
	                                        UInteractionComponent InteractionComponent)
	{
		Player.StopBlendSpace(0.0);
	}

	UFUNCTION()
	private void OnPlayerCancelInteractionBlendOut(AHazePlayerCharacter Player,
	                                                ADoubleInteractionActor Interaction,
	                                                UInteractionComponent InteractionComponent)
	{
		Player.UnblockCapabilities(n"ToothAnimation", this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!bDoubleInteractLockedIn)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bDoubleInteractLockedIn)
			return true;

		if(bButtonMashProgressCompleted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto Player : Game::Players)
		{
			auto ButtonMashSettings = Settings.DrillFinisherButtonMashSettings;
			ButtonMashSettings.WidgetAttachComponent = Player.RootComponent;
			if(Player.IsMio())
				ButtonMashSettings.WidgetPositionOffset = FVector(-90, 0.0, 130);
			else
				ButtonMashSettings.WidgetPositionOffset = FVector(90, 0.0, 130);
			Player.StartButtonMash(ButtonMashSettings, this);
			Player.SetButtonMashAllowCompletion(this, false);
			Player.ActivateCamera(Dentist.FinisherCamera, 1.0, this, EHazeCameraPriority::VeryHigh);
			AccButtonMashProgress[Player].SnapTo(0);

			Player.AttachToComponent(Dentist.SkelMesh, n"LeftUpperForeArm", EAttachmentRule::KeepWorld);

			auto HealthSettings = UPlayerHealthSettings::GetSettings(Player);
			HealthSettings.bGameOverWhenBothPlayersDead = true;
		}

		bButtonMashProgressCompleted = false;
		bTeethHitEventPlayed = false;

		FDentistBossEffectHandlerOnSelfDrillStartedParams EffectParams;
		EffectParams.HitRoot = Dentist.FinisherDrillNeckRoot;
		UDentistBossEffectHandler::Trigger_OnSelfDrillStarted(Dentist, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(auto Player : Game::Players)
		{
			Player.StopButtonMash(this);
			Player.DetachFromActor(EDetachmentRule::KeepWorld);

			Player.DeactivateCamera(Dentist.FinisherCamera, 1.0);
			
			Player.StopBlendSpace(0.0);
			
			auto ToothComp = UDentistToothPlayerComponent::Get(Player);
			ToothComp.AccRotation.SnapTo(Player.ActorQuat);
			ToothComp.AccTiltAmount.SnapTo(FVector::ZeroVector);
			Player.MeshOffsetComponent.ClearOffset(FInstigator(ToothComp, n"Rotation"));

			if(Player.IsMio())
				Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendingOut = FHazeAnimationDelegate(this, n"OnMioExitBlendOut"), PlaySlotAnimParams = Settings.MioDrillFinisherExitParams);
			else
				Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendingOut = FHazeAnimationDelegate(this, n"OnZoeExitBlendOut"), PlaySlotAnimParams = Settings.ZoeDrillFinisherExitParams);
		}

		Dentist.OnFinisherButtonMashCompleted.Broadcast();

		Dentist.bFinisherCompleted = true;
		bDoubleInteractLockedIn = false;
		FDentistBossEffectHandlerOnSelfDrillCompleteParams EffectParams;
		EffectParams.HitRoot = Dentist.FinisherDrillNeckRoot;
		UDentistBossEffectHandler::Trigger_OnSelfDrillComplete(Dentist, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ButtonMashProgress = 0.0;
		for(auto Player : Game::Players)
		{
			float ActualProgress = Player.GetButtonMashProgress(this);
			AccButtonMashProgress[Player].AccelerateToWithStop(ActualProgress, Settings.DrillFinisherButtonMashProgressDuration, DeltaTime, 0.01);
			ButtonMashProgress += AccButtonMashProgress[Player].Value;
		}

		float ProgressMadeThisFrame = ButtonMashProgress - PreviousButtonMashProgress;
		float CurrentProgressPerSecond = ProgressMadeThisFrame / DeltaTime;
		float PushBSAlpha = (CurrentProgressPerSecond / FullBlendSpaceProgressPerSecond);
		TEMPORAL_LOG(Dentist, "Finisher Sequence")
			.Value("Push BS Alpha", PushBSAlpha)
			.Value("Progress Made This Frame", ProgressMadeThisFrame)
			.Value("Current Progress Per Second", CurrentProgressPerSecond)
		;
		for(auto Player : Game::Players)
		{
			float PlayerPushBSAlpha = PushBSAlpha;
			float PlayerProgressMadeThisFrame = AccButtonMashProgress[Player].Value - PreviousPlayerButtonMashProgress[Player];
			// Player is not currently button mashing, animation is slowed down
			if(Math::IsNearlyZero(PlayerProgressMadeThisFrame))
				PlayerPushBSAlpha *= 0.5;
			// Converting alpha to BS Value which is -1 -> 1
			float PlayerPushBSValue = (PlayerPushBSAlpha * 2.0) - 1.0;

			TEMPORAL_LOG(Dentist, "Finisher Sequence")
				.Value(f"{Player}: Push BS Value", PlayerPushBSValue)
				.Value(f"{Player}: Accelerated Button Mash Progress", AccButtonMashProgress[Player].Value)
				.Value(f"{Player}: Previous Button Mash Progress", PreviousPlayerButtonMashProgress[Player])
			;
			Player.SetBlendSpaceValues(0.0, PlayerPushBSValue, true);

			PreviousPlayerButtonMashProgress[Player] = AccButtonMashProgress[Player].Value;

			auto Impact = GetGroundImpact(Player);
			FVector PlayerLocation = Player.ActorLocation;
			PlayerLocation.Z = Impact.Z; 
			Player.SetActorLocation(PlayerLocation);
		}
		PreviousButtonMashProgress = ButtonMashProgress;

		if(!bTeethHitEventPlayed
		&& ButtonMashProgress >= TeethHitEventProgressThreshold)
		{
			FDentistBossEffectHandlerOnSelfDrillHitTeethParams EffectParams;
			EffectParams.HitRoot = Dentist.FinisherDrillNeckRoot;
			UDentistBossEffectHandler::Trigger_OnSelfDrillHitTeeth(Dentist, EffectParams);
			bTeethHitEventPlayed = true;
		}

		if(ButtonMashProgress >= 1.0)
			bButtonMashProgressCompleted = true;
		Dentist.FinisherProgress = ButtonMashProgress;
		Dentist.SelfDrillAlpha = Math::GetMappedRangeValueClamped(FVector2D(TeethHitEventProgressThreshold, 1.0), FVector2D(0.0, 1.0), ButtonMashProgress);
 
		TEMPORAL_LOG(Dentist, "Finisher Sequence")
			.Value("Button Mash Progress", ButtonMashProgress)
			.Value("Self Drill Alpha", Dentist.SelfDrillAlpha)
		;
	}

	FVector GetGroundImpact(AHazePlayerCharacter Player)
	{	
		FVector GroundImpact;

		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(Player);
		Trace.UseLine();
		FVector Start = Player.ActorLocation + FVector::UpVector * 100;
		FVector End = Start + FVector::DownVector * 300.0;
		auto Hit = Trace.QueryTraceSingle(Start, End);
		if(!Hit.bBlockingHit)
			GroundImpact = Player.ActorLocation;
		else
			GroundImpact = Hit.ImpactPoint;

		return GroundImpact;
	}

	UFUNCTION()
	private void OnZoeExitBlendOut()
	{
		auto Player = Game::Zoe;
		auto ToothComp = UDentistToothPlayerComponent::Get(Player);
		FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, Player.ActorForwardVector);
		ToothComp.SetMeshWorldRotation(Rotation, this, 0.0);
		Player.UnblockCapabilities(n"ToothAnimation", this);
	}

	UFUNCTION()
	private void OnMioExitBlendOut()
	{
		auto Player = Game::Mio;
		auto ToothComp = UDentistToothPlayerComponent::Get(Player);
		FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, Player.ActorForwardVector);
		ToothComp.SetMeshWorldRotation(Rotation, this, 0.0);
		Player.UnblockCapabilities(n"ToothAnimation", this);
	}
};
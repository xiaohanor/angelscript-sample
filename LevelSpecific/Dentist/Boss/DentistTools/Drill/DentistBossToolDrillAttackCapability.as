struct FDentistBossToolDrillAttackActivationParams
{
	AHazePlayerCharacter DrillTarget;
}

enum EDentistBossDrillAttackState
{
	DelayBeforeAttack,
	MovingToAttack,
	Drilling,
	MovingBack,
}

class UDentistBossToolDrillAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolDrill Drill;
	UDentistBossTargetComponent TargetComp;

	UDentistToothMovementResponseComponent CurrentTargetMovementResponseComp;
	UPlayerHealthComponent PlayerHealthComp;
	UPlayerMovementComponent PlayerMoveComp;
	
	UDentistBossSettings Settings;

	EDentistBossDrillAttackState State;

	bool bButtonMashCompleted = false;
	bool bTargetDashedInto = false;
	bool bTutorialCompleted = false;
	bool bCompleted = false;

	FVector StartLocation;
	FRotator StartRotation;

	float TimeLastChangedState = -MAX_flt;

	const float TargetLocationUpOffset = 80.0;
	const float TargetLocationDrillDownOffset = 500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Drill = Cast<ADentistBossToolDrill>(Owner);
		Dentist = TListedActors<ADentistBoss>().Single;
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistBossToolDrillAttackActivationParams& Params) const
	{
		if(Drill.bIsDirected)
			return false;

		if(TargetComp.DrillTargets.Num() > 0)
		{
			auto Target = TargetComp.DrillTargets[TargetComp.DrillTargets.Num() - 1];
			if(Target.IsPlayerDead())
				return false;

			if(!TargetComp.IsOnCake[Target])
				return false;
			
			Params.DrillTarget = Target;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Drill.bIsDirected)
			return true;

		if(bCompleted)
			return true;

		if(!Drill.bActive)
			return true;

		if(Drill.TargetedPlayer.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistBossToolDrillAttackActivationParams Params)
	{
		Drill.TargetedPlayer = Params.DrillTarget;
		PlayerHealthComp = UPlayerHealthComponent::Get(Drill.TargetedPlayer);
		PlayerMoveComp = UPlayerMovementComponent::Get(Drill.TargetedPlayer);
		PlayerMoveComp.AddMovementIgnoresActor(this, Drill);
		TargetComp.Target.Apply(Drill.TargetedPlayer, this, EInstigatePriority::High);

		bButtonMashCompleted = false;
		bTargetDashedInto = false;
		bCompleted = false;
		Dentist.bDrillFoundPlayer = false;
		Dentist.bDrillFinished = false;
		Dentist.bDrillExit = false;

		TargetComp.DrillTelegraphDelay = 0; 

		SetNewState(EDentistBossDrillAttackState::DelayBeforeAttack);

		Dentist.CurrentAnimationState.Apply(EDentistBossAnimationState::Drill, this, EInstigatePriority::Low);

		Drill.DrillAlpha = 0.0;
		Drill.Activate();

		Drill.TargetedPlayer.ApplySettings(DentistBossNoHitReactionSettings, this, EHazeSettingsPriority::Override);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetComp.Target.Clear(this);

		if(Drill.TargetedPlayer.HasControl())
		{
			if(State == EDentistBossDrillAttackState::Drilling)
				CrumbStopDrilling();
		}

		if(!bCompleted)
			CrumbFinishMovingBackDrill();

		State = EDentistBossDrillAttackState::MovingBack;

		SetDrillLocationAndRotation(GetTargetLocation(), GetTargetRotation());

		Drill.DrillAlpha = 1.0;
		Dentist.DrillingPlayerWobble = 0.0;

		Dentist.CurrentAnimationState.Clear(this);
		Dentist.bDrillFinished = true;

		PlayerMoveComp.RemoveMovementIgnoresActor(this);
		Drill.TargetedPlayer.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeSinceChangedState = Time::GetGameTimeSince(TimeLastChangedState);

		TEMPORAL_LOG(Dentist, "Drill")
			.Value("State", State)
			.Value("Time Since Changed State", TimeSinceChangedState)
			.Value("Time Last Changed State", TimeLastChangedState)
			.Value("Target Dashed Into", bTargetDashedInto)
			.Value("Completed", bCompleted)
			.Value("Tutorial Completed", bTutorialCompleted)
			.Sphere("Start Location", StartLocation, 100, FLinearColor::Black, 10)
			.Rotation("Start Rotation", StartRotation, Drill.ActorLocation, 1000.0);
		;

		if(!TargetComp.IsOnCake[Drill.TargetedPlayer]
		&& State != EDentistBossDrillAttackState::MovingBack)
		{
			if(Drill.TargetedPlayer.HasControl())
			{
				if(State == EDentistBossDrillAttackState::Drilling)
					CrumbStopDrilling();
			}
			SetNewState(EDentistBossDrillAttackState::MovingBack);
		}

		switch(State)
		{
			case EDentistBossDrillAttackState::DelayBeforeAttack:
			{
				float Alpha = 0.0;
				if(TargetComp.DrillTelegraphDelay == 0)
					Alpha = 1.0;
				else
					Alpha = TimeSinceChangedState / TargetComp.DrillTelegraphDelay;

				if(Alpha >= 1.0)
				{
					SetNewState(EDentistBossDrillAttackState::MovingToAttack);
					Dentist.CurrentIKState.Apply(EDentistIKState::FullBody, this, EInstigatePriority::Normal);
					Dentist.bDrillFoundPlayer = true;
				}

				break;
			}
			case EDentistBossDrillAttackState::MovingToAttack:
			{
				float Alpha = TimeSinceChangedState / Settings.DrillAttackMoveDuration;
				if(Alpha < 1.0)
				{
					FVector NewLocation = Math::Lerp(StartLocation, GetTargetLocation(), Alpha);
					FRotator NewRotation = Math::LerpShortestPath(StartRotation, GetTargetRotation(), Alpha);
					SetDrillLocationAndRotation(NewLocation, NewRotation);
				}
				else
				{
					FVector NewLocation = GetTargetLocation();
					FRotator NewRotation = GetTargetRotation();
					SetDrillLocationAndRotation(NewLocation, NewRotation);
					if(Drill.TargetedPlayer.HasControl())
						CrumbHitPlayer();
					SetNewState(EDentistBossDrillAttackState::Drilling);
				}
				break;
			}
			case EDentistBossDrillAttackState::Drilling:
			{
				if(Drill.TargetedPlayer.HasControl())
					Drill.TargetedPlayer.DealBatchedDamageOverTime(Settings.DrillDamagePerSecond * DeltaTime, FPlayerDeathDamageParams());
				
				float Alpha = TimeSinceChangedState / Settings.DrillSplitOtherPlayerDuration;
				Drill.DrillAlpha = Alpha;

				Dentist.DrillingPlayerWobble = Math::FInterpTo(Dentist.DrillingPlayerWobble, 0.4, DeltaTime, 5.0);

				const FVector RelStartLocation = Drill.TargetedPlayer.ActorCenterLocation + FVector::UpVector * (TargetLocationUpOffset + SkelMeshDrillOffset);

				const float CurveAlpha = Settings.DrillMoveThroughPlayerCurve.GetFloatValue(Alpha);

				FVector NewLocation = Math::Lerp(RelStartLocation, GetTargetLocation(), CurveAlpha);
				FRotator NewRotation = GetTargetRotation();
				SetDrillLocationAndRotation(NewLocation, NewRotation);

				Drill.TargetedPlayer.ApplyManualFractionToCameraSettings(Alpha, this);

				Drill.TargetedPlayer.AddActorWorldRotation(FQuat(FVector::UpVector, 20 * DeltaTime));

				if(bButtonMashCompleted
				|| bTargetDashedInto
				|| Drill.TargetedPlayer.IsPlayerDead()
				|| Alpha >= 1.0)
				{
					if(Drill.TargetedPlayer.HasControl())
					{
						if(Alpha >= 1.0)
							CrumbSplitDrilledPlayer();

						CrumbStopDrilling();
					}
					SetNewState(EDentistBossDrillAttackState::MovingBack);
					Dentist.bDrillFoundPlayer = false;
				}
				break;
			}
			case EDentistBossDrillAttackState::MovingBack:
			{
				float Alpha = TimeSinceChangedState / Settings.DrillMoveBackDuration;
				if(Alpha < 1.0)
				{
					FVector NewLocation = Math::Lerp(StartLocation, GetTargetLocation(), Alpha);
					FRotator NewRotation = Math::LerpShortestPath(StartRotation, GetTargetRotation(), Alpha);
					SetDrillLocationAndRotation(NewLocation, NewRotation);
				}
				else
				{
					if(HasControl())
						CrumbFinishMovingBackDrill();
				}
				break;
			}
			default: break;
		}
	}

	const float SkelMeshDrillOffset = 860.0;
	FVector GetTargetLocation() const 
	{
		FVector TargetLocation;
		
		switch(State)
		{
			case EDentistBossDrillAttackState::MovingToAttack:
				TargetLocation = Drill.TargetedPlayer.ActorCenterLocation + FVector::UpVector * TargetLocationUpOffset + FVector::UpVector * SkelMeshDrillOffset;
				break;
			case EDentistBossDrillAttackState::Drilling:
				TargetLocation = Drill.TargetedPlayer.ActorCenterLocation + FVector::DownVector * 300 + FVector::UpVector * SkelMeshDrillOffset;
				break;
			case EDentistBossDrillAttackState::MovingBack:
				TargetLocation = Drill.TargetedPlayer.ActorCenterLocation + FVector::UpVector * TargetLocationUpOffset + FVector::UpVector * SkelMeshDrillOffset;
				break;
			default: TargetLocation =  FVector::ZeroVector;
		}
		
		TEMPORAL_LOG(Dentist, "Drill").Sphere("Target Location", TargetLocation, 100.0, FLinearColor::LucBlue);
		return TargetLocation;
	}

	FRotator GetTargetRotation() const 
	{
		FRotator TargetRotation;
		switch(State)
		{
			case EDentistBossDrillAttackState::MovingToAttack:
				TargetRotation = FRotator::MakeFromXZ(FVector::DownVector, Dentist.SkelMesh.ForwardVector);
				break;
			case EDentistBossDrillAttackState::Drilling:
				TargetRotation = FRotator::MakeFromXZ(FVector::DownVector, Dentist.SkelMesh.ForwardVector);
				break;
			case EDentistBossDrillAttackState::MovingBack:
				TargetRotation = FRotator::MakeFromXZ(FVector::DownVector, Dentist.SkelMesh.ForwardVector);
				break;
			default: TargetRotation = FRotator::ZeroRotator;
		}
	
		TEMPORAL_LOG(Dentist, "Drill").Rotation("Target Rotation", TargetRotation, Drill.ActorLocation, 1000.0);
		return TargetRotation;
	}

	void SetDrillLocationAndRotation(FVector NewLocation, FRotator NewRotation)
	{
		Dentist.SetIKTransform(EDentistBossArm::LeftTop, NewLocation, NewRotation);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHitPlayer()
	{
		ADentistBossToolChair Chair;
		if(Drill.TargetedPlayer.IsMio())
			Chair = Cast<ADentistBossToolChair>(Dentist.Tools[EDentistBossTool::MioChair]);
		else
			Chair = Cast<ADentistBossToolChair>(Dentist.Tools[EDentistBossTool::ZoeChair]);

		if(Chair.RestrainedPlayer.IsSet()
		&& Chair.RestrainedPlayer.Value == Drill.TargetedPlayer)
		{
			Chair.Deactivate();
			FDentistBossEffectHandlerOnChairDestroyedByDrillParams EffectParams;
			EffectParams.Chair = Chair;
			UDentistBossEffectHandler::Trigger_OnChairDestroyedByDrill(Dentist, EffectParams);
		}

		if(Settings.bDashExitOutOfDrill)
		{
			CurrentTargetMovementResponseComp = UDentistToothMovementResponseComponent::GetOrCreate(Drill.TargetedPlayer);
			CurrentTargetMovementResponseComp.OnDashImpact = EDentistToothDashImpactResponse::Backflip;
			CurrentTargetMovementResponseComp.OnDashedInto.AddUFunction(this, n"OnTargetDashedInto");
			auto DrillDashResponseComp = UDentistToothMovementResponseComponent::GetOrCreate(Drill);
			if(!DrillDashResponseComp.OnDashedInto.IsBound())
				DrillDashResponseComp.OnDashedInto.AddUFunction(this, n"OnTargetDashedInto");

			Drill.TargetedPlayer.CapsuleComponent.SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
			Drill.TargetedPlayer.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
			if(!bTutorialCompleted)
				Drill.TargetedPlayer.OtherPlayer.ShowTutorialPromptWorldSpace(Settings.DashOutOfDrillPrompt, this, Drill.TargetedPlayer.AttachmentRoot, ScreenSpaceOffset = 0.0);
		}
		else
		{
			Drill.TargetedPlayer.StartButtonMash(Settings.DrillButtonMashSettings, Dentist, FOnButtonMashCompleted(this, n"OnButtonMashCompleted"));
		}

		Drill.TargetedPlayer.PlayForceFeedback(Settings.BeingDrilledForceFeedback, true, false, Dentist);
		Drill.TargetedPlayer.PlayCameraShake(Settings.BeingDrilledCameraShake, Dentist);
		Drill.TargetedPlayer.SetActorVelocity(Drill.TargetedPlayer.ActorVelocity.ConstrainToDirection(FVector::DownVector));
		Drill.TargetedPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
		Drill.TargetedPlayer.BlockCapabilities(Dentist::Tags::Dash, this);
		Drill.TargetedPlayer.BlockCapabilities(Dentist::Tags::Jump, this);
		Drill.TargetedPlayer.BlockCapabilities(Dentist::Tags::GroundPound, this);
		Drill.TargetedPlayer.ApplyCameraSettings(Settings.BeingDrilledCameraSettings, 0.2, this, EHazeCameraPriority::High);
		// To be able to override camera shake
		Drill.TargetedPlayer.BlockCapabilities(n"DamageCameraShake", Dentist);

		if(!Settings.bDrillCanKill)
		{
			// Drill.TargetedPlayer.BlockCapabilities(n"Death", this);
			Drill.TargetedPlayer.AddDamageInvulnerability(this);
		}

		Drill.RequestComp.StartInitialSheetsAndCapabilities(Drill.TargetedPlayer, this);

		FDentistBossEffectHandlerOnDrillHitStartedParams EffectParams;
		EffectParams.PlayerRoot = Drill.TargetedPlayer.RootComponent;
		EffectParams.DrillHitRelativeLocation = FVector::UpVector * Drill.TargetedPlayer.ScaledCapsuleHalfHeight * 2.0;
		EffectParams.Player = Drill.TargetedPlayer;
		UDentistBossEffectHandler::Trigger_OnDrillHitStarted(Dentist, EffectParams);

		Drill.OnHitPlayer.Broadcast(Drill.TargetedPlayer);
		TargetComp.DrillTargets.RemoveSingleSwap(Drill.TargetedPlayer);

		TargetComp.bIsDrilling = true;

		auto ToothComp = UDentistToothPlayerComponent::Get(Drill.TargetedPlayer);
		ToothComp.bDrilled = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStopDrilling()
	{
		if(Settings.bDashExitOutOfDrill)
		{
			CurrentTargetMovementResponseComp.OnDashedInto.Unbind(this, n"OnTargetDashedInto");
			CurrentTargetMovementResponseComp = nullptr;
			auto DrillDashResponseComp = UDentistToothMovementResponseComponent::GetOrCreate(Drill);
			if(DrillDashResponseComp.OnDashedInto.IsBound())
				DrillDashResponseComp.OnDashedInto.Unbind(this, n"OnTargetDashedInto");
			Drill.TargetedPlayer.CapsuleComponent.SetCollisionObjectType(ECollisionChannel::PlayerCharacter);
			Drill.TargetedPlayer.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
			if(!bTutorialCompleted)
				Drill.TargetedPlayer.OtherPlayer.RemoveTutorialPromptByInstigator(this);
		}
		else
			Drill.TargetedPlayer.StopButtonMash(Dentist);

		Drill.TargetedPlayer.StopForceFeedback(Dentist);
		Drill.TargetedPlayer.StopCameraShakeByInstigator(Dentist);
		Drill.TargetedPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Drill.TargetedPlayer.UnblockCapabilities(Dentist::Tags::Dash, this);
		Drill.TargetedPlayer.UnblockCapabilities(Dentist::Tags::Jump, this);
		Drill.TargetedPlayer.UnblockCapabilities(Dentist::Tags::GroundPound, this);
		Drill.TargetedPlayer.ClearCameraSettingsByInstigator(this, 1.0);
		Drill.TargetedPlayer.UnblockCapabilities(n"DamageCameraShake", Dentist);

		if(!Settings.bDrillCanKill)
		{
			if(Drill.TargetedPlayer.IsMio())
				Timer::SetTimer(this, n"UnblockDeathOnMio", 0.5);
			else
				Timer::SetTimer(this, n"UnblockDeathOnZoe", 0.5);
		}

		FDentistBossEffectHandlerOnDrillStoppedParams EffectParams;
		EffectParams.Player = Drill.TargetedPlayer;
		UDentistBossEffectHandler::Trigger_OnDrillHitStopped(Dentist, EffectParams);

		Drill.OnStopped.Broadcast(Drill.TargetedPlayer);

		TargetComp.bIsDrilling = false;

		auto ToothComp = UDentistToothPlayerComponent::Get(Drill.TargetedPlayer);
		ToothComp.bDrilled = false;
	}

	UFUNCTION()
	void UnblockDeathOnZoe()
	{
		Game::Zoe.RemoveDamageInvulnerability(this);
		// Game::Zoe.UnblockCapabilities(n"Death", this);
	}

	UFUNCTION()
	void UnblockDeathOnMio()
	{
		Game::Mio.RemoveDamageInvulnerability(this);
		// Game::Mio.UnblockCapabilities(n"Death", this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSplitDrilledPlayer()
	{
		auto SplitComp = UDentistToothSplitComponent::Get(Drill.TargetedPlayer);
		SplitComp.bShouldSplit = true;
		Timer::SetTimer(this, n"ApplyPoITowardsSplitTooth", 0.2);

		Drill.TargetedPlayer.PlayCameraShake(Settings.ToothSplitCameraShake, this);
		Drill.TargetedPlayer.PlayForceFeedback(Settings.ToothSplitForceFeedback, false, true, this);

		Drill.TargetedPlayer.BlockCapabilities(n"DamageCameraShake", this);
		Drill.TargetedPlayer.DamagePlayerHealth(Settings.ToothSplitDamage);
		Drill.TargetedPlayer.UnblockCapabilities(n"DamageCameraShake", this);

		FDentistBossEffectHandlerOnDrillSplitToothParams SplitToothParams;
		SplitToothParams.Player = Drill.TargetedPlayer;
		UDentistBossEffectHandler::Trigger_OnDrillSplitTooth(Dentist, SplitToothParams);
	}

	UFUNCTION()
	void ApplyPoITowardsSplitTooth()
	{
		auto SplitComp = UDentistToothSplitComponent::Get(Drill.TargetedPlayer);
		SplitComp.bShouldSplit = true;
		FHazePointOfInterestFocusTargetInfo PoIInfo;
		PoIInfo.SetFocusToActor(SplitComp.SplitToothAI);
		Drill.TargetedPlayer.ApplyPointOfInterest(this, PoIInfo, Settings.SplitToothPoISettings, 2.0, EHazeCameraPriority::Medium);
	}

	UFUNCTION()
	private void OnTargetDashedInto(AHazePlayerCharacter DashPlayer, FVector Impulse, FHitResult Impact)
	{
		if(DashPlayer.HasControl())
		{
			CrumbGetDashedInto(DashPlayer);
			NetApplyDashImpulse(DashPlayer, Impulse);
		}
	}

	UFUNCTION(NetFunction)
	void NetApplyDashImpulse(AHazePlayerCharacter DashPlayer, FVector Impulse)
	{
		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(DashPlayer.OtherPlayer);
		if(ResponseComp == nullptr)
			return;

		auto RagdollSettings = UDentistToothDashSettings::GetSettings(DashPlayer.OtherPlayer).RagdollSettings;

		ResponseComp.OnImpulseFromObstacle.Broadcast(DashPlayer.OtherPlayer, Impulse, RagdollSettings);
	}

	UFUNCTION(CrumbFunction)
	void CrumbGetDashedInto(AHazePlayerCharacter DashPlayer)
	{
		bTargetDashedInto = true;
		if(!bTutorialCompleted)
		{
			DashPlayer.RemoveTutorialPromptByInstigator(this);
			bTutorialCompleted = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnButtonMashCompleted()
	{
		bButtonMashCompleted = true;
	}

	private void SetNewState(EDentistBossDrillAttackState NewState)
	{
		State = NewState;
		TimeLastChangedState = Time::GameTimeSeconds;

		TEMPORAL_LOG(Dentist, "Drill").Event(f"Set new State: {NewState}");

		StartLocation = Drill.ActorLocation;
		StartRotation = Drill.ActorRotation;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbFinishMovingBackDrill()
	{
		FVector NewLocation = GetTargetLocation();
		FRotator NewRotation = GetTargetRotation();
		SetDrillLocationAndRotation(NewLocation, NewRotation);
		Dentist.ClearIKState(this);
		bCompleted = true;
	}
};
class UDentistBossActionSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Input;

	ADentistBoss Dentist;
	ADentistBossCupManager CupManager;
	UDentistBossTargetComponent TargetComp;
	UDentistBossSettings Settings;

	UDentistBossCupSortingComponent NetworkedCupSortingComp;

	bool bDashToOpenCupTutorialShown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);		
		CupManager = TListedActors<ADentistBossCupManager>().Single;
		TargetComp = UDentistBossTargetComponent::Get(Dentist);
		Settings = UDentistBossSettings::GetSettings(Dentist);
		NetworkedCupSortingComp = Dentist.CupSortingComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Dentist.bIsActive)
			return false;

		if(!HasControl())
			return false;
		
		for(auto Comp : Dentist.ActionQueueComps)
		{
			if(!Comp.IsEmpty())
				return false;
		}
		
		if (NetworkedCupSortingComp.CupSorting.IsEmpty())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		switch(Dentist.CurrentState)
		{
			case EDentistBossState::Start:
			{
				TriggerStartEvent();
				ToggleLookAt(false);
				ToggleCamera(true, Dentist.StartCamera, EHazeSelectPlayer::Both, 1.0, EHazeCameraPriority::High);
				BlendViewSize(false, Game::Mio, EHazeViewPointBlendSpeed::Instant, EHazeViewPointSize::Fullscreen);
				Idle(DentistBossTimings::DrillEnterToggleDelay, 1);
				ToggleTool(EDentistBossTool::Drill, true, 1);
				SetAnimState(EDentistBossAnimationState::DrillChair, EInstigatePriority::Normal);
				BlockCapabilities(EHazeSelectPlayer::Both, CapabilityTags::Movement);
				BlockCapabilities(EHazeSelectPlayer::Both, CapabilityTags::Outline);
				BlockCapabilities(EHazeSelectPlayer::Both, CameraTags::CameraControl);
				BlockCapabilities(EHazeSelectPlayer::Both, n"StickWiggle");
				Idle(2.0);
				ToggleDrillSpinning(true);
				ChairRestraint(EHazeSelectPlayer::Both, true);
				Idle(3.0);
				UnblockCapabilities(EHazeSelectPlayer::Both, n"StickWiggle");
				SetState(EDentistBossState::RestrainedInChair);
				break;
			}
			case EDentistBossState::RestrainedInChair:
			{	
				WaitUntilEscapedFromChair();
				ToggleCamera(false, Dentist.StartCamera, EHazeSelectPlayer::Both, 2.0, EHazeCameraPriority::Low);
				BlendViewSize(true, Game::Mio, EHazeViewPointBlendSpeed::Normal);
				ClearQueue(2, 0);
				UnblockCapabilities(EHazeSelectPlayer::Both, CapabilityTags::Movement);
				UnblockCapabilities(EHazeSelectPlayer::Both, CameraTags::CameraControl);

				WaitUntilDoneDrilling();
				ToggleDrillSpinning(false); 
				Idle(DentistBossTimings::DrillExitToggleDelay);
				ToggleTool(EDentistBossTool::Drill, false);
				Idle(DentistBossTimings::DrillExit - DentistBossTimings::DrillExitToggleDelay);
				SetState(EDentistBossState::ToothBrushOne);
				ToggleLookAt(true);

				ClearAnimState();

				break;
			}
			case EDentistBossState::ToothBrushOne:
			{
				ToothBrushThenPaste();
				SetState(EDentistBossState::DentureSpawning);
				break;
			}
			case EDentistBossState::DentureSpawning:
			{
				SetAnimState(EDentistBossAnimationState::SpittingOutDentures, EInstigatePriority::Normal);
				DenturesAttack(true);
				SetState(EDentistBossState::DenturesSpawned);
				break;
			}
			case EDentistBossState::DenturesSpawned:
			{	
				IdleUntilDenturesDestroyed();
				SetNewStateBasedOnDenturesDestructionReason();
				break;
			}
			case EDentistBossState::CupSpawning:
			{
				SetAnimState(EDentistBossAnimationState::CupAttack, EInstigatePriority::Normal);
				AHazePlayerCharacter GrabPlayer = Game::Mio;
				CupGrabPlayer(true, GrabPlayer);
				CupSorting(true, GrabPlayer);
				WaitUntilSortingDone();
				WaitUntilCupIsChosen();
				Idle(DentistBossTimings::CupsFlattenStartDelay);
				FlattenCups(DentistBossTimings::CupScaleDownDuration);
				Idle(DentistBossTimings::CupFlatten - DentistBossTimings::CupsFlattenStartDelay - DentistBossTimings::CupScaleDownDuration);
				ClearAnimState();
				Idle(1.5);
				SetNewStateBasedOnCupSuccess();
				break;
			}
			case EDentistBossState::CupSuccessfullyChosen:
			{
				SetAnimState(EDentistBossAnimationState::HookAttack, EInstigatePriority::Normal);
				ScraperAttack(Game::Zoe);
				ClearAnimState();
				SetAnimState(EDentistBossAnimationState::Drill, EInstigatePriority::Normal);
				SwapTarget();
				LookAtSelectedPlayer(0.5);
				DrillAttackCurrentTarget(false);
				SetState(EDentistBossState::SpinningCake);
				break;
			}
			case EDentistBossState::CupPoorlyChosen:
			{
				SetAnimState(EDentistBossAnimationState::HookAttack, EInstigatePriority::Normal);
				ScraperAttack(Game::Zoe);
				ClearAnimState();
				SetAnimState(EDentistBossAnimationState::Drill, EInstigatePriority::Normal);
				SwapTarget();
				LookAtSelectedPlayer(0.5);
				DrillAttackCurrentTarget(false);
				SetState(EDentistBossState::SpinningCake);
				break;
			}
			case EDentistBossState::SpinningCake:
			{
				SetAnimState(EDentistBossAnimationState::Drill, EInstigatePriority::Normal);
				SelectTarget(nullptr);
				ToggleLookAt(false);
				Idle(1.0);
				StartCakeRotation();
				SetState(EDentistBossState::ToothBrushTwo);
				break;
			}
			case EDentistBossState::ToothBrushTwo:
			{
				ToothBrushAndPaste();
				SetState(EDentistBossState::HookTwo);
				break;
			}
			case EDentistBossState::HookTwo:
			{
				SetAnimState(EDentistBossAnimationState::HookAttack, EInstigatePriority::Normal);
				AHazePlayerCharacter HookTarget;
				if(TargetComp.LastPlayerHooked != nullptr)
					HookTarget = TargetComp.LastPlayerHooked.OtherPlayer;
				else
					HookTarget = GetRandomPlayer();
				ScraperAttack(HookTarget);
				ClearAnimState();

				SwapTarget();
				LookAtSelectedPlayer(0.5);
				DrillAttackCurrentTarget(false);
				Idle(1.0);
				SetState(EDentistBossState::DentureSpawningTwo);
				break;
			}
			case EDentistBossState::DentureSpawningTwo:
			{
				SetAnimState(EDentistBossAnimationState::SpittingOutDentures, EInstigatePriority::Normal);
				DenturesAttack(true);
				SetState(EDentistBossState::DenturesSpawnedTwo);
				break;
			}
			case EDentistBossState::DenturesSpawnedTwo:
			{	
				IdleUntilDenturesDestroyed();
				SetNewStateBasedOnDenturesDestructionReason();
				break;
			}
			case EDentistBossState::Defeated:
			{
				SetAnimState(EDentistBossAnimationState::FallOverOnArena, EInstigatePriority::High);
				SetIKState(EDentistIKState::None, EInstigatePriority::Normal);
				ToggleLookAt(false);
				ToggleTool(EDentistBossTool::Drill, true);
				ToggleDrillSpinning(true);
				StopRotatingCake();
				DefeatDentist();
				IdleUntilPlayersEnteredChaseTrigger();
				SetState(EDentistBossState::Chase);
				break;
			}
			case EDentistBossState::Debugging:
			{
				Idle(BIG_NUMBER);
				break;
			}
			default: break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	AHazePlayerCharacter GetRandomPlayer() const
	{
		int Rand = Math::RandRange(0, 1);
		return Rand == 0 ? Game::Zoe : Game::Mio; 
	}

	bool GetRandomBool() const
	{
		int Rand = Math::RandRange(0, 1);
		return Rand == 0 ? true : false; 
	}

	void SetState(EDentistBossState NewState, int QueueIndex = 0)
	{
		FDentistBossSetStateActivationParams Params;
		Params.NewState = NewState;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossSetStateCapability, 
			Params);
	}

	void TriggerStartEvent(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"TriggerStartEventDelegate");
	}

	UFUNCTION()
	void TriggerStartEventDelegate()
	{
		FDentistBossEffectHandlerOnSwitchedStateParams Params;
		Params.NewState = EDentistBossState::Start;
		UDentistBossEffectHandler::Trigger_OnSwitchedState(Dentist, Params);
	}

	void Idle(float Duration, int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Idle(Duration);
	}

	void IdleUntilPlayersEnteredChaseTrigger(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossIdleUntilPlayersEnteredChaseTriggerCapability);
	}

	void IdleUntilTargetIsAliveOnArena(AHazePlayerCharacter Target, bool bGetFromTargetComp = false, int QueueIndex = 0)
	{
		FDentistBossIdleUntilTargetIsAliveOnArenaParams Params;
		Params.Target = Target;
		Params.bGetFromTargetComp = bGetFromTargetComp;
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossIdleUntilTargetIsAliveOnArenaCapability, Params);
	}

	void SelectTargetAndLookAtThem(AHazePlayerCharacter Player, float LookDuration, int QueueIndex = 0)
	{
		SelectTarget(Player, QueueIndex);
		LookAtSelectedPlayer(LookDuration, QueueIndex);
	}

	void SelectTarget(AHazePlayerCharacter Target, int QueueIndex = 0)
	{
		FDentistBossSelectTargetActivationParams Params;
		Params.TargetPlayer = Target;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossSelectTargetCapability,
			Params);
	}

	void SwapTarget(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"SwapTargetDelegate");
	}

	UFUNCTION()
	void SwapTargetDelegate()
	{
		AHazePlayerCharacter Target = TargetComp.Target.Get();
		TargetComp.Target.Clear(Dentist);
		TargetComp.Target.Apply(Target.OtherPlayer, Dentist, EInstigatePriority::Normal);
	}

	void LookAtSelectedPlayer(float SwitchDuration, int QueueIndex = 0)
	{
		FDentistBossLookAtSelectedTargetActivationParams Params;
		Params.SwitchDuration = SwitchDuration;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossLookAtSelectedTargetCapability,
			Params);
	}

	void DefeatDentist(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"DefeatDentistDelegate");
	}

	UFUNCTION()
	void DefeatDentistDelegate()
	{
		Dentist.CrumbDie();
	}

	void StopRotatingCake(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"StopRotatingCakeDelegate");
	}

	UFUNCTION()
	void StopRotatingCakeDelegate()
	{
		Dentist.Cake.NetStopRotating(Time::GlobalCrumbTrailTime, Dentist.Cake.InnerCakeRoot.RelativeRotation.Yaw, Dentist.Cake.OuterCakeRoot.RelativeRotation.Yaw);
	}

	void ToggleLooping(int QueueIndex, bool bToggleOn, int ExecutingQueueIndex = 0)
	{
		FDentistBossQueueToggleLoopingActivationParams Params;
		Params.QueueIndex = QueueIndex;
		Params.bToggleOn = bToggleOn;
		Dentist.ActionQueueComps[ExecutingQueueIndex].Capability(
			UDentistBossQueueToggleLoopingCapability,
			Params
		);
	}

	void ClearQueue(int QueueIndex, int ExecutingQueueIndex = 0)
	{
		FDentistBossQueueClearActivationParams Params;
		Params.QueueIndex = QueueIndex;
		Dentist.ActionQueueComps[ExecutingQueueIndex].Capability(
			UDentistBossQueueClearCapability,
			Params
		);
	}

	// ANIM
	void SetAnimState(EDentistBossAnimationState NewState, EInstigatePriority Prio, int QueueIndex = 0)
	{
		FDentistBossSetAnimStateActivationParams Params;
		Params.NewState = NewState;
		Params.Prio = Prio;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossSetAnimStateCapability,
			Params);
	}

	void ClearAnimState(int QueueIndex = 0) 
	{ 
		FDentistBossSetAnimStateActivationParams Params;
		Params.bOnlyClear = true;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossSetAnimStateCapability,
			Params);
	} 

	void SetIKState(EDentistIKState NewState, EInstigatePriority Prio, int QueueIndex = 0)
	{
		FDentistBossSetIKStateActivationParams Params;
		Params.NewState = NewState;
		Params.Prio = Prio;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossSetIKStateCapability,
			Params);
	}

	void ClearIKState(int QueueIndex = 0) 
	{
		FDentistBossSetIKStateActivationParams Params;
		Params.bOnlyClear = true;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossSetIKStateCapability,
			Params);
	}

	void ToggleLookAt(bool bToggleOn, int QueueIndex = 0)
	{
		if(bToggleOn)
			Dentist.ActionQueueComps[QueueIndex].Event(this, n"ToggleLookAtOn");
		else
			Dentist.ActionQueueComps[QueueIndex].Event(this, n"ToggleLookAtOff");
	}

	UFUNCTION()
	private void ToggleLookAtOn()
	{
		if (HasControl())
			CrumbToggleLookAtOn();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbToggleLookAtOn()
	{
		Dentist.LookAtEnabled.Clear(this);
		Dentist.LookAtEnabled.Apply(true, this, EInstigatePriority::Normal);
	}

	UFUNCTION()
	private void ToggleLookAtOff()
	{
		if (HasControl())
			CrumbToggleLookAtOff();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbToggleLookAtOff()
	{
		Dentist.LookAtEnabled.Clear(this);
		Dentist.LookAtEnabled.Apply(false, this, EInstigatePriority::Normal);
	}

	void ToggleLeanBlendSpace(bool bToggleOn, int QueueIndex = 0)
	{
		FDentistBossToggleLeanBlendSpaceActivationParams Params;
		Params.bToggleOn = bToggleOn;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossToggleLeanBlendSpaceCapability,
			Params
		);
	}

	// BLOCKS
	void BlockTargetedPlayer(FName BlockTag, int QueueIndex = 0)
	{
		FDentistBossBlockCapabilitiesActivationParams Params;
		Params.bBlockTargetedPlayer = true;
		Params.CapabilityTag = BlockTag;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossBlockCapabilitiesCapability,
			Params);
	}

	void UnblockTargetedPlayer(FName BlockTag, int QueueIndex = 0)
	{
		FDentistBossUnblockCapabilitiesActivationParams Params;
		Params.bUnblockTargetedPlayer = true;
		Params.CapabilityTag = BlockTag;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossUnblockCapabilitiesCapability, 
			Params);
	}

	void BlockCapabilities(EHazeSelectPlayer PlayerSelection, FName BlockTag, int QueueIndex = 0)
	{
		FDentistBossBlockCapabilitiesActivationParams Params;
		Params.PlayerSelection = PlayerSelection;
		Params.CapabilityTag = BlockTag;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossBlockCapabilitiesCapability,
			Params);
	}

	void UnblockCapabilities(EHazeSelectPlayer PlayerSelection, FName BlockTag, int QueueIndex = 0)
	{
		FDentistBossUnblockCapabilitiesActivationParams Params;
		Params.PlayerSelection = PlayerSelection;
		Params.CapabilityTag = BlockTag;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossUnblockCapabilitiesCapability,
			Params);
	}

	// CAMERA
	void BlendViewSize(bool bClear, AHazePlayerCharacter ViewOverridePlayer, EHazeViewPointBlendSpeed Speed, EHazeViewPointSize Size = EHazeViewPointSize::MAX, int QueueIndex = 0)
	{
		FDentistBossBlendViewSizeActivationParams Params;
		Params.bClear = bClear;
		Params.ViewOverridePlayer = ViewOverridePlayer;
		Params.BlendSpeed = Speed;
		Params.BlendSize = Size;
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossBlendViewSizeCapability, Params);
	}

	void ToggleCamera(bool bToggleOn, AHazeCameraActor CameraToToggle, EHazeSelectPlayer PlayersToToggle, float BlendTime, EHazeCameraPriority CameraPrio, int QueueIndex = 0)
	{
		ToggleCamera(bToggleOn,	UHazeCameraComponent::Get(CameraToToggle), PlayersToToggle, BlendTime, CameraPrio, QueueIndex);
	}

	void ToggleCamera(bool bToggleOn, UHazeCameraComponent CameraToToggle, EHazeSelectPlayer PlayersToToggle, float BlendTime, EHazeCameraPriority CameraPrio, int QueueIndex = 0)
	{
		FDentistBossToggleCameraActivationParams Params;
		Params.bToggleOn = bToggleOn;
		Params.CameraToToggle = CameraToToggle;
		Params.PlayersToToggle = PlayersToToggle;
		Params.BlendTime = BlendTime;
		Params.CameraPrio = CameraPrio;
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossToggleCameraCapability, Params);
	}

	// TOOLS
	void ToggleTool(EDentistBossTool Tool, bool bToggleOn, int QueueIndex = 0)
	{
		FDentistBossToggleToolActivationParams Params;
		Params.bToggleOn = bToggleOn;
		Params.ToolToToggle = Tool;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossToggleToolCapability,
			Params);
	}

	void ResetTool(EDentistBossTool Tool, int QueueIndex = 0)
	{
		FDentistBossResetToolActivationParams Params;
		Params.ToolToReset = Tool;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossResetToolCapability,
			Params);
	}

	void ToggleToolAttachment(EDentistBossTool ToolToToggle, bool bAttach, USceneComponent ComponentToAttachTo = nullptr, FName BoneName = NAME_None
		, EAttachmentRule AttachRule = EAttachmentRule::SnapToTarget, EDetachmentRule DetachRule = EDetachmentRule::KeepWorld, int QueueIndex = 0)
	{
		FDentistBossToggleAttachmentToolActivationParams Params;
		Params.ToolToToggle = ToolToToggle;
		Params.bAttach = bAttach;
		Params.ComponentToAttachTo = ComponentToAttachTo;
		Params.BoneName = BoneName;
		Params.AttachmentRule = AttachRule;
		Params.DetachmentRule = DetachRule;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossToggleAttachmentToolCapability,
			Params);
	}

	void ToggleToolCollision(EDentistBossTool ToolToToggle, bool bToggleOn, int QueueIndex = 0)
	{
		FDentistBossToggleToolCollisionActivationParams Params;
		Params.bToggleOn = bToggleOn;
		Params.ToolToToggle = ToolToToggle;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossToggleToolCollisionCapability,
			Params);
	}


	// CHAIR
	void ChairRestraint(EHazeSelectPlayer RestraintSelection, bool bDeactivateChairOnCompleted = true, int QueueIndex = 0)
	{
		FDentistBossChairRestraintActivationParams Params;
		Params.RestraintSelection = RestraintSelection;
		Params.bDeactivateChairOnCompleted = bDeactivateChairOnCompleted;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossChairRestraintCapability,
			Params);
	}

	void RemoveChair(EHazeSelectPlayer PlayerSelection, int QueueIndex = 0)
	{
		FDentistBossChairRemovalActivationParams Params;
		Params.RemovalSelection = PlayerSelection;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossChairRemovalCapability,
			Params);
	}

	void WaitUntilEscapedFromChair(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossChairWaitUntilEscapedCapability);
	}

	// DRILL
	void DrillAttackCurrentTarget(bool bPlayExit, int QueueIndex = 0)
	{
		SetAnimState(EDentistBossAnimationState::Drill, EInstigatePriority::Normal, QueueIndex);
		Idle(DentistBossTimings::DrillEnterToggleDelay, QueueIndex);
		ToggleTool(EDentistBossTool::Drill, true, QueueIndex);
		ToggleDrillSpinning(true, QueueIndex);
		Idle(DentistBossTimings::DrillEnter - DentistBossTimings::DrillEnterToggleDelay, QueueIndex);
		IdleUntilTargetIsAliveOnArena(nullptr, true, QueueIndex);
		ToggleLeanBlendSpace(true, QueueIndex);
		AddTargetedPlayerToDrillTarget(QueueIndex);

		if(bPlayExit)
		{
			WaitUntilDoneDrilling(QueueIndex);
			TriggerDrillExitAnim(QueueIndex);
			ToggleLeanBlendSpace(false, QueueIndex);
			ToggleDrillSpinning(false, QueueIndex);
			Idle(DentistBossTimings::DrillExitToggleDelay, QueueIndex);
			ToggleTool(EDentistBossTool::Drill, false, QueueIndex);
			Idle(DentistBossTimings::DrillExit - DentistBossTimings::DrillExitToggleDelay, QueueIndex);
			ClearAnimState(QueueIndex);
		}
		else
		{
			WaitUntilDoneDrilling(QueueIndex);
			ToggleLeanBlendSpace(false, QueueIndex);
		}
	}

	void TriggerDrillExitAnim(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"CrumbTriggerDrillExitAnimEvent");
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbTriggerDrillExitAnimEvent()
	{
		Dentist.bDrillExit = true;
	}

	void WaitUntilDoneDrilling(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossDrillWaitUntilDoneDrillingCapability);
	}

	void AddTargetedPlayerToDrillTarget(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"AddTargetedPlayerToDrillTargetDelegate");
	}

	UFUNCTION()
	void AddTargetedPlayerToDrillTargetDelegate()
	{
		TargetComp.DrillTargets.AddUnique(TargetComp.Target.Get());
	}

	void ToggleDrillSpinning(bool bToggleOn, int QueueIndex = 0)
	{
		if(bToggleOn)
			Dentist.ActionQueueComps[QueueIndex].Event(this, n"CrumbStartSpinningDrill");
		else
			Dentist.ActionQueueComps[QueueIndex].Event(this, n"CrumbStopSpinningDrill");
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartSpinningDrill() { Cast<ADentistBossToolDrill>(Dentist.Tools[EDentistBossTool::Drill]).bSpinDrill = true; }

	UFUNCTION(CrumbFunction)
	void CrumbStopSpinningDrill() { Cast<ADentistBossToolDrill>(Dentist.Tools[EDentistBossTool::Drill]).bSpinDrill = false; }


	void StartCakeRotation(int QueueIndex = 0)
	{
		SetIKState(EDentistIKState::None, EInstigatePriority::Normal);
		FDentistBossDrillImpaleCakeActivationParams ImpaleParams;
		ImpaleParams.ImpaleDuration = DentistBossTimings::DrillSpinArena;
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossDrillImpaleCakeCapability, ImpaleParams);

		FDentistBossDrillRotateCakeActivationParams SpinParams;
		SpinParams.SpinDuration = Settings.DrillSpinCakeDuration;
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossDrillRotateCakeCapability, SpinParams);

		TriggerDrillExitAnim(QueueIndex);
		ToggleDrillSpinning(false, QueueIndex);
		Idle(DentistBossTimings::DrillExitToggleDelay, QueueIndex);
		ToggleTool(EDentistBossTool::Drill, false, QueueIndex);
		Idle(DentistBossTimings::DrillExit - DentistBossTimings::DrillExitToggleDelay, QueueIndex);
		ClearAnimState(QueueIndex);
		ToggleLeanBlendSpace(false, QueueIndex);
		ClearIKState();
	}

	void DrillTelegraphLoop(float DelayBetweenSwapping, int QueueIndex = 0)
	{
		ToggleLooping(2, true, 2);
		SelectTargetAndLookAtThem(Game::Mio, Settings.SwitchTargetDuration, QueueIndex);
		Idle(DelayBetweenSwapping, QueueIndex);
		SelectTargetAndLookAtThem(Game::Zoe, Settings.SwitchTargetDuration, QueueIndex);
		Idle(DelayBetweenSwapping, QueueIndex);
	}

	// DENTURES
	void DenturesAttack(bool bPlayEnter, int QueueIndex = 0)
	{
		TriggerDenturesAboutToBeReleased(QueueIndex);
		ToggleLookAt(false, QueueIndex);
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"DisableFollowOnDentures");
		if(bPlayEnter)
		{
			ResetTool(EDentistBossTool::Dentures, QueueIndex);
			Idle(DentistBossTimings::DenturesEnter, QueueIndex);
			ToggleTool(EDentistBossTool::Dentures, true, QueueIndex);
		}
		SpitOutDentures(DentistBossTimings::DenturesSpit, QueueIndex);

		Dentist.ActionQueueComps[QueueIndex].Event(this, n"EnableFollowOnDentures");

		ToggleLookAt(true, QueueIndex);
	}

	void TriggerDenturesAboutToBeReleased(int QueueIndex = 0) { Dentist.ActionQueueComps[QueueIndex].Event(this, n"TriggerDenturesAboutToBeReleasedEvent"); }

	UFUNCTION()
	private void TriggerDenturesAboutToBeReleasedEvent()
	{
		UDentistBossEffectHandler::Trigger_OnDenturesAboutToBeReleased(Dentist);
	}

	UFUNCTION()
	private void DisableFollowOnDentures()
	{
		auto Dentures = Cast<ADentistBossToolDentures>(Dentist.Tools[EDentistBossTool::Dentures]);
		Dentures.BlockCapabilities(DentistBossCapabilityTags::DentistMovementFollowCake, this);
	}

	UFUNCTION()
	private void EnableFollowOnDentures()
	{
		auto Dentures = Cast<ADentistBossToolDentures>(Dentist.Tools[EDentistBossTool::Dentures]);
		Dentures.UnblockCapabilities(DentistBossCapabilityTags::DentistMovementFollowCake, this);
	}

	void SpitOutDentures(float Duration, int QueueIndex = 0)
	{
		FDentistBossSpitOutDenturesActivationParams Params;
		Params.Duration = Duration;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossSpitOutDenturesCapability,
			Params);
	}

	void IdleUntilDenturesDestroyed(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossIdleUntilDenturesAreDestroyedCapability);
	}
	
	void SetNewStateBasedOnDenturesDestructionReason()
	{
		Dentist.ActionQueueComps[0].Event(this, n"SetNewStateBasedOnDenturesDestructionReasonDelegate");
	}

	UFUNCTION()
	void SetNewStateBasedOnDenturesDestructionReasonDelegate()
	{
		auto Dentures = Cast<ADentistBossToolDentures>(Dentist.Tools[EDentistBossTool::Dentures]);
		if(Dentures.bLastTimeDestroyedWasBecauseOfGrabberBeingDestroyed)
		{
			Idle(DentistBossTimings::DenturesDestroyedHand);
			SetState(EDentistBossState::CupSpawning);
		}
		else
		{
			Dentist.ActionQueueComps[0].Event(this, n"SetDenturesFellDownEvent");
			ToggleLookAt(false);
			Idle(DentistBossTimings::DenturesRespawnResetDelay);
			ResetTool(EDentistBossTool::Dentures);
			Idle(DentistBossTimings::DenturesRespawn - DentistBossTimings::DenturesRespawnResetDelay);
			ToggleTool(EDentistBossTool::Dentures, true);
			DenturesAttack(false);
			SetState(EDentistBossState::DenturesSpawned);
			ToggleLookAt(true);
		}
	}

	UFUNCTION()
	void SetDenturesFellDownEvent()
	{
		Dentist.bDenturesFellDown = true;
	}

	// TOOTH BRUSH
	void ToothBrushAttack(float MoveDuration, float BrushDuration, bool bBrushFromRight, int QueueIndex = 0)
	{
		FDentistBossToothBrushAttackActivationParams Params;
		Params.Duration = BrushDuration;
		Params.MoveDuration = MoveDuration;
		Params.bBrushFromRight = bBrushFromRight;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossToothBrushAttackCapability,
			Params);
	}

	void ToothBrushThenPaste()
	{
		SelectTarget(nullptr);
		SetAnimState(EDentistBossAnimationState::ToothBrush, EInstigatePriority::Normal);

		ToggleToolCollision(EDentistBossTool::ToothBrush, false);
		Idle(DentistBossTimings::ToothBrushEnterToggleDelay, 1);
		ToggleTool(EDentistBossTool::ToothBrush, true, 1);
		ToggleTool(EDentistBossTool::ToothPasteTube, true, 1);
		Idle(DentistBossTimings::ToothBrushEnter);
		ToggleLookAt(false);
		ToothBrushAttack(0.0, DentistBossTimings::ToothBrushFromRight, true);
		ToggleLookAt(true);
		ToothPasteAttack(DentistBossTimings::ToothPasteAttack, GetRandomPlayer(), Settings.ToothPasteCount);
		ToggleLookAt(false);
		ToothBrushAttack(0.0, DentistBossTimings::ToothBrushFromLeft, false);
		ToggleLookAt(true);
		Idle(DentistBossTimings::ToothBrushExitToggleDelay);
		ToggleTool(EDentistBossTool::ToothBrush, false);
		ToggleTool(EDentistBossTool::ToothPasteTube, false);
		Idle(DentistBossTimings::ToothBrushExit - DentistBossTimings::ToothBrushExitToggleDelay);
		ToggleToolCollision(EDentistBossTool::ToothBrush, true);
	}

	void ToothBrushAndPaste()
	{
		SelectTarget(nullptr);
		SetAnimState(EDentistBossAnimationState::ToothBrush, EInstigatePriority::Normal);

		Idle(DentistBossTimings::ToothBrushEnterToggleDelay);
		ToggleTool(EDentistBossTool::ToothBrush, true);
		ToggleTool(EDentistBossTool::ToothPasteTube, true);
		Idle(DentistBossTimings::ToothBrushEnter - DentistBossTimings::ToothBrushEnterToggleDelay);

		ToggleToolCollision(EDentistBossTool::ToothBrush, false);
		ToothPasteAttack(DentistBossTimings::ToothPasteAttack, GetRandomPlayer(), Settings.ToothPasteCount);
		ToggleLookAt(false);
		ToothBrushAttack(0.0, DentistBossTimings::ToothBrushFromRight, true);
		ToggleLookAt(true);
		ToothPasteAttack(DentistBossTimings::ToothPasteAttack, GetRandomPlayer(), Settings.ToothPasteCount);
		ToggleLookAt(false);
		ToothBrushAttack(0.0, DentistBossTimings::ToothBrushFromLeft, false);
		ToggleLookAt(true);
		Idle(DentistBossTimings::ToothBrushExitToggleDelay);
		ToggleTool(EDentistBossTool::ToothBrush, false);
		ToggleTool(EDentistBossTool::ToothPasteTube, false);
		Idle(DentistBossTimings::ToothBrushExit - DentistBossTimings::ToothBrushExitToggleDelay);
		ToggleToolCollision(EDentistBossTool::ToothBrush, true);
	}

	// CUPS
	void CupGrabPlayer(bool bIsLeftGrabber, AHazePlayerCharacter Target, int QueueIndex = 0)
	{
		ResetTool(EDentistBossTool::CupMiddle, QueueIndex);
		ResetTool(EDentistBossTool::CupLeft, QueueIndex);
		ResetTool(EDentistBossTool::CupRight, QueueIndex);

		SelectTargetAndLookAtThem(Target, Settings.LookDuration, QueueIndex);
		Idle(DentistBossTimings::CupsEnterToggleDelay, QueueIndex);
		ToggleTool(EDentistBossTool::CupLeft, true, QueueIndex);
		ToggleTool(EDentistBossTool::CupMiddle, true, QueueIndex);
		ToggleTool(EDentistBossTool::CupRight, true, QueueIndex);
		
		const EDentistBossTool CaptureCup = EDentistBossTool::CupLeft;
		ToggleToolAttachment(CaptureCup, true, Dentist.SkelMesh, Dentist.LeftUpperAttach, QueueIndex = QueueIndex);
		ToggleToolAttachment(EDentistBossTool::CupMiddle, true, Dentist.SkelMesh, Dentist.RightUpperAttach, QueueIndex = QueueIndex);
		ToggleToolAttachment(EDentistBossTool::CupRight, true, Dentist.SkelMesh, Dentist.Align, QueueIndex = QueueIndex);

		Idle(DentistBossTimings::CupsEnter - DentistBossTimings::CupsEnterToggleDelay, QueueIndex);
		IdleUntilTargetIsAliveOnArena(Target, QueueIndex = QueueIndex);
		SetIKState(EDentistIKState::FullBody, EInstigatePriority::Normal, QueueIndex);
		ToggleLeanBlendSpace(true, QueueIndex);

		MoveCupOverTarget(DentistBossTimings::CupTelegraph, bIsLeftGrabber, CaptureCup, QueueIndex);
		CaptureTargetWithCup(DentistBossTimings::CupCatchMoveDown, bIsLeftGrabber, CaptureCup, QueueIndex);
		ToggleLeanBlendSpace(false, QueueIndex);
		MoveBackCup(DentistBossTimings::CupCatch - DentistBossTimings::CupCatchMoveDown, CaptureCup, QueueIndex);
		ClearIKState();

		SelectTargetAndLookAtThem(Target.OtherPlayer, Settings.LookDuration, QueueIndex);
	}

	void CupSorting(bool bIsLeftGrabber, AHazePlayerCharacter Target, int QueueIndex = 0)
	{
		FDentistCupSortParams Params;
		Params.TargetedPlayer = Target;
		Params.bIsLeftGrabber = bIsLeftGrabber;
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"StartCupSorting", Params);
	}

	UFUNCTION()
	void StartCupSorting(FDentistCupSortParams Params)
	{
		CrumbStartCupSorting(Params);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartCupSorting(FDentistCupSortParams Params)
	{
		UDentistBossCupSortingComponent CupSortingComp = UDentistBossCupSortingComponent::GetOrCreate(Dentist);
		CupSortingComp.DoTheLocalCupSorting(Params);
	}

	void CupSortingComplete(AHazePlayerCharacter CaughtPlayer, int QueueIndex = 0)
	{
		if(CaughtPlayer.IsMio())
			Dentist.ActionQueueComps[QueueIndex].Event(this, n"CupSortingCompleteMioCaught");
		else
			Dentist.ActionQueueComps[QueueIndex].Event(this, n"CupSortingCompleteZoeCaught");
	}	

	UFUNCTION()
	void CupSortingCompleteMioCaught()
	{
		CrumbCupSortingCompleteCaught(Game::Mio);
	}

	UFUNCTION()
	void CupSortingCompleteZoeCaught()
	{
		CrumbCupSortingCompleteCaught(Game::Zoe);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCupSortingCompleteCaught(AHazePlayerCharacter CaughtPlayer)
	{
		CupManager.bCupSortingFinished = true;
		FDentistBossEffectHandlerOnCupMovementStoppedParams Params;
		Params.PlayerCaughtByCup = CaughtPlayer;
		UDentistBossEffectHandler::Trigger_OnCupMovementStoppedParams(Dentist, Params);
	}

	void MoveCupOverTarget(float Duration, bool bIsLeftGrabber, EDentistBossTool CupType, int QueueIndex = 0)
	{
		FDentistBossCupMoveOverPlayerActivationParams Params;
		Params.CupType = CupType;
		Params.MoveDuration = Duration;
		Params.bIsLeftGrabber = bIsLeftGrabber;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossCupMoveOverPlayerCapability,
			Params);
	}

	void CaptureTargetWithCup(float Duration, bool bIsLeftGrabber, EDentistBossTool CupType, int QueueIndex = 0)
	{
		FDentistBossCupCapturePlayerActivationParams Params;
		Params.CaptureDuration = Duration;
		Params.bIsLeftGrabber = bIsLeftGrabber;
		Params.CupType = CupType;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossCupCapturePlayerCapability,
			Params);
	}

	void MoveBackCup(float MoveDuration, EDentistBossTool CupType, int QueueIndex = 0)
	{
		FDentistBossCupMoveBackActivationParams Params;
		Params.MoveDuration = MoveDuration;
		Params.CupType = CupType;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossCupMoveBackCapability,
			Params);
	}

	void FlattenCups(float Duration, int QueueIndex = 0)
	{
		FDentistBossFlattenCupsActivationParams Params;
		Params.FlattenDuration = Duration;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossFlattenCupsCapability, 
			Params);
	}

	void SortSequence(EDentistBossToolCupSortType SortType, bool bIsFlipped, float Duration, int QueueIndex = 0)
	{
		FDentistBossCupSortSequenceActivationParams Params;
		Params.Duration = Duration;

		if(SortType == EDentistBossToolCupSortType::Left)
		{
			if(bIsFlipped)
				Params.SortType = EDentistBossToolCupSortType::Right;
			else
				Params.SortType = EDentistBossToolCupSortType::Left;
		}
		else if(SortType == EDentistBossToolCupSortType::Right)
		{
			if(bIsFlipped)
				Params.SortType = EDentistBossToolCupSortType::Left;
			else
				Params.SortType = EDentistBossToolCupSortType::Right;
		}
		else if(SortType == EDentistBossToolCupSortType::Sides)
			Params.SortType = EDentistBossToolCupSortType::Sides;

		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossCupCupSortSequenceCapability,
			Params);
	}

	void TargetCupRestrainedPlayer(int QueueIndex = 0)
	{
		FDentistBossCupTargetRestrainedPlayerActivationParams Params;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossCupTargetRestrainedPlayerCapability,
			Params);
	}

	void OpenRemainingCups(int QueueIndex = 0)
	{
		FDentistBossCupOpenRemainingCupsActivationParams Params;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossCupOpenRemainingCupsCapability,
			Params);
	}

	void ShowDashIntoCupTutorial(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossCupShowDashTutorialCapability);
	}

	void WaitUntilSortingDone(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossCupWaitUntilSortCompleteCapability);
	}

	void WaitUntilCupIsChosen(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossCupWaitUntilChosenCapability);
	}

	void SetNewStateBasedOnCupSuccess(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"SetNewStateBasedOnCupSuccessDelegate");
	}

	UFUNCTION()
	void SetNewStateBasedOnCupSuccessDelegate()
	{
		if(CupManager.ChosenCup.Value.RestrainedPlayer.IsSet())
			SetState(EDentistBossState::CupSuccessfullyChosen);
		else
			SetState(EDentistBossState::CupPoorlyChosen);
	}

	// SCRAPER
	void ScraperAttack(AHazePlayerCharacter Target, int QueueIndex = 0)
	{
		SelectTarget(Target, QueueIndex);
		EHazeSelectPlayer Player;
		if(Target.IsMio())
			Player = EHazeSelectPlayer::Mio;
		else
			Player = EHazeSelectPlayer::Zoe;
		
		Idle(DentistBossTimings::HookHammerEnterToggleDelay, QueueIndex);
		ToggleTool(EDentistBossTool::Hammer, true, QueueIndex);
		ToggleTool(EDentistBossTool::Scraper, true, QueueIndex);
		ToggleToolCollision(EDentistBossTool::Scraper, false, QueueIndex);
		Idle(DentistBossTimings::HookHammerEnter - DentistBossTimings::HookHammerEnterToggleDelay, QueueIndex);

		IdleUntilTargetIsAliveOnArena(Target, QueueIndex = QueueIndex);
		ToggleLeanBlendSpace(true, QueueIndex);
		ScraperGrabPlayer(DentistBossTimings::HookCapturePlayer, DentistBossTimings::HookTelegraph, DentistBossTimings::HookDragBack, QueueIndex);
		ToggleLeanBlendSpace(false, QueueIndex);
		ToggleToolCollision(EDentistBossTool::Scraper, true, QueueIndex);
		
		ToggleCamera(true, Dentist.HookedCamera, Player, 2.0, EHazeCameraPriority::Medium, QueueIndex);
		Idle(2.0, QueueIndex);

		HammerHitScraper(DentistBossTimings::HammerHitImpactDelay, Target, QueueIndex);
		Idle(DentistBossTimings::HammerHit - DentistBossTimings::HammerHitImpactDelay, QueueIndex);
		Idle(0.1, QueueIndex);

		HammerHitScraper(DentistBossTimings::HammerHitImpactDelay, Target, QueueIndex);
		Idle(DentistBossTimings::HammerHit - DentistBossTimings::HammerHitImpactDelay, QueueIndex);
		Idle(0.3, QueueIndex);

		HammerHitScraper(DentistBossTimings::HammerHitImpactDelay, Target, QueueIndex);
		SplitToothWithHammer(QueueIndex);
		ToggleCamera(false, Dentist.HookedCamera, Player, 2.0, EHazeCameraPriority::Medium, QueueIndex);
		Idle(DentistBossTimings::HammerHit - DentistBossTimings::HammerHitImpactDelay, QueueIndex);
		
		TriggerScraperExitAnim(QueueIndex);
		ToggleToolCollision(EDentistBossTool::Scraper, false, QueueIndex);
		Idle(DentistBossTimings::HookHammerExitToggleDelay, QueueIndex);
		ToggleTool(EDentistBossTool::Hammer, false, QueueIndex);
		ToggleTool(EDentistBossTool::Scraper, false, QueueIndex);
		Idle(DentistBossTimings::HookHammerExit - DentistBossTimings::HookHammerExitToggleDelay);
		ToggleToolCollision(EDentistBossTool::Scraper, true, QueueIndex);
	}

	void ScraperGrabPlayer(float MoveDuration, float TelegraphDuration, float DragBackDuration, int QueueIndex = 0)
	{
		FDentistBossScraperGrabPlayerActivationParams Params;
		Params.MoveDuration = MoveDuration;
		Params.TelegraphDuration = TelegraphDuration;
		Params.DragBackDuration = DragBackDuration;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossScraperGrabPlayerCapability,
			Params);
	}

	void ScraperMoveBackBeforeSmash(float MoveDuration, int QueueIndex = 0)
	{
		FDentistBossScraperMoveBackBeforeSmashActivationParams Params;
		Params.MoveDuration = MoveDuration;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossScraperMoveBackBeforeSmashCapability,
			Params);
	}

	void TriggerScraperExitAnim(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Event(this, n"TriggerScraperExitAnimEvent");
	}

	UFUNCTION()
	void TriggerScraperExitAnimEvent()
	{
		Dentist.bHammerSplitPlayer = true;
	}

	// HAMMER
	void HammerHitScraper(float MoveDuration, AHazePlayerCharacter Target, int QueueIndex = 0)
	{
		FDentistBossHammerHitScraperActivationParams Params;
		Params.MoveDuration = MoveDuration;
		Params.Target = Target;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossHammerHitScraperCapability,
			Params);
	}

	void SplitToothWithHammer(int QueueIndex = 0)
	{
		Dentist.ActionQueueComps[QueueIndex].Capability(UDentistBossHammerSplitToothCapability);
	}

	// TOOTH PASTE TUBE
	void ToothPasteAttack(float Duration, AHazePlayerCharacter Target, int ToothPasteCount, int QueueIndex = 0)
	{
		FDentistBossToothPasteTubeLobToothPasteActivationParams Params;
		Params.DelayBetweenLobs = 0.05;
		Params.TargetPlayer = Target;
		Params.ToothPasteLobCount = ToothPasteCount;
		Params.Duration = Duration;
		Dentist.ActionQueueComps[QueueIndex].Capability(
			UDentistBossToothPasteTubeLobToothPasteCapability,
			Params);
	}

	// DEV FUNCTIONS
	UFUNCTION(DevFunction)
	void Dev_SetBossState(EDentistBossState NewState)
	{
		ResetBoss();
		if(!HasControl())
			return;
		Dentist.ProgressToState(NewState);
		SetState(NewState);
	}

	UFUNCTION(DevFunction)
	void Dev_DrillAttack(EHazeSelectPlayer Target)
	{
		ResetBoss();
		if(!HasControl())
			return;

		AHazePlayerCharacter Player = Target == EHazeSelectPlayer::Mio ? Game::Mio : Game::Zoe;
		SelectTargetAndLookAtThem(Player, 0.0);
		DrillAttackCurrentTarget(true);
	}

	UFUNCTION(DevFunction)
	void Dev_DenturesSpawnAttack()
	{
		ResetBoss();
		if(!HasControl())
			return;
		SetAnimState(EDentistBossAnimationState::SpittingOutDentures, EInstigatePriority::High);
		DenturesAttack(true);
	}

	UFUNCTION(DevFunction)
	void Dev_DenturesSpawnWithoutEnergy()
	{
		ResetBoss();
		if(!HasControl())
			return;

		ToggleTool(EDentistBossTool::Dentures, true);
		SetAnimState(EDentistBossAnimationState::SpittingOutDentures, EInstigatePriority::High);
		CrumbPlaceDenturesOnTopOfCakeWithoutEnergy();
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlaceDenturesOnTopOfCakeWithoutEnergy()
	{
		auto Dentures = Cast<ADentistBossToolDentures>(Dentist.Tools[EDentistBossTool::Dentures]);
		Dentures.DetachFromActor(EDetachmentRule::KeepWorld);
		Dentures.ActorLocation = Dentist.Cake.ActorLocation + FVector::UpVector * 500;
		Dentures.bIsAttachedToJaw = false;
		Dentures.bHasLandedOnGround = true;
		Dentures.HealthComp.TakeDamage(1.0, EDamageType::Default, Dentist);
		Dentures.EyesSpringinessEnabled.Clear(Dentures);
	}

	UFUNCTION(DevFunction)
	void Dev_ToothBrushAttackThenPaste()
	{
		ResetBoss();
		if(!HasControl())
			return;
		ToothBrushThenPaste();
	}

	UFUNCTION(DevFunction)
	void Dev_ToothBrushAttackWithPaste()
	{
		ResetBoss();
		if(!HasControl())
			return;
		ToothBrushAndPaste();
	}

	UFUNCTION(DevFunction)
	void Dev_CupAttack(EHazeSelectPlayer Target)
	{
		ResetBoss();
		if(!HasControl())
			return;
		AHazePlayerCharacter Player = Target == EHazeSelectPlayer::Mio ? Game::Mio : Game::Zoe;
		SetAnimState(EDentistBossAnimationState::CupAttack, EInstigatePriority::High);
		CupGrabPlayer(true, Player);
		CupSorting(true, Player);
		WaitUntilSortingDone();
		WaitUntilCupIsChosen();
		Idle(DentistBossTimings::CupsFlattenStartDelay);
		FlattenCups(DentistBossTimings::CupScaleDownDuration);
		Idle(DentistBossTimings::CupFlatten - DentistBossTimings::CupsFlattenStartDelay - DentistBossTimings::CupScaleDownDuration);
		ClearAnimState();
	}

	UFUNCTION(DevFunction)
	void Dev_CupInstantCapture(EHazeSelectPlayer Target)
	{
		ResetBoss();
		if(!HasControl())
			return;
		AHazePlayerCharacter Player = Target == EHazeSelectPlayer::Mio ? Game::Mio : Game::Zoe;
		SelectTarget(Player);
		ToggleTool(EDentistBossTool::CupLeft, true);
		ToggleTool(EDentistBossTool::CupMiddle, true);
		ToggleTool(EDentistBossTool::CupRight, true);
		CaptureTargetWithCup(0.0, true, EDentistBossTool::CupMiddle);	
		auto LeftCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupLeft]);
		LeftCup.PutCupAtTarget();
		auto MiddleCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupMiddle]);
		MiddleCup.PutCupAtTarget();
		auto RightCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupRight]);
		RightCup.PutCupAtTarget();
		SelectTarget(Player);
		Player.TeleportActor(Dentist.Cake.ActorLocation, FRotator::MakeFromXZ(-Dentist.Cake.ActorRightVector, FVector::UpVector), this);
	}

	UFUNCTION(DevFunction)
	void Dev_CupFlattenWithPlayer(EHazeSelectPlayer Target)
	{
		ResetBoss();
		if(!HasControl())
			return;
		SetAnimState(EDentistBossAnimationState::CupAttack, EInstigatePriority::High);
		AHazePlayerCharacter Player = Target == EHazeSelectPlayer::Mio ? Game::Mio : Game::Zoe;
		SelectTarget(Player);
		ToggleTool(EDentistBossTool::CupLeft, true);
		ToggleTool(EDentistBossTool::CupMiddle, true);
		ToggleTool(EDentistBossTool::CupRight, true);
		CaptureTargetWithCup(0.0, true, EDentistBossTool::CupLeft);
		auto LeftCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupLeft]);
		LeftCup.PutCupAtTarget();
		auto MiddleCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupMiddle]);
		MiddleCup.PutCupAtTarget();
		auto RightCup = Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupRight]);
		RightCup.PutCupAtTarget();

		FlattenCups(DentistBossTimings::CupScaleDownDuration);
		ClearAnimState();
	}

	UFUNCTION(DevFunction)
	void Dev_HookAttack(EHazeSelectPlayer Target)
	{
		ResetBoss();
		if(!HasControl())
			return;
		AHazePlayerCharacter Player = Target == EHazeSelectPlayer::Mio ? Game::Mio : Game::Zoe;
		SetAnimState(EDentistBossAnimationState::HookAttack, EInstigatePriority::High);
		ScraperAttack(Player);
		ClearAnimState();
	}

	UFUNCTION(DevFunction)
	void Dev_ToothPasteAttack(EHazeSelectPlayer Target)
	{
		ResetBoss();
		if(!HasControl())
			return;
		AHazePlayerCharacter Player = Target == EHazeSelectPlayer::Mio ? Game::Mio : Game::Zoe;
		ToothPasteAttack(DentistBossTimings::ToothPasteAttack, Player, Settings.ToothPasteCount);
	}

	UFUNCTION(DevFunction)
	void Dev_StartCakeRotation()
	{
		ResetBoss();
		if(!HasControl())
			return;

		SetAnimState(EDentistBossAnimationState::Drill, EInstigatePriority::High);
		ToggleTool(EDentistBossTool::Drill, true);
		Idle(DentistBossTimings::DrillEnter);
		StartCakeRotation();
		ClearAnimState();
		ToggleTool(EDentistBossTool::Drill, false);
	}

	UFUNCTION(DevFunction)
	void Dev_StopCakeRotation()
	{
		ResetBoss();
		if(!HasControl())
			return;
		StopRotatingCake();
	}

	UFUNCTION(DevFunction)
	void Dev_KillLeftArm()
	{
		ResetBoss();
		if(!HasControl())
			return;

		Dentist.LeftHandHealthComp.Die();
	}

	UFUNCTION(DevFunction)
	void Dev_KillRightArm()
	{
		ResetBoss();
		if(!HasControl())
			return;

		Dentist.RightHandHealthComp.Die();
	}

	void ResetBoss()
	{
		ResetAnimParams();
		if(!HasControl())
			return;
		ClearIKState();
		ClearAnimState();
		Dentist.ClearActionQueues();
		StopAllLooping();
		ResetAllTools();
		DeactivateAllTools();
		ClearAllBlocksOnPlayers();
		StopMashesAndWiggles();
		SelectTarget(nullptr);
		Dentist.SkelMesh.ResetAllAnimation(true);
		auto Dentures = Cast<ADentistBossToolDentures>(Dentist.Tools[EDentistBossTool::Dentures]);
		Dentures.SkelMesh.ResetAllAnimation(true);
		Dentist.CurrentState = EDentistBossState::Debugging;
	}

	void StopAllLooping(int ExecutingQueueIndex = 0)
	{
		for(int i = 0; i < Dentist.QueueNum; i++)
		{
			ToggleLooping(i, false, ExecutingQueueIndex);
		}
	}

	void DeactivateAllTools()
	{
		for(auto Tool : Dentist.Tools)
		{
			Tool.Value.Deactivate();
		}
	}

	void ResetAllTools()
	{
		TArray<ADentistBossTool> Tools = TListedActors<ADentistBossTool>().Array;
		for(auto Tool : Tools)
		{
			Tool.Reset();
		}
	}

	void ClearAllBlocksOnPlayers()
	{
		for(auto Player : Game::Players)
		{
			for(auto Block : Dentist.CurrentCapabilityBlocks[Player].Blocks)
			{
				Player.UnblockCapabilities(Block, Dentist);
			}
			Dentist.CurrentCapabilityBlocks[Player].Blocks.Reset();
		}
	}

	void StopMashesAndWiggles()
	{
		for(auto Player : Game::Players)
		{
			Player.StopStickWiggle(Dentist);
			Player.StopButtonMash(Dentist);
		}
	}

	void ResetAnimParams()
	{
		Dentist.UseLeanBlendSpace.DefaultValue = false;
		Dentist.LookAtEnabled.Clear(this);
		Dentist.bRightPlayerEscapedChair = false;
		Dentist.bLeftPlayerEscapedChair = false;
		Dentist.bDrillFoundPlayer = false;
		Dentist.bDrillFinished = false;
		Dentist.bDrillExit = false;
		Dentist.bDrillSpinArena = false;
		Dentist.bDenturesDestroyedHand = false;
		Dentist.DenturesBitingAlpha = 0.0;
		Dentist.bDenturesFellDown = false;
		Dentist.bDenturesAttachedLeftHand = false;
		Dentist.bDenturesAttachedRightHand = false;
		Dentist.CloseMouthMaskAgainAlpha = 0.0;
		Dentist.bCupCaptureTelegraphDone = false;
		Dentist.CurrentSortType = EDentistBossToolCupSortType::None;
		Dentist.CupSortAnimSpeed = 1.0;
		Dentist.bCupChosen = false;
		Dentist.bHookTelegraphDone = false;
		Dentist.bHammerPlayer = false;
		Dentist.bHammerSplitPlayer = false;
		Dentist.bFinisherDoubleInteractStarted = false;
		Dentist.FinisherProgress = 0.0;
		Dentist.bFinisherCompleted = false;
	}
};
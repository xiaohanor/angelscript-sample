class USummitKnightCrystalCoreDestroyedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"HurtReaction");
	default TickGroup = EHazeTickGroup::Gameplay;

	USummitKnightStageComponent StageComp;
	UBasicAIAnimationComponent AnimComp;
	UBasicAIDestinationComponent DestComp;
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSettings Settings;

	FVector CenterDirection;
	float SmashFloorTime;	
	float AnimDuration;
	float SecondPhaseMoveTime;
	float SecondPhaseMoveDuration;
	float WearHelmetTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StageComp = USummitKnightStageComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		CenterDirection = Owner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StageComp.Phase != ESummitKnightPhase::CrystalCoreDamage)
			return false;
		if (StageComp.Round < Settings.DestroyCrystalCoreHits)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Only abort when done or by testing phase
		if (StageComp.Phase == ESummitKnightPhase::Test)
			return true;
		if (ActiveDuration > AnimDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
		AnimDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::SmashCrystal, NAME_None, Settings.DestroyCrystalDuration);
		AnimComp.RequestFeature(SummitKnightFeatureTags::SmashCrystal, EBasicBehaviourPriority::Medium, this, AnimDuration);

		WearHelmetTime = AnimDuration * 0.5;
		UAnimSequence Anim = KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::SmashCrystal, NAME_None);
		TArray<float32> WearHelmetTimes;
		if ((Anim != nullptr) && Anim.GetAnimNotifyTriggerTimes(UAnimNotifySummitKnightWearHelmet, WearHelmetTimes))
			WearHelmetTime = WearHelmetTimes[0];

		UAnimInstanceRubyKnight AnimInstance = Cast<UAnimInstanceRubyKnight>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
		// UAnimSequence DestroyCrystalCoreAnim = AnimInstance.DamageCrystalFinal.Sequence;
		// SmashFloorTime = DestroyCrystalCoreAnim.GetAnimNotifyStateStartTime(UBasicAIActionAnimNotify);

		// TArray<FHazeAnimNotifyStateGatherInfo> ActionNotifyInfo;
		// if (DestroyCrystalCoreAnim.GetAnimNotifyStateTriggerTimes(USummitKnightPhaseTransitonMoveAnimNotify, ActionNotifyInfo) &&
		// 	(ActionNotifyInfo.Num() > 0))
		// {
		// 	SecondPhaseMoveTime = ActionNotifyInfo[0].TriggerTime;
		// 	SecondPhaseMoveDuration = ActionNotifyInfo[0].Duration;
		// }
		// else
		{
			SecondPhaseMoveTime = 3.0;
			SecondPhaseMoveDuration = 1.0;
		}

		auto HealthComp = UBasicAIHealthComponent::Get(Owner);
		if (HealthComp.CurrentHealth > 0.667)
			HealthComp.TakeDamage(HealthComp.CurrentHealth - 0.667, EDamageType::MeleeBlunt, Game::Zoe);

		Cast<AAISummitKnight>(Owner).OnCoreDestroyed.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		AnimComp.ClearFeature(this);
 
 		if (StageComp.Phase != ESummitKnightPhase::Test)
		{
			StageComp.SetPhase(ESummitKnightPhase::FinalArenaStart, 1);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestComp.RotateInDirection(CenterDirection);
		if (HasControl() && (ActiveDuration > SecondPhaseMoveTime))
			CrumbPerformSecondPhaseMove();

		if (ActiveDuration > SmashFloorTime)
		{	
			Cast<AAISummitKnight>(Owner).OnSmashArenaFloor.Broadcast();
			SmashFloorTime = BIG_NUMBER;
		}

		if (ActiveDuration > WearHelmetTime)
		{
			WearHelmetTime = BIG_NUMBER;
			USummitKnightHelmetComponent::Get(Owner).Wear();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbPerformSecondPhaseMove()
	{
		SecondPhaseMoveTime = BIG_NUMBER;	
		FVector NextPhaseLocation = KnightComp.GetSecondPhaseLocation();
		Owner.SmoothTeleportActor(NextPhaseLocation, CenterDirection.Rotation(), this, SecondPhaseMoveDuration);
	}
};
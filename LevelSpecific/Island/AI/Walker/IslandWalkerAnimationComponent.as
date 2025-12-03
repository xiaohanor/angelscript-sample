// Handles animation stuff for walker. A better pattern is to use animinstance directly, see most other AIs. 
class UIslandWalkerAnimationComponent : UActorComponent
{
	UFeatureAnimInstanceWalker AnimInstance;

	UBasicAIAnimationComponent HeadAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AnimInstance = Cast<UFeatureAnimInstanceWalker>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
		auto NeckRoot = UIslandWalkerNeckRoot::Get(Owner);
		if (NeckRoot != nullptr)
			NeckRoot.OnHeadSetup.AddUFunction(this, n"OnHeadSetup");
		else 
			HeadAnim = UBasicAIAnimationComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnHeadSetup(AIslandWalkerHead Head)
	{
		HeadAnim = UBasicAIAnimationComponent::Get(Head);
	}

	float GetFinalizedTotalDuration(FName Tag, FName SubTag, float OverrideDuration)
	{
		if (OverrideDuration > SMALL_NUMBER)
			return OverrideDuration;

		UAnimSequence Anim = GetRequestedAnimation(Tag, SubTag);
		if (Anim == nullptr)
			return 0.0;
		
		return Anim.PlayLength;
	}

	void FinalizeDurations(FName Tag, FName SubTag, FBasicAIAnimationActionDurations& Durations)
	{
		if (Durations.IsFullySet())
			return;

		UAnimSequence Anim = GetRequestedAnimation(Tag, SubTag);
		if (Anim == nullptr)
			return;

		float ActionTime = Anim.PlayLength;
		float RecoveryTime = Anim.PlayLength;
		TArray<FHazeAnimNotifyStateGatherInfo> ActionNotifyInfo;
		if (Anim.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, ActionNotifyInfo) && (ActionNotifyInfo.Num() > 0))
		{
			ActionTime = ActionNotifyInfo[0].TriggerTime;
			RecoveryTime = ActionNotifyInfo.Last().TriggerTime + ActionNotifyInfo.Last().Duration;
		}
		float AnticipationTime = 0.0;
		TArray<FHazeAnimNotifyStateGatherInfo> TelegraphNotifyInfo;
		if (Anim.GetAnimNotifyStateTriggerTimes(UBasicAITelegraphingAnimNotify, TelegraphNotifyInfo) && (TelegraphNotifyInfo.Num() > 0))
			AnticipationTime = TelegraphNotifyInfo[0].TriggerTime + TelegraphNotifyInfo[0].Duration;

		if (Durations.Telegraph < SMALL_NUMBER)
			Durations.Telegraph = Math::Min(AnticipationTime, ActionTime);
		if (Durations.Anticipation < SMALL_NUMBER)
			Durations.Anticipation = Math::Max(ActionTime - AnticipationTime, 0.01);
		if (Durations.Action < SMALL_NUMBER)
			Durations.Action = Math::Max(RecoveryTime - ActionTime, 0.01);
		if (Durations.Recovery < SMALL_NUMBER)
			Durations.Recovery = Math::Max(Anim.PlayLength - RecoveryTime, 0.01);
	}

	UAnimSequence GetRequestedAnimation(FName Tag, FName SubTag)
	{
		if (Tag == FeatureTagWalker::Intro)
		{
			if (SubTag == SubTagWalkerIntro::End)
				return AnimInstance.IntroEnd.Sequence;
			return AnimInstance.Intro.Sequence;
		}
		if (Tag == FeatureTagWalker::Walk)
		{
			if (SubTag == SubTagWalkerWalk::Forward)
				return AnimInstance.WalkForward.Sequence;
			if (SubTag == SubTagWalkerWalk::Backward)
				return AnimInstance.WalkBackward.Sequence;
			if (SubTag == SubTagWalkerWalk::Right)
				return AnimInstance.WalkRight.Sequence;
			if (SubTag == SubTagWalkerWalk::Left)
				return AnimInstance.WalkLeft.Sequence;
		}
		if (Tag == FeatureTagWalker::Turn)
		{
			if (SubTag == SubTagWalkerTurn::Left90)
				return AnimInstance.TurnLeft90.Sequence;
			if (SubTag == SubTagWalkerTurn::Left45)
				return AnimInstance.TurnLeft45.Sequence;
			if (SubTag == SubTagWalkerTurn::Left22)
				return AnimInstance.TurnLeft22.Sequence;
			if (SubTag == SubTagWalkerTurn::Right90)
				return AnimInstance.TurnRight90.Sequence;
			if (SubTag == SubTagWalkerTurn::Right45)
				return AnimInstance.TurnRight45.Sequence;
			if (SubTag == SubTagWalkerTurn::Right22)
				return AnimInstance.TurnRight22.Sequence;
		}
		if (Tag == FeatureTagWalker::Hit)
		{
			if (SubTag == SubTagWalkerHit::Left)
				return AnimInstance.HitLeft.Sequence;
			if (SubTag == SubTagWalkerHit::Right)
				return AnimInstance.HitRight.Sequence;
		}
		if (Tag == FeatureTagWalker::Fall)
		{
			if (SubTag == SubTagWalkerFall::Forward)
				return AnimInstance.FallForward.Sequence;
			if (SubTag == SubTagWalkerFall::Left)
				return AnimInstance.FallLeft.Sequence;
			if (SubTag == SubTagWalkerFall::Right)
				return AnimInstance.FallRight.Sequence;
		}
		if (Tag == FeatureTagWalker::JumpAttack)
		{
			return AnimInstance.JumpAttack.Sequence;
		}
		if (Tag == FeatureTagWalker::FireBurst)
		{
			return AnimInstance.FireBurst.Sequence;
		}
		if (Tag == FeatureTagWalker::SweepingLaser)
		{
			if (SubTag == SubTagWalkerSweepingLaser::End)
				return AnimInstance.SweepingLaserEnd.Sequence;
			return AnimInstance.SweepingLaserStart.Sequence;
		}
		if (Tag == FeatureTagWalker::SpinningLaser)
		{
			if (SubTag == SubTagWalkerSpinningLaser::End)
				return AnimInstance.SpinningLaserEnd.Sequence;
			return AnimInstance.SpinningLaserStart.Sequence;
		}
		if (Tag == FeatureTagWalker::Spawner)
		{
			if (SubTag == SubTagWalkerSpawner::Standing)
				return AnimInstance.SpawnerStandingMh.Sequence;
			if (SubTag == SubTagWalkerSpawner::StandingSpawn)
				return AnimInstance.SpawnerStanding.Sequence;
			if (SubTag == SubTagWalkerSpawner::ProtectingLegs)
				return AnimInstance.SpawnerProtectingLegsStart.Sequence;
			if (SubTag == SubTagWalkerSpawner::ProtectingLegsEnd)
				return AnimInstance.SpawnerProtectingLegsEnd.Sequence;
			if (SubTag == SubTagWalkerSpawner::ProtectingLegsSpawning)
				return AnimInstance.SpawnerProtectingLegsSpawnBuzzer.Sequence;
			return AnimInstance.SpawnerProtectingLegsMH.Sequence;
		}
		if (Tag == FeatureTagWalker::Suspended)
		{
			if (SubTag == SubTagWalkerSuspended::IntroForward)
				return AnimInstance.SuspendedIntroForward.Sequence;
			if (SubTag == SubTagWalkerSuspended::IntroRight)
				return AnimInstance.SuspendedIntroRight.Sequence;
			if (SubTag == SubTagWalkerSuspended::IntroLeft)
				return AnimInstance.SuspendedIntroLeft.Sequence;
			if (SubTag == SubTagWalkerSuspended::Spawning)
				return AnimInstance.SuspendedSpawning.Sequence;
			if (SubTag == SubTagWalkerSuspended::FrontShieldDown)
				return AnimInstance.SuspendedFrontShieldDown.Sequence;
			if (SubTag == SubTagWalkerSuspended::RearShieldDown)
				return AnimInstance.SuspendedRearShieldDown.Sequence;
			if (SubTag == SubTagWalkerSuspended::FrontCablesCut)
				return AnimInstance.SuspendedFrontCablesCut.Sequence;
			if (SubTag == SubTagWalkerSuspended::RearCablesCut)
				return AnimInstance.SuspendedRearCablesCut.Sequence;
			if (SubTag == SubTagWalkerSuspended::FallDownFrontFirst)
				return AnimInstance.SuspendedFallDownFrontFirst.Sequence;
			if (SubTag == SubTagWalkerSuspended::FallDownRearFirst)
				return AnimInstance.SuspendedFallDownRearFirst.Sequence;
			return AnimInstance.SuspendedMH.Sequence;
		}
		if (Tag == FeatureTagWalker::SmashCage)
		{
			if (SubTag == SubTagWalkerSmashCage::Left)
				return AnimInstance.SmashCageTurnLeft.Sequence;
			if (SubTag == SubTagWalkerSmashCage::Right)
				return AnimInstance.SmashCageTurnRight.Sequence;
			return AnimInstance.SmashCageAttack.Sequence;
		}
		if (Tag == FeatureTagWalker::HeadSprayGas)
		{
			if (SubTag == SubTagWalkerHeadSprayGas::End)
				return AnimInstance.HeadCloseJaw.Sequence;
			return AnimInstance.HeadOpenJaw.Sequence;
		}
		if (Tag == FeatureTagWalker::HeadGrenadeReaction)
		{
			if (SubTag == SubTagWalkerHeadGrenadeReaction::HitLeft)
				return AnimInstance.HeadGrenadeHitLeft.Sequence;
			if (SubTag == SubTagWalkerHeadGrenadeReaction::HitRight)
				return AnimInstance.HeadGrenadeHitRight.Sequence;
			if (SubTag == SubTagWalkerHeadGrenadeReaction::Eat)
				return AnimInstance.HeadGrenadeEat.Sequence;
			if (SubTag == SubTagWalkerHeadGrenadeReaction::EatenDetonate)
				return AnimInstance.HeadGrenadeEatDetonate.Sequence;
		}
		if (Tag == FeatureTagWalker::HeadHurtReaction)
		{
			if (AnimInstance.HeadHurtReaction.Sequences.Num() > 0)
				return AnimInstance.HeadHurtReaction.Sequences[0].Sequence;
		}
		if (Tag == FeatureTagWalker::HatchFlight)
		{
			if (SubTag == SubTagWalkerHatchFlight::StartLiftOff)
				return AnimInstance.HatchStartLiftOff.Sequence;
			if (SubTag == SubTagWalkerHatchFlight::ThrowOff)
				return AnimInstance.HatchThrowOff.Sequence;
			return AnimInstance.HatchMh.Sequence;
		}
		if (Tag == FeatureTagWalker::HeadCrash)
		{
			if (SubTag == SubTagWalkerHeadCrash::FallDown)
				return AnimInstance.HeadCrash.Sequence;
			if (SubTag == SubTagWalkerHeadCrash::StayCrashed)
				return AnimInstance.HeadCrash_Mh.Sequence;
			if (SubTag == SubTagWalkerHeadCrash::Attack)
				return AnimInstance.HeadCrash_Attack.Sequence;
			if (SubTag == SubTagWalkerHeadCrash::Recover)
				return AnimInstance.HeadCrashRecover.Sequence;
			return AnimInstance.HeadCrash_Mh.Sequence;
		}
		return nullptr;
	}

}

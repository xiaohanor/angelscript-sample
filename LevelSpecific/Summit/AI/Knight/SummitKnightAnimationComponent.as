// Handles animation stuff for knight. A better pattern is to use animinstance directly, see most other AIs. 
class USummitKnightAnimationComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PlayerRollToHeadAnimation;

	AHazeActor AcidShieldInstigator = nullptr;
	float SpinningSlashLoopDuration = 1.0;

	UAnimInstanceRubyKnight AnimInstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AnimInstance = Cast<UAnimInstanceRubyKnight>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
	}

	void SetSpinningSlashLoopDuration(float OverrideDuration)
	{
		if (OverrideDuration > SMALL_NUMBER)
			SpinningSlashLoopDuration = OverrideDuration;
		else 
			SpinningSlashLoopDuration = AnimInstance.SpinningShockwaveMh.Sequence.ScaledPlayLength;
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
		if (Tag == SummitKnightFeatureTags::Swoop)
		{
			if (SubTag == SummitKnightSubTagsSwoop::Enter)
				return AnimInstance.Swoop_Enter.Sequence;
			if (SubTag == SummitKnightSubTagsSwoop::Mh)
				return AnimInstance.Swoop_Mh.Sequence;
			if (SubTag == SummitKnightSubTagsSwoop::Exit)
				return AnimInstance.Swoop_Exit.Sequence;
			return AnimInstance.Swoop_Mh.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::SlamAttack)
		{
			if (SubTag == SummitKnightSubTagsSlamAttack::Enter)
				return AnimInstance.SlamAttack_Enter.Sequence;
			if (SubTag == SummitKnightSubTagsSlamAttack::Mh)
				return AnimInstance.SlamAttack_Mh.Sequence;
			if (SubTag == SummitKnightSubTagsSlamAttack::Exit)
				return AnimInstance.SlamAttack_Exit.Sequence;
			if (SubTag == SummitKnightSubTagsSlamAttack::Stun)
				return AnimInstance.SlamAttack_Stun.Sequence;
			return AnimInstance.SlamAttack_Enter.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::CirclingIntro)
		{
			return AnimInstance.CirclingIntro.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::SingleSlash)
		{
			return AnimInstance.OneSlash.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::DualSlash)
		{
			return AnimInstance.TwoSlashes.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::SpinningShockwave)
		{
			if (SubTag == SummitKnightSubTagsSpinningShockwave::Enter)
				return AnimInstance.SpinningShockwaveEnter.Sequence;
			if (SubTag == SummitKnightSubTagsSpinningShockwave::Mh)
				return AnimInstance.SpinningShockwaveMh.Sequence;
			if (SubTag == SummitKnightSubTagsSpinningShockwave::Exit)
				return AnimInstance.SpinningShockwaveExit.Sequence;
			return AnimInstance.SpinningShockwaveEnter.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::HomingFireballs)
		{
			return AnimInstance.HomingFireballs.Sequence;
		}
	
		if (Tag == SummitKnightFeatureTags::SpikeTrail)
		{
			return AnimInstance.SpikeTrail.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::SummonCritters)
		{
			return AnimInstance.SummonCritters.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::SummonObstacles)
		{
			return AnimInstance.SummonObstacles.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::LargeAreaStrike)
		{
			return AnimInstance.LargeAreaStrike.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::SmashGround)
		{
			return AnimInstance.SmashGround.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::HurtReaction)
		{
			return AnimInstance.HurtReaction.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::SmashCrystal)
		{
			return AnimInstance.SmashCrystal.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::AlmostDeadRecoil)
		{
			if (SubTag == SummitKnightSubTagsAlmostDead::Start)
				return AnimInstance.AlmostDeadStart.Sequence;
			if (SubTag == SummitKnightSubTagsAlmostDead::End)
				return AnimInstance.AlmostDeadEnd.Sequence;
			return AnimInstance.AlmostDeadStart.Sequence;
		}
		if (Tag == SummitKnightFeatureTags::Death)
		{
			return AnimInstance.Death.Sequence;
		}
		return nullptr;
	}

}
// Temp until Animation BP
class USanctuaryBossSplineRunHydraAnimationCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(ArenaHydraTags::SplineRunHydra);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossSplineRunHydra SplineRunHydra;
	ESanctuaryBossSplineRunHydraAnimation PlayingAnimation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineRunHydra = Cast<ASanctuaryBossSplineRunHydra>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SplineRunHydra.DesiredAnimation == PlayingAnimation)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SplineRunHydra.DesiredAnimation == PlayingAnimation)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayingAnimation = SplineRunHydra.DesiredAnimation;
		switch (PlayingAnimation)
		{
			case ESanctuaryBossSplineRunHydraAnimation::Idle: PlayIdleAnimation(); break;
			case ESanctuaryBossSplineRunHydraAnimation::Projectile: PlaySpitBallAnimation(); break;
			case ESanctuaryBossSplineRunHydraAnimation::Wave: PlayWaveAnimation(); break;
			case ESanctuaryBossSplineRunHydraAnimation::Dive: PlayDiveAnimation(); break;
			case ESanctuaryBossSplineRunHydraAnimation::PlayersEngageCrossbow: PlayEngageCrossbowAnimation(); break;
			case ESanctuaryBossSplineRunHydraAnimation::HitByArrow: PlayHitByArrowAnimation(); break;
			case ESanctuaryBossSplineRunHydraAnimation::None: break;
		}
	}

	void PlayHitByArrowAnimation()
	{
		if (SplineRunHydra.HitByArrowAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams AnimationParams;
			AnimationParams.BlendTime = 0.2;
			AnimationParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			AnimationParams.Animation = SplineRunHydra.HitByArrowAnimation;
			SplineRunHydra.SkeletalMesh.PlaySlotAnimation(AnimationParams);
			USanctuaryBossSplineRunHydraEventHandler::Trigger_AnimateStart_HitByArrow(Owner);
		}
	}

	void PlayEngageCrossbowAnimation()
	{
		if (SplineRunHydra.PlayersEngageCrossbowAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams AnimationParams;
			AnimationParams.BlendTime = 0.2;
			AnimationParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			AnimationParams.Animation = SplineRunHydra.PlayersEngageCrossbowAnimation;
			SplineRunHydra.SkeletalMesh.PlaySlotAnimation(AnimationParams);
			USanctuaryBossSplineRunHydraEventHandler::Trigger_AnimateStart_ReactToPlayersEngagedCrossbow(Owner);
		}
	}

	void PlayDiveAnimation()
	{
		if (SplineRunHydra.DiveAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams AnimationParams;
			AnimationParams.BlendTime = 0.2;
			AnimationParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			AnimationParams.Animation = SplineRunHydra.DiveAnimation;
			SplineRunHydra.SkeletalMesh.PlaySlotAnimation(AnimationParams);
			USanctuaryBossSplineRunHydraEventHandler::Trigger_AnimateStart_Idle(Owner);
		}
	}

	void PlayWaveAnimation()
	{
		if (SplineRunHydra.WaveAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams AnimationParams;
			AnimationParams.BlendTime = 0.2;
			AnimationParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			AnimationParams.Animation = SplineRunHydra.WaveAnimation;
			SplineRunHydra.SkeletalMesh.PlaySlotAnimation(AnimationParams);
			Timer::SetTimer(this, n"ReturnToIdle", AnimationParams.Animation.SequenceLength * 0.95);
			USanctuaryBossSplineRunHydraEventHandler::Trigger_AnimateStart_Wave(Owner);
		}
	}

	void PlaySpitBallAnimation()
	{
		if (SplineRunHydra.SpitBallAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams AnimationParams;
			AnimationParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			AnimationParams.BlendTime = 0.2;
			AnimationParams.Animation = SplineRunHydra.SpitBallAnimation;
			SplineRunHydra.SkeletalMesh.PlaySlotAnimation(AnimationParams);
			Timer::SetTimer(this, n"ReturnToIdle", AnimationParams.Animation.SequenceLength * 0.95);
			USanctuaryBossSplineRunHydraEventHandler::Trigger_AnimateStart_GhostBall(Owner);
		}
	}

	void PlayIdleAnimation()
	{
		if (SplineRunHydra.IdleAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams AnimationParams;
			AnimationParams.BlendTime = 0.2;
			AnimationParams.BlendType = EHazeBlendType::BlendType_Inertialization;
			AnimationParams.Animation = SplineRunHydra.IdleAnimation;
			AnimationParams.bLoop = true;
			SplineRunHydra.SkeletalMesh.PlaySlotAnimation(AnimationParams);
			USanctuaryBossSplineRunHydraEventHandler::Trigger_AnimateStart_Idle(Owner);
		}
	}

	UFUNCTION()
	void ReturnToIdle()
	{
		bool bIgnoreIdle = SplineRunHydra.DesiredAnimation == ESanctuaryBossSplineRunHydraAnimation::PlayersEngageCrossbow || SplineRunHydra.DesiredAnimation == ESanctuaryBossSplineRunHydraAnimation::HitByArrow;
		if (!bIgnoreIdle)
			SplineRunHydra.DesiredAnimation = ESanctuaryBossSplineRunHydraAnimation::Idle;
	}
};
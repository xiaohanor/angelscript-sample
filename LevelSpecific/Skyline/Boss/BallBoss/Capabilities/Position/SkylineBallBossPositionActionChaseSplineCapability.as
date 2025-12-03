struct FSkylineBallBossPositionActionChaseSplineData
{
	// float OriginalHeight;
}

class USkylineBallBossPositionActionChaseSplineCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Position);
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);
	default TickGroup = EHazeTickGroup::Movement;
	
	FSkylineBallBossPositionActionChaseSplineData ActivationParams;
	ASkylineBallBoss BallBoss;
	FHazeAcceleratedFloat AccHeight;
	USkylineBallBossActionsComponent BossComp;
	float PostChaseDuration = 0.0;
	float OGHeight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		OGHeight = BallBoss.ActorLocation.Z;
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossPositionActionChaseSplineData& Params) const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return false;
		if (!IsInHandledState())
			return false;
		if (BossComp.PositionActionQueue.Start(this, Params))
		{
			// if (BallBoss.bIsControlledByCutscene || BallBoss.IsHidden())
			// 	Params.OriginalHeight = OGHeight;
			// else
			// 	Params.OriginalHeight = BallBoss.ActorLocation.Z;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return true;
		if (!IsInHandledState())
			return true;
		if (BallBoss.ActorLocation.Z < OGHeight - KINDA_SMALL_NUMBER)
			return false;
		if (!BossComp.PositionActionQueue.IsActive(this))
			return true;
		return false;
	}

	private bool IsInHandledState() const
	{
		return BallBoss.GetPhase() == ESkylineBallBossPhase::Chase || BallBoss.GetPhase() == ESkylineBallBossPhase::PostChaseElevator;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossPositionActionChaseSplineData Params)
	{
		ActivationParams = Params;
		AccHeight.SnapTo(BallBoss.ActorLocation.Z);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.PositionActionQueue.Finish(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation = BallBoss.ActorLocation;
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::Chase)
		{
			float TargetHeight = BallBoss.AcceleratedTargetVector.Value.Z;
			AccHeight.AccelerateTo(TargetHeight, 1.0, DeltaTime);
			if (BallBoss.bChaseSnapToBehindPlayers)
				AccHeight.SnapTo(TargetHeight);
			TargetLocation.Z = TargetHeight;
		}
		else if (BallBoss.GetPhase() == ESkylineBallBossPhase::PostChaseElevator)
		{
			PostChaseDuration += DeltaTime;
			const float SlowApproachDuration = 1.0;
			const float QuickApproachDuration = 7.0;
			if (PostChaseDuration < SlowApproachDuration)
			{
				float Alpha = Math::Clamp(PostChaseDuration / SlowApproachDuration, 0.0, 1.0);
				float ExtraOffset = Math::EaseInOut(-500, 2000.0, Alpha, 2.0);
				float TargetHeight = Game::Mio.ActorLocation.Z + ExtraOffset;
				TargetLocation.Z = TargetHeight;
				AccHeight.AccelerateTo(TargetHeight, 5.0, DeltaTime);
			}
			else if (PostChaseDuration < SlowApproachDuration + QuickApproachDuration)
			{
				float QuickDuration = PostChaseDuration - SlowApproachDuration;
				float Alpha = Math::Clamp(QuickDuration / QuickApproachDuration, 0.0, 1.0);
				float ExtraOffset = Math::EaseInOut(-500, 2000.0, Alpha, 2.0);
				float TargetHeight = Game::Mio.ActorLocation.Z + ExtraOffset;
				TargetLocation.Z = TargetHeight;
				AccHeight.AccelerateTo(TargetHeight, 2.5, DeltaTime);
			}
			else
			{
				TargetLocation.Z = OGHeight;
				AccHeight.AccelerateTo(OGHeight, 2.0, DeltaTime);
			}
		}
		
		if (SkylineBallBossDevToggles::DrawLocationTarget.IsEnabled() && BallBoss.ActorLocation.Distance(TargetLocation) > KINDA_SMALL_NUMBER)
			Debug::DrawDebugArrow(BallBoss.ActorLocation, TargetLocation, 20.0, ColorDebug::Ruby, 5.0, 0.0, true);

		FVector BallBossLocation = BallBoss.ActorLocation;
		BallBossLocation.Z = AccHeight.Value;
		BallBoss.SetActorLocation(BallBossLocation);
	}
}
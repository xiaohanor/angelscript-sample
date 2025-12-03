struct FSandSharkDiveActivateParams
{
	bool bIsPlayerBehindShark;
	bool bIsPlayerOnLeftSide;
	bool bPlayDiveAnim;
} class USandSharkChaseDiveCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkChase);

	default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = SandShark::TickGroupOrder::Chase;
	default TickGroupSubPlacement = 1;

	ASandShark SandShark;
	USandSharkMovementComponent MoveComp;
	USandSharkChaseComponent ChaseComp;
	USandSharkAnimationComponent AnimationComp;
	USandSharkSettings SharkSettings;

	bool bUnblockedDistracts = false;
	bool bIsPlayingDiveAnim = false;

	float CurrentDistance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
		ChaseComp = USandSharkChaseComponent::Get(Owner);
		AnimationComp = USandSharkAnimationComponent::Get(Owner);
		SharkSettings = USandSharkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSandSharkDiveActivateParams& Params) const
	{
		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != SandShark.LandscapeLevel)
			return false;

		if (ChaseComp.State != ESandSharkChaseState::None)
			return false;

		if (!ChaseComp.bIsChasing)
			return false;

		if (SandShark.MoveToComp.Path.Points.Num() < 2)
			return false;

		FVector ToPath = (SandShark.MoveToComp.Path.Points[1] - SandShark.ActorLocation).ProjectOnToNormal(SandShark.ActorForwardVector);
		float Dot = ToPath.DotProductNormalized(SandShark.ActorForwardVector);
		if (Dot > 0.4)
			return false;

		if (MoveComp.AccDive.Value > -100)
		{
			Params.bPlayDiveAnim = true;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bIsPlayingDiveAnim && ActiveDuration >= 0.9)
			return true;

		if (!bIsPlayingDiveAnim)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSandSharkDiveActivateParams Params)
	{
		USandSharkEventHandler::Trigger_OnChaseSmallDiveStarted(SandShark);
		SandShark.BlockAttacks(this);
		ChaseComp.State = ESandSharkChaseState::Diving;
		if (Params.bIsPlayerBehindShark)
		{
			ChaseComp.bCanMoveDuringDive = true;
			AnimationComp.Data.bIsTurnDiving = true;
			AnimationComp.Data.bShouldTurnLeft = Params.bIsPlayerOnLeftSide;
		}

		bIsPlayingDiveAnim = Params.bPlayDiveAnim;
		if (bIsPlayingDiveAnim)
		{
			AnimationComp.AddDiveInstigator(this);
		}
		CurrentDistance = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnimationComp.RemoveDiveInstigator(this);
		SandShark.UnblockAttacks(this);
		ChaseComp.DiveActiveDuration = ActiveDuration;
		ChaseComp.State = ESandSharkChaseState::None;

		bUnblockedDistracts = false;
		ChaseComp.bCanMoveDuringDive = false;
		AnimationComp.Data.bIsTurnDiving = false;
		AnimationComp.Data.bShouldTurnLeft = false;
		MoveComp.AccDive.SnapTo(-450);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AnimationComp.HasBreachedSand())
		{
			AnimationComp.ConsumeSandBreach();
			FSandSharkSandBreachParams Params;
			Params.SandBreachedLocation = Desert::GetLandscapeLocationByLevel(AnimationComp.GetNeckLocation(), ESandSharkLandscapeLevel::Lower);
			USandSharkEventHandler::Trigger_OnChaseSmallDiveSandBreached(SandShark, Params);
		}
		
		if (ActiveDuration < 0.8 && bIsPlayingDiveAnim)
		{
			return;
		}

		if (HasControl())
		{
			if (SandShark.MoveToComp.Path.IsValid())
			{
				auto Points = SandShark.MoveToComp.Path.Points;
				if (Points.Num() >= 2)
				{
					FHazeRuntimeSpline RuntimeSpline;
					RuntimeSpline.SetPoints(Points);
					CurrentDistance += 100 * DeltaTime;
					FVector OutLocation;
					FRotator OutRotation;
					RuntimeSpline.GetLocationAndRotationAtDistance(CurrentDistance, OutLocation, OutRotation);
					MoveComp.ApplyMove(OutLocation, OutRotation.Quaternion(), this);
				}
			}
		}
		else
		{
			MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
		}
	}
	UFUNCTION(CrumbFunction)
	void CrumbUnblockDistracts()
	{
		// allow transition to distract states once dive animation is finished
		bUnblockedDistracts = true;
	}
};
struct FSandSharkAttackFromBelowJumpDeactivateParams
{
	bool bFinished;
	ASandSharkSpline TargetSpline;
	FQuat NewRotation;
}

struct FSandSharkAttackFromBelowJumpActivateParams
{
	FVector TargetLocation;
	FQuat TargetRotation;
}

class USandSharkAttackFromBelowJumpCapability : UHazeCapability
{
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(SandSharkTags::SandShark);
	// default CapabilityTags.Add(SandSharkTags::SandSharkAttackFromBelow);

	// default CapabilityTags.Add(SandSharkBlockedWhileIn::AttackLunge);
	// default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	// default TickGroup = EHazeTickGroup::BeforeMovement;
	// default TickGroupOrder = SandShark::TickGroupOrder::AttackFromBelow;
	// default TickGroupSubPlacement = 1;

	// ASandShark SandShark;
	// USandSharkAttackFromBelowComponent AttackFromBelowComp;
	// USandSharkMovementComponent MoveComp;
	// USandSharkAnimationComponent AnimationComp;
	// USandSharkSettings SharkSettings;

	// FVector LastValidLocation;
	// FQuat InitialRotation;

	// FVector HeadBoneOffset;

	// bool bPlayerBecameUnattackable;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	SandShark = Cast<ASandShark>(Owner);
	// 	AttackFromBelowComp = USandSharkAttackFromBelowComponent::Get(Owner);
	// 	MoveComp = USandSharkMovementComponent::Get(Owner);
	// 	AnimationComp = USandSharkAnimationComponent::Get(Owner);
	// 	SharkSettings = USandSharkSettings::GetSettings(Owner);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate(FSandSharkAttackFromBelowJumpActivateParams& Params) const
	// {
	// 	if (!AttackFromBelowComp.bIsAttackingFromBelow)
	// 		return false;

	// 	if (MoveComp.HasMovedThisFrame())
	// 		return false;

	// 	auto PlayerLocation = SandShark.GetTargetPlayerLocationOnLandscapeByLevel(SandShark.LandscapeLevel);

	// 	FVector LocationNearestPlayer, TargetLocation;
	// 	if (Pathfinding::FindNavmeshLocation(PlayerLocation, 1000, SandShark::Navigation::AgentHeight, LocationNearestPlayer))
	// 		TargetLocation = LocationNearestPlayer;
	// 	else
	// 		TargetLocation = PlayerLocation;

	// 	TargetLocation.Z -= 3000;
	// 	Params.TargetLocation = TargetLocation;

	// 	auto Direction = (TargetLocation - SandShark.ActorLocation).GetSafeNormal2D();

	// 	Params.TargetRotation = FQuat::MakeFromXZ(Direction, FVector::UpVector);

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate(FSandSharkAttackFromBelowJumpDeactivateParams& Params) const
	// {
	// 	bool bShouldDeactivate = false;
	// 	if (!AttackFromBelowComp.bIsAttackingFromBelow)
	// 		bShouldDeactivate = true;

	// 	if (MoveComp.HasMovedThisFrame())
	// 		bShouldDeactivate = true;

	// 	// If the state has been changed by something, deactivate
	// 	if (AttackFromBelowComp.State != ESandSharkAttackFromBelowState::Jump)
	// 		bShouldDeactivate = true;

	// 	if (ActiveDuration > SandShark::Animations::AttackFromBelowJumpDuration)
	// 	{
	// 		Params.bFinished = true;
	// 		bShouldDeactivate = true;
	// 	}

	// 	if (bShouldDeactivate)
	// 	{
	// 		// Dive deep and set rotation towards spline
	// 		auto PlayerComp = SandShark.GetTargetPlayerComponent();
	// 		auto PlayerLastSafePoint = PlayerComp.GetLastSafePoint();
	// 		ASandSharkSpline TargetSpline;
	// 		if (PlayerLastSafePoint != nullptr)
	// 			TargetSpline = PlayerLastSafePoint.Spline;
	// 		else
	// 			TargetSpline = SandShark.GetCurrentSpline();

	// 		FQuat NewRotation;
	// 		if (TargetSpline != nullptr)
	// 		{
	// 			auto Direction = TargetSpline.Spline.GetClosestSplinePositionToWorldLocation(SandShark.ActorLocation).WorldLocation - SandShark.ActorLocation;
	// 			NewRotation = FQuat::MakeFromXZ(Direction, FVector::UpVector);
	// 		}

	// 		Params.TargetSpline = TargetSpline;
	// 		Params.NewRotation = NewRotation;

	// 		return true;
	// 	}

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated(FSandSharkAttackFromBelowJumpActivateParams Params)
	// {
	// 	USandSharkAttackFromBelowEventHandler::Trigger_OnStartAttackFromBelowJump(SandShark);

	// 	LastValidLocation = Desert::GetLandscapeLocation(SandShark.ActorLocation);
	// 	AnimationComp.AddHighAnimUpdateInstigator(this);

	// 	AnimationComp.Data.AttackFromBelow.bIsJumping = true;

	// 	AttackFromBelowComp.State = ESandSharkAttackFromBelowState::Jump;

	// 	InitialRotation = Params.TargetRotation;

	// 	//MoveComp.AccDive.SnapTo(-3000);
	// 	if (HasControl())
	// 		MoveComp.ApplyMove(Params.TargetLocation, InitialRotation, this);
	// 	else
	// 		MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated(FSandSharkAttackFromBelowJumpDeactivateParams Params)
	// {
	// 	AnimationComp.ReapplyMeshOffset(this);
	// 	AnimationComp.RemoveHighAnimUpdateInstigator(this);

	// 	//MoveComp.AccDive.SnapTo(-3000);

	// 	auto NewLocation = LastValidLocation;
	// 	NewLocation.Z += MoveComp.AccDive.Value;

	// 	AnimationComp.Data.AttackFromBelow.bIsJumping = false;
	// 	bPlayerBecameUnattackable = false;

	// 	if (Params.bFinished)
	// 		AttackFromBelowComp.State = ESandSharkAttackFromBelowState::None;

	// 	USandSharkAttackFromBelowEventHandler::Trigger_OnStopAttackFromBelowJump(SandShark);
	// 	if (HasControl())
	// 	{
	// 		MoveComp.ApplyMove(NewLocation, Params.NewRotation, this);
	// 	}
	// 	else
	// 	{
	// 		MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
	// 	}
	// 	// SandShark.GoToSpline(Params.TargetSpline);
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (ActiveDuration > 0.1)
	// 	{
	// 		// small delay so that we don't cause warping by removing meshoffset when it's visible
	// 		AnimationComp.RemoveMeshOffset(this);
	// 		MoveComp.AccDive.SnapTo(0);
	// 	}

	// 	if (MoveComp.HasMovedThisFrame())
	// 		return;

	// 	if (HasControl())
	// 	{
	// 		if (!AttackFromBelowComp.IsTargetPlayerAttackable())
	// 			bPlayerBecameUnattackable = true;

	// 		FVector NearestLocation = LastValidLocation;
	// 		if (!bPlayerBecameUnattackable)
	// 		{
	// 			FVector PlayerLocation = SandShark.GetTargetPlayerLocationOnLandscapeByLevel(SandShark.LandscapeLevel);

	// 			if (!Pathfinding::FindNavmeshLocation(PlayerLocation, SandShark.AttackFromBelowValues.AttackWhenWithinDistance, SandShark::Navigation::AgentHeight, NearestLocation))
	// 			{
	// 				// if cant find nearby point then flag as unattackable
	// 				NearestLocation = Desert::GetLandscapeLocation(LastValidLocation);
	// 				bPlayerBecameUnattackable = true;
	// 			}

	// 			LastValidLocation = NearestLocation;
	// 		}
	// 		NearestLocation.Z += MoveComp.AccDive.Value;

	// 		MoveComp.ApplyMove(NearestLocation, InitialRotation, this);

	// 		TArray<AHazePlayerCharacter> KilledPlayers;

	// 		if (ActiveDuration < SandShark::AttackFromBelow::TimeBeforeKill)
	// 			return;

	// 		if (SandShark.AttemptKillPlayersInBox(NearestLocation, SandShark.ActorQuat, SandShark::Collision::AttackFromBelowExtents, KilledPlayers))
	// 		{
	// 			for (auto KilledPlayer : KilledPlayers)
	// 			{
	// 				KilledPlayer.PlayForceFeedback(AttackFromBelowComp.KillForceFeedback, false, false, this, AttackFromBelowComp.ForceFeedbackMaxIntensity);
	// 			}
	// 			// setting this to stop following player
	// 			bPlayerBecameUnattackable = true;
	// 		}
	// 	}
	// 	else
	// 	{
	// 		MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
	// 	}
	// }

	// bool CanTransitionFrom(ESandSharkAttackFromBelowState State) const
	// {
	// 	switch (State)
	// 	{
	// 		case ESandSharkAttackFromBelowState::Dive:
	// 			return true;
	// 		default:
	// 			return false;
	// 	}
	// }
};
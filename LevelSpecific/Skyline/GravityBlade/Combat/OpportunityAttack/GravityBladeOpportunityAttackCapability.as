class UGravityBladeOpportunityAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;
	UGravityBladePlayerOpportunityAttackComponent OpportunityAttackComp;
	ULocomotionFeatureOpportunityAttack Feature;
	UGravityBladeOpportunityAttackTargetComponent OpportunityAttackTarget;
	UHazeSkeletalMeshComponentBase TargetMesh;

	float GrappleTime = -BIG_NUMBER;
	UGravityBladeOpportunityAttackTargetComponent GrappleTarget;

	int NumPendingAttacks;
	bool bTriggeredAttack;
	float TimeSinceComboAvailable;
	bool bShowingTutorial = false;
	float FailTime = BIG_NUMBER;
	float ExitTime = BIG_NUMBER;
	float FailKillTime = BIG_NUMBER;

	float RotateTowardsTargetEndTime;
	FQuat ToTargetRot;

	float AlignStartMoveTime;
	float AlignMoveDuration;
	float AlignStartRotationTime;
	float AlignRotationDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		BladeComp = UGravityBladeUserComponent::Get(Owner);
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		UGravityBladeGrappleUserComponent::Get(Owner).OnActivation.AddUFunction(this, n"OnBladeGrapple");
		OpportunityAttackComp = UGravityBladePlayerOpportunityAttackComponent::GetOrCreate(Player);
	}

	UFUNCTION()
	private void OnBladeGrapple()
	{
		if (!CombatComp.HasPendingAttack())
			return; // Not a combat grapple
		if (CombatComp.PendingAttackData.Target == nullptr)
			return;
		GrappleTarget = UGravityBladeOpportunityAttackTargetComponent::Get(CombatComp.PendingAttackData.Target.Owner);
		if (GrappleTarget == nullptr) 
			return;
		GrappleTime = Time::GameTimeSeconds;			
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Check if a combat grapple should turn into an opportunity attack
		if (!HasControl())
			return;
		if (GrappleTarget == nullptr)
			return;
		if (Time::GetGameTimeSince(GrappleTime) > 2.0)
		{
			GrappleTarget = nullptr;
			return;
		}
		if (!GrappleTarget.IsOpportunityAttackEnabled())
			return;
		if (!Player.ActorCenterLocation.IsWithinDist(GrappleTarget.Owner.ActorLocation, GrappleTarget.AttackDistanceFromGrapple))
		 	return;
		CrumbOpportunityAttackFromGrapple(UGravityBladeCombatTargetComponent::Get(GrappleTarget.Owner), CombatComp.ActiveAttackData.AnimationType);	
		GrappleTarget = nullptr;
	}

	UFUNCTION(CrumbFunction)
	void CrumbOpportunityAttackFromGrapple(UGravityBladeCombatTargetComponent Target, EGravityBladeAttackAnimationType AnimType)
	{
		auto MoveType = EGravityBladeAttackMovementType::OpportunityAttack;
		FGravityBladeCombatAttackAnimationData AnimData;
		CombatComp.GetAttackAnimationData(AnimType, 0, 0, AnimData);
		CombatComp.SetPendingAttackData(FGravityBladeCombatAttackData(MoveType, AnimType, Target, AnimData));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if(!BladeComp.IsBladeEquipped())
			return false;
		if(!CombatComp.HasPendingAttack())
			return false;
		if(CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::OpportunityAttack)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if(!CombatComp.HasActiveAttack())
			return true;
		if(CombatComp.ActiveAttackData.MovementType != EGravityBladeAttackMovementType::OpportunityAttack)
			return true;
		if (ActiveDuration > ExitTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
		OpportunityAttackTarget = UGravityBladeOpportunityAttackTargetComponent::Get(CombatComp.ActiveAttackData.Target.Owner);
		TargetMesh = UHazeSkeletalMeshComponentBase::Get(OpportunityAttackTarget.Owner);
		BladeComp.UnsheatheBlade();

		Feature = Player.Mesh.GetFeatureByClass(ULocomotionFeatureOpportunityAttack);

		// Target decides how it wants to get beat up
		OpportunityAttackComp.CurrentSequence = OpportunityAttackTarget.GetCurrentSequence(Feature);
		OpportunityAttackComp.bIsAttacking = true;
		OpportunityAttackComp.bAttackFailed = false;
		OpportunityAttackComp.CurrentSegment = 0;
		NumPendingAttacks = 0;
		bTriggeredAttack = false;
		TimeSinceComboAvailable = 0;

		InitializeAlignment();
		MoveComp.bResolveMovementLocally.Apply(true, this);

		OpportunityAttackTarget.OnOpportunityAttackBegin.Broadcast(OpportunityAttackComp);
		OpportunityAttackTarget.OnOpportunityAttackSegmentStart.Broadcast(OpportunityAttackComp);
		Player.AddDamageInvulnerability(this);

		FailTime = GetFailTime();
		ExitTime = GetSuccessfulExitTime(); 
		FailKillTime = BIG_NUMBER;

		// Do not block gameplay action since that will cause other combat capabilities to deactivate out of order and invalidate attack data
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CombatComp.StopActiveAttackData(this);
		Player.RemoveTutorialPromptByInstigator(this);
		bShowingTutorial = false;
		if (OpportunityAttackComp.bAttackFailed)
			OpportunityAttackTarget.OnOpportunityAttackFailed.Broadcast(OpportunityAttackComp);
		else
			OpportunityAttackTarget.OnOpportunityAttackCompleted.Broadcast(OpportunityAttackComp);

		Player.RemoveDamageInvulnerability(this);

		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
		MoveComp.bResolveMovementLocally.Clear(this);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerNextAttack()
	{
		NumPendingAttacks += 1;
		Player.RemoveTutorialPromptByInstigator(this);
		bShowingTutorial = false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbFailAttack()
	{
		OpportunityAttackComp.bAttackFailed = true;
		OpportunityAttackComp.bIsAttacking = false;
		NumPendingAttacks = 0;	
		FailTime = BIG_NUMBER;
		UAnimSequence FailAnim = OpportunityAttackComp.GetCurrentSegment().Fail.Sequence;
		ExitTime = ActiveDuration + FailAnim.ScaledPlayLength;

		Player.RemoveDamageInvulnerability(this);
		FailKillTime = ActiveDuration + FailAnim.ScaledPlayLength;
		TArray<float32> NotifyInfo;
		if (FailAnim.GetAnimNotifyTriggerTimes(UGravityBladeOpportunityFailKillPlayerAnimNotify, NotifyInfo) && (NotifyInfo.Num() > 0))
			FailKillTime = ActiveDuration + (NotifyInfo[0] / Math::Max(0.1, FailAnim.RateScale));
			
		if (bShowingTutorial)	
			Player.RemoveTutorialPromptByInstigator(this);

		OpportunityAttackTarget.OnOpportunityAttackStartFailing.Broadcast(OpportunityAttackComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateAlignment();

		if (HasControl() && (ActiveDuration > FailTime))
			CrumbFailAttack();
		if (OpportunityAttackComp.bAttackFailed)
		{
			// Oh noes, we're undone!
			if (ActiveDuration > FailKillTime)
			{
				FailKillTime = BIG_NUMBER;	
				Player.KillPlayer();
			}
		}
		else
		{
			// Continue attack normally
			if (CombatComp.bInsideComboWindow)
			{
				if (OpportunityAttackComp.bIsAttacking && !bTriggeredAttack)
				{
					TimeSinceComboAvailable = 0;
					OpportunityAttackComp.bIsAttacking = false;
					CombatComp.ClearPreviousHitActors();
				}
			}
			else
			{
				bTriggeredAttack = false;
			}

			TimeSinceComboAvailable += DeltaTime;
			if (!OpportunityAttackComp.IsInFinalSegment())
			{
				if (TimeSinceComboAvailable > 0.5 && NumPendingAttacks == 0 && !bShowingTutorial && !OpportunityAttackComp.bIsAttacking)
				{
					FTutorialPrompt Prompt;
					Prompt.Action = ActionNames::PrimaryLevelAbility;
					Prompt.Text = NSLOCTEXT("GravityBlade", "OpportunityAttackPrompt", "Attack");
					Player.ShowTutorialPromptWorldSpace(Prompt, this, TargetMesh, FVector(0.0, 0.0, 0.0), AttachSocket = n"Spine1");
					bShowingTutorial = true;
				}	

				if (HasControl())
				{
					if (!OpportunityAttackComp.bIsAttacking)
					{
						if (WasActionStarted(ActionNames::PrimaryLevelAbility) && NumPendingAttacks == 0)
						{
							CrumbTriggerNextAttack();
						}
					}
				}

				if (!OpportunityAttackComp.bIsAttacking && NumPendingAttacks > 0)
				{
					// Start next attack
					OpportunityAttackComp.bIsAttacking = true;
					bTriggeredAttack = true;

					NumPendingAttacks--;
					OpportunityAttackComp.CurrentSegment++;
					FailTime = GetFailTime();
					ExitTime = GetSuccessfulExitTime();

					OpportunityAttackTarget.OnOpportunityAttackSegmentStart.Broadcast(OpportunityAttackComp);
				}
			}
		}

		if (MoveComp.PrepareMove(Movement))
		{
			// Local movement so we don't get crumb interpolation glitches
			// TODO: Test in network!
			if (ActiveDuration < RotateTowardsTargetEndTime)
				Movement.InterpRotationTo(ToTargetRot, 1.0 / RotateTowardsTargetEndTime);

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"OpportunityAttack");
		}
	}

	float GetFailTime() const
	{
		if (OpportunityAttackComp.IsInFinalSegment())
			return BIG_NUMBER; // Can't fail in final segment

		// Fail after reaching the end of current mh animation
		// FOpportunityAttackSegment CurSegment = OpportunityAttackComp.GetCurrentSegment();
		// return ActiveDuration + CurSegment.Attack.Sequence.ScaledPlayLength + CurSegment.Mh.Sequence.ScaledPlayLength; 
		return ActiveDuration + OpportunityAttackTarget.DurationUntilFail;
	}

	float GetSuccessfulExitTime() const
	{
		if (!OpportunityAttackComp.IsInFinalSegment())
			return BIG_NUMBER;

		// In final segment, we're done when we've completed the current attack
		FOpportunityAttackSegment CurSegment = OpportunityAttackComp.GetCurrentSegment();
		return ActiveDuration + CurSegment.Attack.Sequence.ScaledPlayLength;
	}

	void InitializeAlignment()
	{
		AlignStartMoveTime = 0.25;
		AlignMoveDuration = 0.5;
		AlignStartRotationTime = 0.75;
		AlignRotationDuration = 0.3;

		UAnimSequence StartAnim = OpportunityAttackComp.GetCurrentSegment().Attack.Sequence;
		TArray<FHazeAnimNotifyStateGatherInfo> MoveNotifyInfo;
		if (StartAnim.GetAnimNotifyStateTriggerTimes(UGravityBladeOpportunityAttackAlignMoveWindowAnimNotifyState, MoveNotifyInfo) && (MoveNotifyInfo.Num() > 0))
		{
			AlignStartMoveTime = MoveNotifyInfo[0].TriggerTime;
			AlignMoveDuration = MoveNotifyInfo[0].Duration;			
		}
		TArray<FHazeAnimNotifyStateGatherInfo> RotationNotifyInfo;
		if (StartAnim.GetAnimNotifyStateTriggerTimes(UGravityBladeOpportunityAttackAlignRotateWindowAnimNotifyState, RotationNotifyInfo) && (RotationNotifyInfo.Num() > 0))
		{
			AlignStartRotationTime = RotationNotifyInfo[0].TriggerTime;
			AlignRotationDuration = RotationNotifyInfo[0].Duration;			
		}
		if ((RotationNotifyInfo.Num() > 0) && (MoveNotifyInfo.Num() == 0))
			AlignStartMoveTime = BIG_NUMBER; // Rotation only is fine, this will move as well
		if (AlignStartRotationTime < AlignStartMoveTime)
			AlignStartMoveTime = BIG_NUMBER; // Rotation will start before move and will move as well, so skip separate move

		RotateTowardsTargetEndTime = Math::Min(AlignStartMoveTime, AlignStartRotationTime) - 0.05;	
		ToTargetRot = (OpportunityAttackTarget.WorldLocation - Player.ActorCenterLocation).ToOrientationQuat();
	}

	void UpdateAlignment()
	{
		if (ActiveDuration > AlignStartMoveTime)
		{
			AlignStartMoveTime = BIG_NUMBER;
			MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
			MoveComp.FollowComponentMovement(TargetMesh, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Normal, OpportunityAttackTarget.AlignSocket);
			FTransform Align = TargetMesh.GetSocketTransform(OpportunityAttackTarget.AlignSocket);
			Player.SmoothTeleportActor(Align.Location, Player.ActorRotation, this, AlignMoveDuration);	
		}

		if (ActiveDuration > AlignStartRotationTime)
		{
			AlignStartRotationTime = BIG_NUMBER;
			MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
			MoveComp.FollowComponentMovement(TargetMesh, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Normal, OpportunityAttackTarget.AlignSocket);
			FTransform Align = TargetMesh.GetSocketTransform(OpportunityAttackTarget.AlignSocket);
			Player.SmoothTeleportActor(Align.Location, Align.Rotator(), this, AlignRotationDuration);	
		}
	}

	void CheckAlignment()
	{
		FTransform Align = TargetMesh.GetSocketTransform(OpportunityAttackTarget.AlignSocket);
		if (!Align.Location.IsWithinDist(Player.Mesh.WorldLocation, 0.01))
			Debug::DrawDebugString(Player.FocusLocation, "LocDiff " + Player.Mesh.WorldLocation.Distance(Align.Location));
		if (!Align.Rotation.Equals(Player.Mesh.WorldRotation.Quaternion(), 0.01))
			Debug::DrawDebugString(Player.FocusLocation + FVector(0,0,20), "RotDiff " + (Player.Mesh.WorldRotation - Align.Rotator()));

		TArray<FHazePlayingAnimationData> TargetAnimations;
		TargetMesh.GetCurrentlyPlayingAnimations(TargetAnimations);
		for (FHazePlayingAnimationData AnimData : TargetAnimations)
		{
			float PlayLength = AnimData.Sequence.GetScaledPlayLength();
			PrintToScreenScaled("Target anim playlength: " + PlayLength + " pos: " + AnimData.CurrentPosition);			
		}
		TArray<FHazePlayingAnimationData> PlayerAnimations;
		Player.Mesh.GetCurrentlyPlayingAnimations(PlayerAnimations);
		for (FHazePlayingAnimationData AnimData : PlayerAnimations)
		{
			float PlayLength = AnimData.Sequence.GetScaledPlayLength();
			PrintToScreenScaled("Player anim playlength: " + PlayLength + " pos: " + AnimData.CurrentPosition);			
		}
	}
};
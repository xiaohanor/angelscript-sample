class UDragonSwordCombatGroundAttackCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordAttack);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordGroundAttack);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 85;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	UDragonSwordUserComponent SwordComp;
	UDragonSwordCombatUserComponent CombatComp;

	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UCombatHitStopComponent HitStopComp;
	USteppingMovementData Movement;

	float StartVelocity;
	FVector ForwardVector;
	FVector AccumulatedTranslation;
	float TotalMovementLength;
	float MinimumSuctionDistance;

	UDragonSwordCombatTargetComponent CurrentTarget;
	bool bHasFoundTarget = false;
	// bool bHasSnappedTowardsTarget = false;
	bool bHasHitTarget = false;

	bool bCanMove = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UDragonSwordUserComponent::Get(Owner);
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);

		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		HitStopComp = UCombatHitStopComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CombatComp.CanStartNewAttack())
			return false;

		if (CombatComp.PendingAttackData.AttackType != EDragonSwordCombatAttackType::Ground)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CombatComp.IsActiveAttackType(EDragonSwordCombatAttackType::Ground))
			return true;

		if (!CombatComp.GetHitUnderPlayer(DragonSwordCombat::GroundAttackDistanceThreshold).bBlockingHit)
			return true;

		if (ActiveDuration > CombatComp.ActiveAttackData.AnimationData.PlayLength)
			return true;

		if (CombatComp.HasPendingAttack())
		{
			if (CombatComp.bInsideComboWindow)
				return true;
		}

		if (CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasFoundTarget = false;
		// bHasSnappedTowardsTarget = false;
		bHasHitTarget = false;

		CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
		CombatComp.StartAttackAnimation();

		if (HasControl())
		{
			StartVelocity = MoveComp.Velocity.Size() * .75;
			AccumulatedTranslation = FVector::ZeroVector;

			// Get forward vector after turning towards movement direction
			//  then use our new forward to find suction target
			ForwardVector = CombatComp.GetMovementDirection(Player.ActorForwardVector);

			TotalMovementLength = CombatComp.ActiveAttackData.AnimationData.AttackData.MovementLength;
			if (CurrentTarget != nullptr)
			{
				const FVector ToTarget = (CurrentTarget.WorldLocation - Player.ActorCenterLocation);
				const FVector ToTargetHorizontal = ToTarget.VectorPlaneProject(Player.MovementWorldUp);

				// Calculate minimum distance we want to reach and extend
				//  our total root motion movement length to accommodate
				MinimumSuctionDistance = CombatComp.GetSuctionReachDistance(CurrentTarget);
				TotalMovementLength = Math::Max(TotalMovementLength, Math::Min(ToTargetHorizontal.Size() - MinimumSuctionDistance, CurrentTarget.SuctionReachDistance));
			}
			FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
			TraceSettings.UseSphereShape(70);
			auto HitResults = TraceSettings.QueryTraceMulti(Player.ActorLocation, Player.ActorLocation + ForwardVector * 100);
			bCanMove = true;
			for (auto Hit : HitResults)
			{
				if (Hit.Actor.IsA(AStoneBossWeakpoint))
				{
					float Dot = (Hit.ImpactPoint - Player.ActorLocation).GetSafeNormal().DotProduct(ForwardVector);
					bCanMove = Dot < 0.1;
					break;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Reset current combo when attack finishes
		if (CombatComp.HasActiveAttack() && CombatComp.ActiveAttackInstigator == this)
			CombatComp.StopActiveAttackData(this);

		if (IsBlocked())
			CombatComp.UnblockMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleMovement(DeltaTime);

		if (HasControl())
		{
			if (CombatComp.bInsideHitWindow)
			{
				bool bSuccessFulHit = CombatComp.TryAttack();
				if (bSuccessFulHit)
					bHasHitTarget = true;
			}
			// else if (bHasHitTarget)
			// {
			// 	CombatComp.FinishAttack();
			// }
		}

		SwordComp.PreviousSwordLocation = SwordComp.Weapon.ActorCenterLocation;
	}

	void HandleMovement(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			Movement.StopMovementWhenLeavingEdgeThisFrame();

			FVector RootMovement = SwordComp.GetRootMotion(AccumulatedTranslation, ActiveDuration, TotalMovementLength, CombatComp.ActiveAttackData.AnimationData.PlayLength);

			if (ActiveDuration < 0.2 && CurrentTarget == nullptr)
				TryFindNewTarget();

			RootMovement *= Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0),
															 DragonSwordCombat::RootMovementInputScale,
															 MoveComp.MovementInput.Size());
			// if we hit something set rotationspeed to 0 to prevent pingponging rotation
			const float RotationSpeed = bHasHitTarget ? 0 : 12;

			FQuat TargetRotation = FQuat::MakeFromZX(Player.MovementWorldUp, ForwardVector);
			FQuat NewRotation = FQuat::Slerp(Player.ActorQuat, TargetRotation, RotationSpeed * DeltaTime);
			FVector DeltaMovement = NewRotation.RotateVector(RootMovement);

			DeltaMovement = DeltaMovement.VectorPlaneProject(MoveComp.WorldUp);

			DeltaMovement += GetAdditionalMovement(ForwardVector, DeltaTime);

			if (bCanMove)
			{
				Movement.AddGravityAcceleration();
				if (!CombatComp.bHasHitWeakpointWithCurrentAttack && !(MoveComp.HasWallContact() && MoveComp.WallContact.Actor.IsA(AStoneBossWeakpoint)))
				{
					Movement.AddDelta(DeltaMovement);
					Movement.SetRotation(NewRotation);
				}
			}
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, DragonSwordCombat::Feature);
	}

	/**
	 * Find a new target if no target has previously been found
	 */
	void TryFindNewTarget()
	{
		if (bHasFoundTarget || bHasHitTarget)
			return;

		auto NewTarget = Cast<UDragonSwordCombatTargetComponent>(TargetablesComp.GetPrimaryTargetForCategory(DragonSwordCombat::TargetableCategory));
		if (NewTarget != nullptr)
		{
			CurrentTarget = NewTarget;
			bHasFoundTarget = true;
		}
	}

	/**
	 * Movement in addition to rootmotion
	 */
	FVector GetAdditionalMovement(FVector DesiredDirection, float DeltaTime)
	{
		if (CombatComp.ActiveAttackData.AnimationData.AttackData.AdditionalMovementDuration == 0)
			return FVector::ZeroVector;

		float Alpha = Math::Saturate(ActiveDuration / CombatComp.ActiveAttackData.AnimationData.AttackData.AdditionalMovementDuration);
		float AdditionalSpeed = Math::CircularIn(DragonSwordCombat::AdditionalMovementMaxSpeed, 0, Alpha);
		bool bCanChangeDirection = ActiveDuration < CombatComp.ActiveAttackData.AnimationData.AttackData.AdditionalMovementDuration;

		float InputStrength = 0;
		if (bCanChangeDirection)
		{
			const FVector Input = MoveComp.MovementInput;
			const FVector InputDirection = MoveComp.MovementInput.GetSafeNormal();
			const FVector ProjectedInput = InputDirection.VectorPlaneProject(Player.MovementWorldUp).GetSafeNormal();
			const float InputSize = Input.Size();
			if (ProjectedInput.DotProduct(DesiredDirection) > 0.3)
				InputStrength = InputSize > 1 ? 1 : InputSize;
		}

		return DesiredDirection * InputStrength * AdditionalSpeed * DeltaTime;
	}
}
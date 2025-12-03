struct FDragonSwordHitInfo
{
	UDragonSwordCombatResponseComponent ResponseComp;
	FVector ImpactPoint;
	FVector ImpactNormal;
}

struct FDragonSwordHitInfoSimple
{
	FDragonSwordHitInfoSimple(UDragonSwordCombatResponseComponent InResponseComp, FVector InHitDirection)
	{
		ResponseComp = InResponseComp;
		HitDirection = InHitDirection;
	}
	UDragonSwordCombatResponseComponent ResponseComp;
	FVector HitDirection;
}

UCLASS(Abstract, HideCategories = "ComponentTick ComponentReplication Debug Activation Variable Cooking Disable Tags AssetUserData Collision")
class UDragonSwordCombatUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = true;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Dragon Sword")
	FDragonSwordCombatAnimData AnimData;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword")
	TSubclassOf<UDragonSwordCombatMioTargetableWidget> TargetableWidget;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword")
	ULocomotionFeatureDragonSwordCombat AnimFeature;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword")
	TSubclassOf<ADragonSwordBoomerang> BoomerangClass;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	/* This is how much the y value of the pivot offset will be when the taret is max to the left of the screen */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Camera")
	float CameraLeftMaxOffset = -150.0;

	/* This is how much the y value of the pivot offset will be when the taret is max to the right of the screen */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Camera")
	float CameraRightMaxOffset = 50.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Camera Shake")
	TSubclassOf<UCameraShakeBase> HitCameraShake;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Camera Shake")
	TSubclassOf<UCameraShakeBase> RushCameraShake;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Camera Shake")
	TSubclassOf<UCameraShakeBase> SwingCameraShake;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Force Feedback")
	UForceFeedbackEffect HitForceFeedback;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Force Feedback")
	UForceFeedbackEffect SwingForceFeedback;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Force Feedback")
	UForceFeedbackEffect GroundPoundForceFeedback;

	// The attack that has been selected to be the next attack, but has not been used yet
	FDragonSwordCombatAttackData PendingAttackData;

	// The current attack
	FDragonSwordCombatAttackData ActiveAttackData;
	FInstigator ActiveAttackInstigator;

	// The attack that was last deactivated
	FDragonSwordCombatAttackData PreviousAttackData;

	FDragonSwordCombatComboData ComboData;
	bool bIsAirDash = false; // FL TODO: Temp because Air and Ground dash share the same type, but need different combo reset criteria

	// Notify States
	bool bInsideComboWindow;
	bool bInsideHitWindow;
	bool bInsideSettleWindow;

	bool bIsHoldingChargeAttack = false;

	EAnimHitPitch HitPitch = EAnimHitPitch::Center;
	EHazeCardinalDirection HitDirection = EHazeCardinalDirection::Forward;

	// Attack
	TArray<AActor> PreviouslyHitActors;

	private TMap<EDragonSwordAttackMovementType, int> SequenceIndices;
	private bool bMovementBlocked = false;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;
	private UPlayerMovementComponent MoveComp;
	private UPlayerSprintComponent SprintComp;
	private UDragonSwordUserComponent SwordComp;
	private UPlayerTargetablesComponent TargetablesComp;
	private UPlayerStepDashComponent StepDashComp;
	private UPlayerRollDashComponent RollDashComp;
	private UPlayerAirDashComponent AirDashComp;
	private UCombatHitStopComponent HitStopComp;
	UDragonSwordCombatInputComponent InputComp;

	// FL TODO: TEMP
	FVector LastGroundedLocation;

	bool bIsTraceDebugDrawEnabled = false;
	FVector DesiredFacingDirection;
	FVector ActivationMovementInput;

	bool bInsideComboGraceWindow = false;
	float TimeWhenStartedComboGrace = 0;
	float TimeWhenLastAttacked = 0;

	private uint CachedHitUnderPlayerFrame;
	FHitResult CachedHitUnderPlayer;

	TInstigated<bool> SwordBlockers;

	bool bHasHitSomething = false;

	ADragonSwordBoomerang SwordBoomerang;

	UHazeCapabilitySheet CurrentlyActiveSheet;

	bool bHasAppliedSlowmo = false;
	bool bHasHitWeakpointWithCurrentAttack = false;

	uint FrameLastAppliedHitStop;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		StepDashComp = UPlayerStepDashComponent::Get(Owner);
		RollDashComp = UPlayerRollDashComponent::Get(Owner);
		AirDashComp = UPlayerAirDashComponent::Get(Owner);
		SprintComp = UPlayerSprintComponent::Get(Owner);
		SwordComp = UDragonSwordUserComponent::Get(Owner);
		HitStopComp = UCombatHitStopComponent::Get(Owner);
		InputComp = UDragonSwordCombatInputComponent::GetOrCreate(Owner);
		AnimData.CombatComp = this;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// FL TODO: SUPER TEMP
		if (!MoveComp.IsInAir())
			LastGroundedLocation = Player.ActorCenterLocation;

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Anim Data");

		// Attack
		TemporalLog.Value("LastAttackFrame", AnimData.LastAttackFrame);
		TemporalLog.Value("LastAttackEndFrame", AnimData.LastAttackEndFrame);
		TemporalLog.Value("AttackTypeData", AnimData.AttackTypeData.ToType());
		TemporalLog.Value("AttackDuration", AnimData.AttackDuration);
		TemporalLog.Value("SequenceIndex", AnimData.SequenceIndex);
		TemporalLog.Value("AttackIndex", AnimData.AttackIndex);
#endif
	}

	UFUNCTION(DevFunction)
	void ActivateChargeAttackSheet(EDragonSwordChargeAttack NewAttack)
	{
		// if (CurrentlyActiveSheet == ChargeAttackSheets[NewAttack])
		// 	return;

		// if (CurrentlyActiveSheet != nullptr)
		// 	Player.StopCapabilitySheet(CurrentlyActiveSheet, this);

		// CurrentlyActiveSheet = ChargeAttackSheets[NewAttack];
		// Player.StartCapabilitySheet(CurrentlyActiveSheet, this);
	}

	void BlockSword(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		if (!SwordBlockers.Get())
		{
			// Player.BlockCapabilities(n"DragonSword", this);
			Player.BlockCapabilities(n"DragonSwordWielding", this);
		}

		SwordBlockers.Apply(true, Instigator, Priority);
	}

	void UnblockSword(FInstigator Instigator)
	{
		SwordBlockers.Clear(Instigator);
		if (!SwordBlockers.Get())
		{
			// Player.UnblockCapabilities(n"DragonSword", this);
			Player.UnblockCapabilities(n"DragonSwordWielding", this);
		}
	}

	bool HasSword()
	{
		return !SwordBlockers.Get();
	}

	bool HasBoomerang()
	{
		return SwordBoomerang != nullptr;
	}

	void SetPendingAttackData(FDragonSwordCombatAttackData InAttackData)
	{
		check(!PendingAttackData.IsValid());
		PendingAttackData = InAttackData;
		PendingAttackData.AttackDataType = EDragonSwordCombatAttackDataType::Pending;
	}

	void SetActiveAttackData(FDragonSwordCombatAttackData InAttackData, FInstigator Instigator)
	{
		bHasHitWeakpointWithCurrentAttack = false;
		bInsideHitWindow = false;
		bInsideComboWindow = false;
		ActiveAttackData = InAttackData;
		ActiveAttackData.AttackDataType = EDragonSwordCombatAttackDataType::Active;
		ActiveAttackInstigator = Instigator;

		if (PendingAttackData.IsValid())
			PendingAttackData.Invalidate();

		if (!ComboData.IsValid())
			ComboData = FDragonSwordCombatComboData(ActiveAttackData, this);
		else
			ComboData.AddAttack(ActiveAttackData);

		PreviouslyHitActors.Reset();
		UnblockMovement();
	}

	void UnblockMovement()
	{
		if (bMovementBlocked)
		{
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			bMovementBlocked = false;
		}
	}
	void BlockMovement()
	{
		if (!bMovementBlocked)
		{
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			bMovementBlocked = true;
		}
	}

	void StopActiveAttackData(FInstigator Instigator)
	{
		if (HasPendingAttack())
		{
			if (Player.Mesh.CanRequestLocomotion())
				Player.Mesh.RequestLocomotion(DragonSwordCombat::Feature, this);

			BlockMovement();
		}

		// It is only allowed to stop an active attack with the same instigator
		if (ActiveAttackInstigator != Instigator)
			return;

		PreviousAttackData = ActiveAttackData;
		PreviousAttackData.AttackDataType = EDragonSwordCombatAttackDataType::Previous;
		if (ActiveAttackData.IsValid())
			ActiveAttackData.Invalidate();

		bHasHitSomething = false;

		AnimData.LastAttackEndFrame = Time::FrameNumber;
	}

	void StartAttackAnimation()
	{
		AnimData.LastAttackFrame = Time::FrameNumber;
		AnimData.AttackTypeData = FDragonSwordCombatAttackTypeData(ActiveAttackData.AttackType);
		AnimData.AttackIndex = ActiveAttackData.AnimationData.AttackIndex;
		AnimData.SequenceIndex = ActiveAttackData.AnimationData.SequenceIndex;
		AnimData.AttackDuration = ActiveAttackData.AnimationData.PlayLength;

		FDragonSwordCombatStartAttackAnimationEventData EventData;
		EventData.AttackIndex = ActiveAttackData.AnimationData.AttackIndex;
		EventData.MovementType = ActiveAttackData.AttackTypeData.GetMovementType();
		EventData.HitType = ActiveAttackData.AnimationData.AttackData.HitType;
		EventData.AnimationDuration = ActiveAttackData.AnimationData.PlayLength;
		UDragonSwordCombatEventHandler::Trigger_StartAttackAnimation(SwordComp.Weapon, EventData);
		Player.PlayForceFeedback(ActiveAttackData.AnimationData.AttackData.ForceFeedbackEffect, false, false, this, 1.0);
		TimeWhenLastAttacked = Time::GameTimeSeconds;
	}

	bool ShouldExitSettle() const
	{
		if (!MoveComp.GetMovementInput().IsNearlyZero())
			return true;

		if (!MoveComp.IsOnAnyGround())
			return true;

		if (Player.IsStrafeEnabled())
			return true;

		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttackAnimation()
	{
		StartAttackAnimation();
	}

	FDragonSwordAttackDefinition GetAttackDefinitionFromAttackType(EDragonSwordCombatAttackType AttackType) const
	{
		switch (AttackType)
		{
			case EDragonSwordCombatAttackType::Air:
			case EDragonSwordCombatAttackType::AirRush:
				return AnimFeature.AnimData.AirAttacks;

			case EDragonSwordCombatAttackType::Dash:
			case EDragonSwordCombatAttackType::DashRush:
				return AnimFeature.AnimData.DashAttacks;

			case EDragonSwordCombatAttackType::Charge:
			case EDragonSwordCombatAttackType::Ground:
			case EDragonSwordCombatAttackType::GroundRush:
				return AnimFeature.AnimData.GroundAttacks;

			default:
				break;
				// case EDragonSwordCombatAttackType::Sprint:
				// 	return AnimData.SprintAttacks;
		}

		devCheck(false, "Tried to get AttackDefinition with invalid AttackType");
		return FDragonSwordAttackDefinition();
	}

	bool GetAttackAnimationData(EDragonSwordCombatAttackType InAttackType, int SequenceIndex, int InAttackIndex, FDragonSwordCombatAttackAnimationData&out OutAnimationData) const
	{
		const FDragonSwordAttackSequenceData Sequence = AnimFeature.GetSequenceFromAttackType(InAttackType, SequenceIndex);
		OutAnimationData = FDragonSwordCombatAttackAnimationData(Sequence, InAttackIndex, SequenceIndex);
		return OutAnimationData.IsValid();
	}

	FVector GetMovementDirection(FVector StartForward) const
	{
		if (MoveComp.MovementInput.IsNearlyZero())
		{
			FVector DesiredForward = InputComp.GetStoredAttackInputDirection();
			auto SplineLockComponent = UPlayerSplineLockComponent::Get(Player);
			if (SplineLockComponent != nullptr && SplineLockComponent.HasActiveSplineLock())
			{
				const FVector SplineLockedInput = SplineLockComponent.GetLockedMovementInput(DesiredForward);
				return SplineLockedInput;
			}

			return DesiredForward.VectorPlaneProject(Player.MovementWorldUp).GetSafeNormal();
		}

		const FVector InputDirection = MoveComp.MovementInput.GetSafeNormal();
		return InputDirection.VectorPlaneProject(Player.MovementWorldUp).GetSafeNormal();
	}

	bool HasPendingAttack() const
	{
		return PendingAttackData.IsValid();
	}

	bool HasActiveAttack() const
	{
		return ActiveAttackData.IsValid();
	}
	bool IsActiveAttackType(EDragonSwordCombatAttackType AttackType) const
	{
		return ActiveAttackData.IsValid() && ActiveAttackData.AttackType == AttackType;
	}

	bool HasPreviousAttack() const
	{
		return PreviousAttackData.IsValid();
	}

	bool HasActiveCombo() const
	{
		return ComboData.IsValid();
	}

	int GetSequenceIndexForType(EDragonSwordAttackMovementType MovementType)
	{
		if (!SequenceIndices.Contains(MovementType))
		{
			SequenceIndices.Add(MovementType, -1);
			return -1;
		}

		return SequenceIndices.FindOrAdd(MovementType);
	}

	// This function will progress to the next sequence index based on the attack definition settings and current index, it will return the new sequence index
	int ProgressToNextSequenceForType(EDragonSwordAttackMovementType MovementType)
	{
		int NewSequenceIndex;
		FDragonSwordAttackDefinition AttackDef = GetAttackDefinitionFromAttackType(FDragonSwordCombatAttackTypeData(MovementType).ToType());
		int CurrentSequenceIndex = GetSequenceIndexForType(MovementType);

		if (AttackDef.bRandomizeSequenceIndex)
		{
			TArray<int> ValidIndices;
			for (int i = 0; i < AttackDef.Sequences.Num(); i++)
			{
				if (i == CurrentSequenceIndex)
					continue;

				ValidIndices.Add(i);
			}

			NewSequenceIndex = ValidIndices[Math::RandRange(0, ValidIndices.Num() - 1)];
		}
		else
		{
			if (AttackDef.Sequences.Num() == 0)
				NewSequenceIndex = 0;
			else
				NewSequenceIndex = (CurrentSequenceIndex + 1) % AttackDef.Sequences.Num();
		}

		SequenceIndices.Add(MovementType, NewSequenceIndex);
		return NewSequenceIndex;
	}

	float GetSuctionReachDistance(UDragonSwordCombatTargetComponent TargetComponent) const
	{
		if (TargetComponent != nullptr && TargetComponent.bOverrideSuctionReachDistance)
			return TargetComponent.SuctionReachDistance;

		return DragonSwordCombat::IdealSuctionDistance;
	}

	EDragonSwordAttackMovementType GetCurrentMovementType() const
	{
		if (InputComp.WasPrimaryPressed())
		{
			if (MoveComp.IsInAir())
				return EDragonSwordAttackMovementType::Air;

			if (InputComp.WasPrimaryPressed() && (IsDashing() || IsSprinting()))
				return EDragonSwordAttackMovementType::Dash;

			return EDragonSwordAttackMovementType::Ground;
		}

		return EDragonSwordAttackMovementType::StillAttack;
		// //Secondary was pressed or is held
		// return EDragonSwordAttackMovementType::Charge;
	}

	/**
	 * We have multiple functions that wanted to know what was beneath the player,
	 * so we cached one trace here instead of doing multiple per frame.
	 */
	FHitResult GetHitUnderPlayer(float MaxDistance = 5000)
	{
		float DistanceToTrace = Math::Max(MaxDistance, 5000);
		if (CachedHitUnderPlayerFrame != Time::FrameNumber || (CachedHitUnderPlayer.Time > 0 && DistanceToTrace > CachedHitUnderPlayer.Distance / CachedHitUnderPlayer.Time))
		{
			FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
			// TraceSettings.DebugDrawOneFrame();
			CachedHitUnderPlayer = TraceSettings.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - Player.MovementWorldUp * DistanceToTrace);
			CachedHitUnderPlayerFrame = Time::FrameNumber;
		}

		if (CachedHitUnderPlayer.Distance > MaxDistance)
			return FHitResult();

		return CachedHitUnderPlayer;
	}

	bool CanStartNewAttack(bool bUsableWhileMoving = false) const
	{
		if (!bUsableWhileMoving && MoveComp.HasMovedThisFrame())
			return false;

		if (!SwordComp.IsWeaponEquipped())
			return false;

		if (!HasPendingAttack())
			return false;

		return true;
	}

	bool IsSprinting() const
	{
		return SprintComp.IsSprinting();
	}

	bool IsDashing() const
	{
		if (RollDashComp.IsDashing())
			return true;

		if (StepDashComp.IsDashing())
			return true;

		return false;
	}

	bool IsAirDashing() const
	{
		return AirDashComp.IsAirDashing();
	}

	void TriggerComboGrace()
	{
		if (!PreviousAttackData.IsValid())
			return;

		int NumAttacks = AnimFeature.GetSequenceFromAttackType(PreviousAttackData.AttackType, PreviousAttackData.AnimationData.SequenceIndex).Attacks.Num();
		if (PreviousAttackData.AnimationData.AttackIndex >= NumAttacks - 1)
		{
			// Don't enable gracewindow on last attack
			return;
		}

		bInsideComboGraceWindow = true;
		TimeWhenStartedComboGrace = Time::GameTimeSeconds;
	}

	void EndComboGrace()
	{
		bInsideComboGraceWindow = false;
	}

	void ApplyHitStop()
	{
		if (Time::FrameNumber <= FrameLastAppliedHitStop)
			return;
		if (ActiveAttackData.AnimationData.AttackData.HitType == EDragonSwordCombatAttackDataHitType::Sphere)
			return;

		FrameLastAppliedHitStop = Time::FrameNumber;
		HitStopComp.ApplyHitStop(this, 0.015);
		Player.PlayForceFeedback(HitForceFeedback, false, true, this);
	}

	void GetSwipeAttackHitTargets(TArray<FDragonSwordHitInfo>&out HitInfo, TArray<UDragonSwordCombatResponseComponent>&out HitInfoSimple, TArray<UDragonSwordCombatResponseComponent>&out HitInfoNoData)
	{
		// Trace around player for to find initial targets
		FHazeTraceSettings TraceSettings = DragonSwordTrace::GetSphereTraceSettings(ActiveAttackData.AnimationData.AttackData.TraceRange, IgnoreActors = PreviouslyHitActors, bDebugDraw = bIsTraceDebugDrawEnabled);
		auto Overlaps = TraceSettings.QueryOverlaps(Player.ActorCenterLocation);

		if (Overlaps.Num() == 0)
			return;

		FVector SwordLocation = SwordComp.Weapon.ActorCenterLocation;

		FVector DirToPrevSword = (SwordComp.PreviousSwordLocation - Player.ActorCenterLocation).GetSafeNormal2D();
		FVector DirToSword = (SwordLocation - Player.ActorCenterLocation).GetSafeNormal2D();

		FVector RightHorizontal = Player.ActorRightVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		FVector ForwardHorizontal = Player.ActorForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

		float AngleToPreviousSwordLocation = RightHorizontal.GetAngleDegreesTo(DirToPrevSword);
		AngleToPreviousSwordLocation = ForwardHorizontal.DotProduct(DirToPrevSword) > 0 ? AngleToPreviousSwordLocation : AngleToPreviousSwordLocation + 180;

		float AngleToNewSwordLocation = RightHorizontal.GetAngleDegreesTo(DirToSword);
		AngleToNewSwordLocation = ForwardHorizontal.DotProduct(DirToSword) > 0 ? AngleToNewSwordLocation : AngleToNewSwordLocation + 180;

		float MinAngle = Math::Min(AngleToPreviousSwordLocation, AngleToNewSwordLocation) - 10;
		float MaxAngle = Math::Max(AngleToPreviousSwordLocation, AngleToNewSwordLocation) + 10;

		for (auto Overlap : Overlaps.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;

			auto ResponseComp = UDragonSwordCombatResponseComponent::Get(Overlap.Actor);
			if (ResponseComp == nullptr)
				continue;

			if (Overlap.Actor.IsA(AStoneBossWeakpoint))
				bHasHitWeakpointWithCurrentAttack = true;

			FVector NearestOverlapPoint;
			Overlap.Component.GetClosestPointOnCollision(SwordLocation, NearestOverlapPoint);
			FVector DirToOverlapPoint = (NearestOverlapPoint - Player.ActorCenterLocation).GetSafeNormal2D();

			bool bIsInFront = DirToOverlapPoint.DotProduct(ForwardHorizontal) >= 0;

			float AngleToNearestOverlapPoint = RightHorizontal.GetAngleDegreesTo(DirToOverlapPoint);
			AngleToNearestOverlapPoint = bIsInFront ? AngleToNearestOverlapPoint : AngleToNearestOverlapPoint + 180;
			float Distance = NearestOverlapPoint.Dist2D(Player.ActorCenterLocation);

			if (Math::IsWithinInclusive(AngleToNearestOverlapPoint, MinAngle, MaxAngle) || (bIsInFront && Distance <= DragonSwordCombat::HitSafeRangeFront) || Distance <= DragonSwordCombat::HitSafeRange)
			{
				FVector ClosestPointToPreviousLocation;
				Overlap.Component.GetClosestPointOnCollision(SwordComp.PreviousSwordLocation, ClosestPointToPreviousLocation);

				switch (ResponseComp.ResponseDetailLevel)
				{
					case EDragonSwordResponseDetailLevel::None:
					{
						HitInfoNoData.AddUnique(ResponseComp);
					}
					break;
					case EDragonSwordResponseDetailLevel::Simple:
					{
						HitInfoSimple.AddUnique(ResponseComp);
					}
					break;
					case EDragonSwordResponseDetailLevel::Full:
					{
						FDragonSwordHitInfo Info;
						Info.ResponseComp = ResponseComp;
						Info.ImpactNormal = (NearestOverlapPoint - Overlap.Actor.ActorLocation).GetSafeNormal();
						Info.ImpactPoint = NearestOverlapPoint;
						HitInfo.AddUnique(Info);
					}
					break;
				}
				PreviouslyHitActors.Add(Overlap.Actor);
			}
		}
	}

	void GetSphereAttackHitTargets(TArray<FDragonSwordHitInfo>&out HitInfo,
								   TArray<UDragonSwordCombatResponseComponent>&out HitInfoSimple,
								   TArray<UDragonSwordCombatResponseComponent>&out HitInfoNoData)
	{
		FHazeTraceSettings TraceSettings = DragonSwordTrace::GetSphereTraceSettings(ActiveAttackData.AnimationData.AttackData.TraceRange, IgnoreActors = PreviouslyHitActors, bDebugDraw = bIsTraceDebugDrawEnabled);
		auto Overlaps = TraceSettings.QueryOverlaps(Player.ActorCenterLocation);

		if (Overlaps.Num() == 0)
			return;

		for (auto Overlap : Overlaps.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;

			auto ResponseComp = UDragonSwordCombatResponseComponent::Get(Overlap.Actor);
			if (ResponseComp == nullptr)
				continue;

			if (Overlap.Actor.IsA(AStoneBossWeakpoint))
				bHasHitWeakpointWithCurrentAttack = true;

			FVector ClosestPoint;
			Overlap.Component.GetClosestPointOnCollision(Player.ActorCenterLocation, ClosestPoint);
			switch (ResponseComp.ResponseDetailLevel)
			{
				case EDragonSwordResponseDetailLevel::None:
				{
					HitInfoNoData.AddUnique(ResponseComp);
				}
				break;
				case EDragonSwordResponseDetailLevel::Simple:
				{
					HitInfoSimple.AddUnique(ResponseComp);
				}
				break;
				case EDragonSwordResponseDetailLevel::Full:
				{
					FDragonSwordHitInfo Info;
					Info.ResponseComp = ResponseComp;
					Info.ImpactNormal = (Player.ActorCenterLocation - ClosestPoint).GetSafeNormal();
					Info.ImpactPoint = ClosestPoint;
					HitInfo.AddUnique(Info);
				}
				break;
			}
			PreviouslyHitActors.Add(Overlap.Actor);
		}
	}

	void GetStabAttackHitTargets(TArray<FDragonSwordHitInfo>&out HitInfo, TArray<UDragonSwordCombatResponseComponent>&out HitInfoSimple, TArray<UDragonSwordCombatResponseComponent>&out HitInfoNoData)
	{
		FHazeTraceSettings TraceSettings = DragonSwordTrace::GetStabTraceSettings(IgnoreActors = PreviouslyHitActors, bDebugDraw = bIsTraceDebugDrawEnabled);
		auto HitResults = TraceSettings.QueryTraceMulti(Player.ActorCenterLocation, Player.ActorCenterLocation + Player.ActorForwardVector * DragonSwordCombat::HitRange);

		if (HitResults.Num() == 0)
			return;

		for (auto HitResult : HitResults)
		{
			if (HitResult.Actor == nullptr)
				continue;

			auto ResponseComp = UDragonSwordCombatResponseComponent::Get(HitResult.Actor);
			if (ResponseComp == nullptr)
				continue;

			if (HitResult.Actor.IsA(AStoneBossWeakpoint))
				bHasHitWeakpointWithCurrentAttack = true;

			switch (ResponseComp.ResponseDetailLevel)
			{
				case EDragonSwordResponseDetailLevel::None:
					HitInfoNoData.AddUnique(ResponseComp);
					break;
				case EDragonSwordResponseDetailLevel::Simple:
					HitInfoSimple.AddUnique(ResponseComp);
					break;
				case EDragonSwordResponseDetailLevel::Full:
				{
					FDragonSwordHitInfo Info;
					Info.ResponseComp = ResponseComp;
					Info.ImpactNormal = HitResult.ImpactNormal;
					Info.ImpactPoint = HitResult.ImpactPoint;
					HitInfo.AddUnique(Info);
				}
				break;
			}
			PreviouslyHitActors.Add(HitResult.Actor);
		}
	}

	UFUNCTION()
	bool TryAttack()
	{
		if (HasControl())
		{
			TArray<FDragonSwordHitInfo> FullData;
			TArray<UDragonSwordCombatResponseComponent> SimpleDataResponses;
			TArray<UDragonSwordCombatResponseComponent> NoData;
			switch (ActiveAttackData.AnimationData.AttackData.HitType)
			{
				case EDragonSwordCombatAttackDataHitType::Swipe:
					GetSwipeAttackHitTargets(FullData, SimpleDataResponses, NoData);
					break;
				case EDragonSwordCombatAttackDataHitType::Stab:
					GetStabAttackHitTargets(FullData, SimpleDataResponses, NoData);
					break;
				case EDragonSwordCombatAttackDataHitType::Sphere:
					GetSphereAttackHitTargets(FullData, SimpleDataResponses, NoData);
					break;
				default:
					devError(f"Tried to trace for unimplemented attack type.");
					break;
			}
			TArray<FDragonSwordHitInfoSimple> SimpleData;
			SimpleData.Reserve(SimpleDataResponses.Num());
			for (auto Response : SimpleDataResponses)
			{
				SimpleData.Add(FDragonSwordHitInfoSimple(Response, (Response.Owner.ActorLocation - Player.ActorLocation).GetSafeNormal2D()));
			}
			
			int TotalNumHits = FullData.Num() + SimpleDataResponses.Num() + NoData.Num();
			if (TotalNumHits > 0)
				FinishAttack(FullData, SimpleData, NoData);

			return TotalNumHits > 0;
		}
		return false;
	}

	private void FinishAttack(TArray<FDragonSwordHitInfo> FullData, TArray<FDragonSwordHitInfoSimple> SimpleData, TArray<UDragonSwordCombatResponseComponent> NoData)
	{
		if (HasControl())
		{
			if (FullData.Num() > 0)
				CrumbHandleFullDataHits(FullData);
			
			if (SimpleData.Num() > 0)
			{
				int MaxArraySize = 12;
				if (SimpleData.Num() > MaxArraySize)
				{
					TArray<FDragonSwordHitInfoSimple> SplitSimpleData;
					SplitSimpleData.Reserve(MaxArraySize);
					for (int i = 0; i < SimpleData.Num(); i++)
					{
						SplitSimpleData.Add(SimpleData[i]);
						if (SplitSimpleData.Num() >= MaxArraySize)
						{
							CrumbHandleSimpleHits(SplitSimpleData);
							SplitSimpleData.Empty(MaxArraySize);
						}
					}

					if (SplitSimpleData.Num() > 0)
						CrumbHandleSimpleHits(SplitSimpleData);
				}
				else
				{
					CrumbHandleSimpleHits(SimpleData);
				}
			}
			if (NoData.Num() > 0)
				CrumbHandleNoDataHits(NoData);

			bHasHitSomething = true;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleSimpleHits(TArray<FDragonSwordHitInfoSimple> SimpleDataResponses)
	{
		ApplyHitStop();
		for (auto Data : SimpleDataResponses)
		{
			FDragonSwordHitDataSimple HitData;
			HitData.HitDirection = Data.HitDirection;
			EDamageType DamageType = EDamageType::MeleeSharp;
			if (ActiveAttackData.AnimationData.AttackData.HitType == EDragonSwordCombatAttackDataHitType::Sphere)
				DamageType = EDamageType::Impact;

			HitData.DamageType = DamageType;
			Data.ResponseComp.HitSimple(HitData);

			UDragonSwordCombatEventHandler::Trigger_OnHitEnemy(SwordComp.Weapon, FDragonSwordHitData());
		}
	}
	UFUNCTION(CrumbFunction)
	void CrumbHandleNoDataHits(TArray<UDragonSwordCombatResponseComponent> NoDataResponses)
	{
		ApplyHitStop();
		for (auto Response : NoDataResponses)
		{
			Response.HitNoData();
			UDragonSwordCombatEventHandler::Trigger_OnHitEnemy(SwordComp.Weapon, FDragonSwordHitData());
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleFullDataHits(TArray<FDragonSwordHitInfo> FullDataResponses)
	{
		ApplyHitStop();
		for (auto Info : FullDataResponses)
		{
			FVector Direction = (Info.ResponseComp.Owner.ActorLocation - Player.ActorLocation).GetSafeNormal();

			EDamageType DamageType = EDamageType::MeleeSharp;
			if (ActiveAttackData.AnimationData.AttackData.HitType == EDragonSwordCombatAttackDataHitType::Sphere)
				DamageType = EDamageType::Impact;

			FDragonSwordHitData HitData(Info.ImpactPoint, Info.ImpactNormal, Direction, DamageType);
			Info.ResponseComp.Hit(this, HitData, Player);

			UDragonSwordCombatEventHandler::Trigger_OnHitEnemy(SwordComp.Weapon, HitData);
		}
	}

	UDragonSwordUserComponent GetSwordComp()
	{
		return SwordComp;
	}
}
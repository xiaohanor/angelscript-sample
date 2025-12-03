struct FGravityBladeCombatThrowBladeData
{
	UGravityBladeCombatTargetComponent Target;
	FInstigator Instigator;
	float ThrowSpeed;
	float DelayBeforePulling;

	bool IsValid() const
	{
		return ::IsValid(Target);
	}
}

UCLASS(Abstract, HideCategories = "ComponentTick ComponentReplication Debug Activation Variable Cooking Disable Tags AssetUserData Collision")
class UGravityBladeCombatUserComponent : UActorComponent
{
	access Input = private, UGravityBladeCombatPrimaryInputCapability;
	access ReadOnly = private, * (readonly);

	default PrimaryComponentTick.bStartWithTickEnabled = true;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Gravity Blade")
	FGravityBladeCombatAnimData AnimData;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Gravity Blade")
	FGravityBladeCombatGloryKillAnimData GloryKillAnimData;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade")
	TSubclassOf<UGravityBladeHittableTargetWidget> TargetableWidget;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade")
	ULocomotionFeatureGravityBladeCombat AnimFeature;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade")
	ULocomotionFeatureGloryKill GloryKillAnimFeature;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsInRush;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera")
	float CameraSettingsInRushBlendInTime = 0.25;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera")
	float CameraSettingsInRushBlendOutTime = 0.25;

	/* This is how much the y value of the pivot offset will be when the taret is max to the left of the screen */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera")
	float CameraLeftMaxOffset = -150.0;

	/* This is how much the y value of the pivot offset will be when the taret is max to the right of the screen */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera")
	float CameraRightMaxOffset = 50.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera Shake")
	TSubclassOf<UCameraShakeBase> HitCameraShake;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera Shake")
	TSubclassOf<UCameraShakeBase> RushCameraShake;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Camera Shake")
	TSubclassOf<UCameraShakeBase> SwingCameraShake;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade")
	UForceFeedbackEffect HitForceFeedback;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Glory Kill")
	UHazeCameraSpringArmSettingsDataAsset GloryKillCameraSettings;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Glory Kill")
	UCameraPointOfInterestClearOnInputSettings GloryKillPOIClearOnInputSettings;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Glory Kill")
	float GloryKillCameraSettingBlendInTime = 2.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Glory Kill")
	float GloryKillCameraSettingBlendOutTime = -1.0;

	/** y: 0 is normal speed, y: 1 is max play rate, start time and rush speed multiplier, x: 0 is when you first start a combo, x: 1 is speed up duration after starting a combo.
	 * Curve is unclamped in both x/y axes so if you want to add more to the curve above 1 you can do so.
	 */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Speed Up")
	FRuntimeFloatCurve SpeedUpCurve;
	default SpeedUpCurve.AddDefaultKey(0.0, 0.0);
	default SpeedUpCurve.AddDefaultKey(1.0, 1.0);

	// How long the curve will take to go from x: 0 to x: 1.
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Speed Up")
	float SpeedUpDuration = 4.0;

	// How long it takes for the curve to evaluate from x: 1 to x: 0 (as soon as we enter a settle).
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Speed Up")
	float SpeedUpResetDuration = 1.0;

	// This play rate will be used at curve value y: 1. Since the curve is unclamped this is not the actual max play rate if y is above 1.
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Speed Up")
	float MaxSpeedUpPlayRate = 2.0;

	// This start time will be used at curve value y: 1. Since the curve is unclamped this is not the actual max start time if y is above 1.
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Speed Up")
	float MaxSpeedUpStartTime = 0.2;

	// This rush speed multiplier will be used at curve value y: 1. Since the curve is unclamped this is not the actual max rush speed multiplier if y is above 1.
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade|Speed Up")
	float MaxRushSpeedMultiplier = 2.0;

	// The attack that has been selected to be the next attack, but has not been used yet
	FGravityBladeCombatAttackData PendingAttackData;

	// The current attack
	FGravityBladeCombatAttackData ActiveAttackData;
	FInstigator ActiveAttackInstigator;

	// Active glory kill animation meta data
	FGravityBladeGloryKillAnimationWithMetaData ActiveGloryKillAnimation;
	FGravityBladeCombatGloryKillCameraData GloryKillCameraData;
	FQuat GloryKillWantedPlayerRotation;
	bool bGloryKillActive = false;
	bool bGloryKillInterrupted = false;

	// Input
	access:Input
	bool bIsPrimaryHeld = false;
	float PrimaryHoldStartTime = -1;
	float PrimaryHoldEndTime = -1;

	// Notify States
	bool bInsideComboWindow;
	bool bInsideHitWindow;
	bool bTriggerHitWindowFrame;
	bool bInsideSettleWindow;
	bool bInsideSpeedUpWindow;
	bool bInsideThrowBladeWindow;

	// Combo
	bool bHasActiveCombo = false;
	EGravityBladeAttackAnimationType ActiveComboType;
	int ActiveComboAttackIndex = 0;
	int ActiveComboSequenceIndex = 0;

	// Rush
	bool bIsRushing;

	// Recoil
	FGravityBladeRecoilData ActiveRecoil;

	EAnimHitPitch HitPitch = EAnimHitPitch::Center;
	EHazeCardinalDirection HitDirection = EHazeCardinalDirection::Forward;
	bool bHitWindowGuaranteeHitTargetEnemyImmediately;
	float HitWindowPushbackMultiplier = 1.0;
	float HitWindowExtraPushback = 0.0;

	// Attack
	TArray<AActor> HitActors;

	// This will mimic primary input, true means held down, false means not. Used to reproduce otherwise hard to reproduce bugs 100% of the time.
	bool bFakeDebugInput = false;
	int DebugInitialSequenceIndex = -1;

	private TMap<EGravityBladeAttackAnimationType, int> SequenceIndices;
	bool bMovementBlocked = false;

	float MostRecentDashTime = 0.0;
	EGravityBladeCombatDashType MostRecentDashType;
	FVector MostRecentDashDirection;

	TInstigated<bool> AllowAirAttackHover(false);

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;
	private UPlayerMovementComponent MoveComp;
	private UPlayerSprintComponent SprintComp;
	private UPlayerTargetablesComponent TargetablesComp;
	private UPlayerStepDashComponent StepDashComp;
	private UPlayerRollDashComponent RollDashComp;
	private UPlayerAirDashComponent AirDashComp;

	// Speed up stuff
	float CurrentSpeedUpCurveTime = 0.0;
	float CurrentSpeedUpCurveValue = 0.0;

	float CurrentSpeedUpPlayRate = 1.0;
	float CurrentSpeedUpStartTime = 0.0;
	float CurrentSpeedUpRushSpeedMultiplier = 1.0;

	bool bPreviousGloryKillWasAirborne = false;
	int PreviousGloryKillIndex = -1;

	// Throw blade stuff, when this is applied the throw should start, the pull should start a specified delay after that, then it should get cleared when the player has reached the target
	access:ReadOnly FGravityBladeCombatThrowBladeData ThrowBladeData;

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
		AnimData.CombatComp = this;

		GravityBladeGloryKillDevToggles::Index.MakeVisible();
		GravityBladeGloryKillDevToggles::Side.MakeVisible();
		GravityBladeGloryKillDevToggles::Disable.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		#if EDITOR

		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Anim Data");

		// Attack
		TemporalLog.Value("LastAttackFrame", AnimData.LastAttackFrame);
		TemporalLog.Value("LastAttackEndFrame", AnimData.LastAttackEndFrame);
		TemporalLog.Value("MovementType", AnimData.MovementType);
		TemporalLog.Value("AnimationType", AnimData.AnimationType);
		TemporalLog.Value("AttackDuration", AnimData.AttackDuration);
		TemporalLog.Value("SequenceIndex", AnimData.SequenceIndex);
		TemporalLog.Value("AttackIndex", AnimData.AttackIndex);
		
		// Rush
		TemporalLog.Value("RushStartFrame", AnimData.RushStartFrame);
		TemporalLog.Value("bIsRushing", AnimData.bIsRushing);
		TemporalLog.Value("RushAlpha", AnimData.RushAlpha);
		
		// Recoil
		TemporalLog.Value("LastRecoilFrame", AnimData.LastRecoilFrame);
		TemporalLog.Value("RecoilDuration", AnimData.RecoilDuration);
		TemporalLog.Value("RecoilDirection", AnimData.RecoilDirection);

		// Anim notify states
		TemporalLog.Value("bInsideComboWindow", bInsideComboWindow);
		TemporalLog.Value("bInsideHitWindow", bInsideHitWindow);
		TemporalLog.Value("bInsideSettleWindow", bInsideSettleWindow);
		TemporalLog.Value("bInsideSpeedUpWindow", bInsideSpeedUpWindow);

		// Pending attacks
		TemporalLog.Value("WasPrimaryPressed", WasPrimaryPressed());
		TemporalLog.Value("HasPendingAttack", HasPendingAttack());
		TemporalLog.Value("HasActiveAttack", HasActiveAttack());

		TemporalLog.Value("FirstFrameIsRightFootForward", AnimData.bFirstFrameHasRightFootForward);

		// Speed up
		TemporalLog.Value("CurrentSpeedUpCurveTime", CurrentSpeedUpCurveTime);
		TemporalLog.Value("CurrentSpeedUpCurveValue", CurrentSpeedUpCurveValue);

		TemporalLog.Value("CurrentSpeedUpPlayRate", CurrentSpeedUpPlayRate);
		TemporalLog.Value("CurrentSpeedUpStartTime", CurrentSpeedUpStartTime);
		TemporalLog.Value("CurrentSpeedUpRushSpeedMultiplier", CurrentSpeedUpRushSpeedMultiplier);

		#endif

		// Determine information about the player's most recent dash type for combo purposes
		if (RollDashComp.bTriggeredRollDashJump)
		{
			MostRecentDashTime = Time::GameTimeSeconds;
			MostRecentDashType = EGravityBladeCombatDashType::RollDashJump;
			MostRecentDashDirection = Player.ActorForwardVector;
		}
		else if (RollDashComp.IsDashing())
		{
			MostRecentDashTime = Time::GameTimeSeconds;
			MostRecentDashType = EGravityBladeCombatDashType::RollDash;
			MostRecentDashDirection = Player.ActorForwardVector;
		}
		else if (AirDashComp.IsAirDashing())
		{
			MostRecentDashTime = Time::GameTimeSeconds;
			MostRecentDashType = EGravityBladeCombatDashType::AirDash;
			MostRecentDashDirection = Player.ActorForwardVector;
		}
		else if (StepDashComp.IsDashing())
		{
			MostRecentDashTime = Time::GameTimeSeconds;
			MostRecentDashType = EGravityBladeCombatDashType::Dash;
			MostRecentDashDirection = Player.ActorForwardVector;
		}

		if (bMovementBlocked)
		{
			if (Player.IsPlayerDead() || !HasPendingAttack())
			{
				Player.UnblockCapabilities(CapabilityTags::Movement, this);
				bMovementBlocked = false;
			}
		}
	}

	bool DashedRecently()
	{
		return Time::GetGameTimeSince(MostRecentDashTime) < 0.4;
	}

	UFUNCTION(CrumbFunction)
	bool CrumbTrySetThrowBladeTarget(UGravityBladeCombatTargetComponent BladeTarget, float ThrowSpeed, float DelayBeforePulling, FInstigator Instigator)
	{
		if(ThrowBladeData.IsValid())
			return false;

		ThrowBladeData.Target = BladeTarget;
		ThrowBladeData.Instigator = Instigator;
		ThrowBladeData.ThrowSpeed = ThrowSpeed;
		ThrowBladeData.DelayBeforePulling = DelayBeforePulling;
		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbClearThrowBladeTargetByInstigator(FInstigator Instigator)
	{
		if(ThrowBladeData.Instigator != Instigator)
			return;

		ThrowBladeData.Target = nullptr;
		ThrowBladeData.Instigator = nullptr;
		ThrowBladeData.ThrowSpeed = -1.0;
	}

	UFUNCTION()
	void DebugSetFakeInputPressState(bool bPressed)
	{
		bFakeDebugInput = bPressed;
	}

	UFUNCTION()
	void DebugSetInitialSequenceIndex(int SequenceIndex)
	{
		DebugInitialSequenceIndex = SequenceIndex;
	}

	UFUNCTION(BlueprintCallable)
	void TriggerRecoil(FVector Direction, float InRecoilDuration = -1.0)
	{
		float RecoilDuration = InRecoilDuration;
		if (RecoilDuration < KINDA_SMALL_NUMBER)
			RecoilDuration = GravityBladeCombat::DefaultRecoilDuration;

		ActiveRecoil.StartTimestamp = Time::GameTimeSeconds;
		ActiveRecoil.Duration = RecoilDuration;
		ActiveRecoil.Direction = Direction;
	}

	void SetPendingAttackData(FGravityBladeCombatAttackData InAttackData)
	{
		check(!PendingAttackData.IsValid());
		PendingAttackData = InAttackData;
		PendingAttackData.AttackDataType = EGravityBladeCombatAttackDataType::Pending;
	}

	void SetActiveAttackData(FGravityBladeCombatAttackData InAttackData, FInstigator Instigator)
	{
		bInsideHitWindow = false;
		bInsideComboWindow = false;
		bInsideThrowBladeWindow = false;
		bTriggerHitWindowFrame = false;
		ActiveAttackData = InAttackData;
		ActiveAttackData.AttackDataType = EGravityBladeCombatAttackDataType::Active;
		ActiveAttackInstigator = Instigator;

		// Clear the most recent dash so we can no longer combo off it
		MostRecentDashTime = -1.0;

		bHasActiveCombo = true;
		ActiveComboType = ActiveAttackData.AnimationType;
		ActiveComboAttackIndex = ActiveAttackData.AttackIndex;
		ActiveComboSequenceIndex = ActiveAttackData.SequenceIndex;

		AnimData.CurrentSpeedUpPlayRate = CurrentSpeedUpPlayRate;
		AnimData.CurrentSpeedUpStartTime = CurrentSpeedUpStartTime;
		AnimData.CurrentSpeedUpRushSpeedMultiplier = CurrentSpeedUpRushSpeedMultiplier;

		if(ActiveAttackData.AnimationData.AnimationWithMetaData.AttackMetaData.AnimationFootOverride == EGravityBladeCombatAnimationFootOverride::Automatic)
		{
			AnimData.bFirstFrameHasRightFootForward = ActiveAttackData.AnimationData.AnimationWithMetaData.Animation.Sequence.IsRightFootForwardAtTime(0.0);
		}
		else if(ActiveAttackData.AnimationData.AnimationWithMetaData.AttackMetaData.AnimationFootOverride == EGravityBladeCombatAnimationFootOverride::Left)
		{
			AnimData.bFirstFrameHasRightFootForward = false;
		}
		else if(ActiveAttackData.AnimationData.AnimationWithMetaData.AttackMetaData.AnimationFootOverride == EGravityBladeCombatAnimationFootOverride::Right)
		{
			AnimData.bFirstFrameHasRightFootForward = true;
		}
		else
			devError("Forgot to add a case to handle right foot forward override");

		if(ActiveAttackData.IsRushAttack())
		{
			AnimData.bIsRushing = true;
			AnimData.RushStartFrame = Time::FrameNumber;

			// Prepare type, index and duration for rush to start the correct animation
			// Only wait with LastAttackFrame until StartAttackAnimation() is called.
			AnimData.MovementType = ActiveAttackData.MovementType;
			AnimData.AnimationType = ActiveAttackData.AnimationType;
			AnimData.AttackIndex = ActiveAttackData.AttackIndex;
			AnimData.SequenceIndex = ActiveAttackData.SequenceIndex;

			AnimData.AttackDuration = ActiveAttackData.AnimationData.AttackMetaData.Duration;
		}

		if(PendingAttackData.IsValid())
			PendingAttackData.Invalidate();

		SetSequenceIndexForType(ActiveAttackData.AnimationType, ActiveAttackData.SequenceIndex);
		HitActors.Reset();

		if(bMovementBlocked)
		{
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			bMovementBlocked = false;
		}
	}

	bool HasRemainingAttacksInCombo() const
	{
		if (!bHasActiveCombo)
			return false;

		FGravityBladeAttackDefinition AttackDefinition = GetAttackDefinitionFromAttackType(ActiveComboType);
		if (!AttackDefinition.Sequences.IsValidIndex(ActiveComboSequenceIndex))
			return false;

		if (!AttackDefinition.Sequences[ActiveComboSequenceIndex].Attacks.IsValidIndex(ActiveComboAttackIndex+1))
		{
			if (!AttackDefinition.bContinueComboBetweenSequences)
				return false;
		}

		return true;
	}

	bool IsComboOnLastAttackOfSequence() const
	{
		if (!bHasActiveCombo)
			return false;

		FGravityBladeAttackDefinition AttackDefinition = GetAttackDefinitionFromAttackType(ActiveComboType);
		if (!AttackDefinition.Sequences.IsValidIndex(ActiveComboSequenceIndex))
			return false;
		
		if (!AttackDefinition.Sequences[ActiveComboSequenceIndex].Attacks.IsValidIndex(ActiveComboAttackIndex))
			return false;

		if (AttackDefinition.Sequences[ActiveComboSequenceIndex].Attacks.IsValidIndex(ActiveComboAttackIndex+1))
			return false;

		return true;
	}

	bool IsAttackIndexValid(EGravityBladeAttackAnimationType AnimationType, int SequenceIndex, int AttackIndex) const
	{
		FGravityBladeAttackDefinition AttackDefinition = GetAttackDefinitionFromAttackType(AnimationType);
		if (!AttackDefinition.Sequences.IsValidIndex(SequenceIndex))
			return false;
		if (!AttackDefinition.Sequences[ActiveComboSequenceIndex].Attacks.IsValidIndex(AttackIndex))
			return false;
		return true;
	}

	void StopActiveAttackData(FInstigator Instigator, bool bBlockInterruptByMovement = true)
	{
		// It is only allowed to stop an active attack with the same instigator
		if (ActiveAttackInstigator != Instigator)
			return;

		if (HasPendingAttack()
			&& bBlockInterruptByMovement
			&& !Player.IsCapabilityTagBlocked(CapabilityTags::GameplayAction))
		{
			if(Player.Mesh.CanRequestLocomotion())
				Player.Mesh.RequestLocomotion(GravityBladeCombat::Feature, this);

			Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
			bMovementBlocked = true;
		}

		if (ActiveAttackData.IsRushAttack())
		{
			AnimData.bIsRushing = false;
			AnimData.RushAlpha = 0;
		}

		if (ActiveAttackData.IsValid())
			ActiveAttackData.Invalidate();
		
		AnimData.LastAttackEndFrame = Time::FrameNumber;
		ActiveAttackInstigator = nullptr;
	}

	void StartAttackAnimation()
	{
		AnimData.LastAttackFrame = Time::FrameNumber;
		AnimData.MovementType = ActiveAttackData.MovementType;
		AnimData.AnimationType = ActiveAttackData.AnimationType;
		AnimData.AttackIndex = ActiveAttackData.AttackIndex;
		AnimData.SequenceIndex = ActiveAttackData.SequenceIndex;

		AnimData.AttackDuration = ActiveAttackData.AnimationData.AttackMetaData.Duration;
		bInsideSettleWindow = false;
		bInsideHitWindow = false;
		bTriggerHitWindowFrame = false;
		bInsideComboWindow = false;

		if(ActiveAttackData.IsRushAttack())
		{
			AnimData.bIsRushing = false;
		}

		FGravityBladeCombatStartAttackAnimationEventData EventData;
		EventData.AttackIndex = ActiveAttackData.AttackIndex;
		EventData.MovementType = ActiveAttackData.MovementType;
		EventData.bIsSpin = ActiveAttackData.AnimationData.AttackMetaData.bIsSpin;
		float AnimationDuration = (ActiveAttackData.AnimationData.AttackMetaData.Duration - CurrentSpeedUpStartTime) / CurrentSpeedUpPlayRate;
		EventData.AnimationDuration = AnimationDuration;
		UGravityBladeCombatEventHandler::Trigger_StartAttackAnimation(GetBladeComp().Blade, EventData);

	}

	int GetGloryKillIndex(bool bAirborne, int IgnoreGloryKillIndex = -1) const
	{
		const TArray<FGravityBladeGloryKillAnimationLeftRightPair>& GloryKills = bAirborne ? GloryKillAnimFeature.AnimData.AirborneGloryKills : GloryKillAnimFeature.AnimData.GloryKillVariants;
		devCheck(GloryKills.Num() > 0, "There are no glory kill animation variants set up in glory kill feature!");

		if (GloryKills.Num() == 1)
			return 0;

		int PrevIndex = PreviousGloryKillIndex;
		if (bPreviousGloryKillWasAirborne != bAirborne)
			PrevIndex = -1;
		TArray<int> ValidGloryKillIndices;
		for(int i = 0; i < GloryKillAnimFeature.AnimData.GloryKillVariants.Num(); i++)
		{
			if(i == PrevIndex)
				continue;
			if(IgnoreGloryKillIndex == i)
				continue;

			ValidGloryKillIndices.Add(i);
		}

		if (ValidGloryKillIndices.Num() == 0)
			return -1;

		int Index = ValidGloryKillIndices[Math::RandRange(0, ValidGloryKillIndices.Num() - 1)]; 
#if TEST
		Index = GravityBladeGloryKillDevToggles::GetOverrideIndex(Index, GloryKills.Num());
#endif		
		return Index;
	}
	
	bool IsGloryKillValidToPerform(UGravityBladeCombatTargetComponent Target, int GloryKillIndex, bool bAirborne, bool bUseRightFoot) const
	{
		const TArray<FGravityBladeGloryKillAnimationLeftRightPair>& GloryKills = bAirborne ? GloryKillAnimFeature.AnimData.AirborneGloryKills : GloryKillAnimFeature.AnimData.GloryKillVariants;
		const FGravityBladeGloryKillAnimationWithMetaData& Animation = bUseRightFoot ? GloryKills[GloryKillIndex].RightAnimation : GloryKills[GloryKillIndex].LeftAnimation;

		if (Owner.ActorLocation.IsWithinDist(Target.Owner.ActorLocation, Animation.MetaData.MinDistance))
			return false; // Too close to target for this glory kill

		if (!bAirborne)
		{
			if (!Animation.MetaData.bAllowIntoWall || !Animation.MetaData.bAllowOverEdge)
			{
				// Check if we would drop off a ledge or move into a wall if we did this glory kill
				float Distance = Animation.MetaData.MovementLength;

				FHazeTraceSettings Trace;
				Trace.TraceWithPlayerProfile(Player);
				Trace.IgnoreActor(Player);
				Trace.IgnoreActor(Target.Owner);
				Trace.UseLine();
				// Trace.DebugDraw(5.0);

				int TraceCount = 5;
				FVector StartLocation = Target.Owner.ActorLocation;
				FVector TraceDirection = Player.ActorForwardVector;
				FVector WorldUp = Player.MovementWorldUp;

				float TraceSpacing = Distance / (TraceCount-1);
				float PlayerHeight = WorldUp.DotProduct(Player.ActorLocation);

				for (int TraceIndex = 0; TraceIndex < TraceCount; ++TraceIndex)
				{
					FVector TraceMidPoint = StartLocation + TraceDirection * (TraceSpacing * TraceIndex);
					FVector TraceUpperPoint = TraceMidPoint + WorldUp * 200.0;
					FVector TraceLowerPoint = TraceMidPoint - WorldUp * 200.0;

					FHitResult Hit = Trace.QueryTraceSingle(TraceUpperPoint, TraceLowerPoint);
					
					// If the trace was penetrating that means there's a wall here
					if (Hit.bStartPenetrating)
					{
						if (Animation.MetaData.bAllowIntoWall)
							continue;
						else
							return false;
					}

					// If the trace didn't hit the floor, then we can't do this glory kill because it would take us over the ledge
					if (!Hit.bBlockingHit)
					{
						if (Animation.MetaData.bAllowOverEdge)
							continue;
						else
							return false;
					}

					float Height = WorldUp.DotProduct(Hit.ImpactPoint);
					if (Height < PlayerHeight - 40.0 || Height > PlayerHeight + 40.0)
					{
						if (Animation.MetaData.bAllowOverEdge)
							continue;
						else
							return false;
					}
				}
			}
		}

		return true;
	}

	void StartGloryKill(int Index, bool bAirborne, bool bUseRightFoot)
	{
		PreviousGloryKillIndex = Index;
		bPreviousGloryKillWasAirborne = bAirborne;

		GloryKillAnimData.GloryKillAnimationIndex = Index;
		GloryKillAnimData.LastAttackFrame = Time::FrameNumber;
		GloryKillAnimData.bRightFootForward = bUseRightFoot;
		GloryKillAnimData.bAirborne = bAirborne;

		FGravityBladeGloryKillAnimationLeftRightPair LeftRightAnimationPair = GloryKillAnimFeature.AnimData.GloryKillVariants[Index];
		if(GloryKillAnimData.bRightFootForward)
			ActiveGloryKillAnimation = LeftRightAnimationPair.RightAnimation;
		else
			ActiveGloryKillAnimation = LeftRightAnimationPair.LeftAnimation;

		UGravityBladeCombatEnforcerGloryDeathComponent GloryDeathComp = UGravityBladeCombatEnforcerGloryDeathComponent::Get(ActiveAttackData.Target.Owner);
		GloryDeathComp.StartGloryDeath(Index, ActiveGloryKillAnimation.MetaData.Duration, Player, GloryKillAnimData.bRightFootForward, bAirborne);
	}

	bool ShouldExitSettle() const
	{
 		if(!MoveComp.GetMovementInput().IsNearlyZero())
 			return true;
		
 		if (!MoveComp.IsOnAnyGround())
 			return true;

		if(Player.IsStrafeEnabled())
			return true;

		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttackAnimation()
	{
		StartAttackAnimation();
	}

	FGravityBladeAttackDefinition GetAttackDefinitionFromAttackType(EGravityBladeAttackAnimationType AttackType) const
	{
		return AnimFeature.GetAttackDefinitionFromAttackType(AttackType);
	}

	FGravityBladeAttackSequenceData GetSequenceFromAttackType(EGravityBladeAttackAnimationType AttackType, int SequenceIndex) const
	{
		return AnimFeature.GetSequenceFromAttackType(AttackType, SequenceIndex);
	}

	bool GetAttackAnimationData(EGravityBladeAttackAnimationType InAttackType, int SequenceIndex, int InAttackIndex, FGravityBladeCombatAttackAnimationData&out InAnimationData) const
	{
		const FGravityBladeAttackSequenceData Sequence = GetSequenceFromAttackType(InAttackType, SequenceIndex);
		InAnimationData = FGravityBladeCombatAttackAnimationData(Sequence, InAttackIndex, false, SequenceIndex);
		return InAnimationData.IsValid();
	}

	FVector GetMovementDirection(const FVector& StartForward) const
	{
		if (MoveComp.MovementInput.IsNearlyZero())
		{
			if (Player.GetCurrentGameplayPerspectiveMode() != EPlayerMovementPerspectiveMode::ThirdPerson)
			{
				// If we are in 2D mode, don't default to the camera rotation but use the character rotation instead
				return Player.ActorForwardVector.VectorPlaneProject(Player.MovementWorldUp).GetSafeNormal();
			}
			
			return StartForward.VectorPlaneProject(Player.MovementWorldUp).GetSafeNormal();
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

	int GetSequenceIndexForType(EGravityBladeAttackAnimationType AnimationType) const
	{
		if(!SequenceIndices.Contains(AnimationType))
			return -1;

		return SequenceIndices[AnimationType];
	}

	// This function will progress to the next sequence index based on the attack definition settings and current index, it will return the new sequence index
	int GetNextSequenceIndexForType(EGravityBladeAttackAnimationType AnimationType) const
	{
		if(DebugInitialSequenceIndex >= 0)
		{
			return DebugInitialSequenceIndex;
		}

		int NewSequenceIndex;
		FGravityBladeAttackDefinition AttackDef = GetAttackDefinitionFromAttackType(AnimationType);
		int CurrentSequenceIndex = GetSequenceIndexForType(AnimationType);

		if(AttackDef.bRandomizeSequenceIndex)
		{
			TArray<int> ValidIndices;
			for(int i = 0; i < AttackDef.Sequences.Num(); i++)
			{
				if(i == CurrentSequenceIndex)
					continue;

				ValidIndices.Add(i);
			}

			NewSequenceIndex = ValidIndices[Math::RandRange(0, ValidIndices.Num() - 1)];
		}
		else
			NewSequenceIndex = (CurrentSequenceIndex + 1) % AttackDef.Sequences.Num();

		return NewSequenceIndex;
	}

	private void SetSequenceIndexForType(EGravityBladeAttackAnimationType AnimationType, int NewSequenceIndex)
	{
		DebugInitialSequenceIndex = -1;
		SequenceIndices.Add(AnimationType, NewSequenceIndex);
	}

	float GetSuctionReachDistance(UGravityBladeCombatTargetComponent TargetComponent) const
	{
		if (TargetComponent != nullptr && TargetComponent.bOverrideSuctionReachDistance)
			return TargetComponent.SuctionReachDistance;
		
		return GravityBladeCombat::SuctionDistance;
	}

	float GetSuctionMinimumDistance(UGravityBladeCombatTargetComponent TargetComponent) const
	{
		if (TargetComponent != nullptr)
			return TargetComponent.SuctionMinimumDistance;
		
		return GravityBladeCombat::SuctionMinimumDistance;
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

	bool WasPrimaryPressed() const
	{
		return (PrimaryHoldStartTime + GravityBladeCombat::InputBufferTime >= Time::GameTimeSeconds);
	}

	bool IsPrimaryHeld(float Threshold = -1) const
	{
		if(!bIsPrimaryHeld)
			return false;

		if(Threshold < 0)
			return bIsPrimaryHeld;

		return Time::GetGameTimeSince(PrimaryHoldStartTime) > Threshold;
	}
	
	bool WasPrimaryReleased() const
	{
		if(PrimaryHoldEndTime < 0)
			return false;

		return (!bIsPrimaryHeld && PrimaryHoldEndTime + GravityBladeCombat::InputBufferTime >= Time::GameTimeSeconds);
	}
	
	float GetPrimaryHoldTime() const
	{
		if (bIsPrimaryHeld)
			return Time::GetGameTimeSince(PrimaryHoldStartTime);

		return (PrimaryHoldEndTime - PrimaryHoldStartTime);
	}

	float GetTimeToHit(FGravityBladeCombatAttackAnimationWithMetaData AttackAnimation) const
	{
		if (AttackAnimation.Animation.Sequence == nullptr)
			return 0;

		float TimeOfHit = AttackAnimation.Animation.Sequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow);
		return TimeOfHit;
	}

	float GetMovementLengthBeforeHit(FGravityBladeCombatAttackAnimationWithMetaData AttackAnimation) const
	{
		if (AttackAnimation.Animation.Sequence == nullptr)
			return 0;

		float TimeOfHit = AttackAnimation.Animation.Sequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow);
		float MovementPctAtHit = AttackAnimation.Animation.Sequence.GetMoveRatioAtTime(TimeOfHit, AttackAnimation.Animation.Sequence.PlayLength).X;
		return AttackAnimation.AttackMetaData.MovementLength * MovementPctAtHit;
	}

	float GetMovementLengthAfterHit(FGravityBladeCombatAttackAnimationWithMetaData AttackAnimation) const
	{
		if (AttackAnimation.Animation.Sequence == nullptr)
			return 0;

		float TimeOfHit = AttackAnimation.Animation.Sequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow);
		float MovementPctAtHit = AttackAnimation.Animation.Sequence.GetMoveRatioAtTime(TimeOfHit, AttackAnimation.Animation.Sequence.PlayLength).X;
		return AttackAnimation.AttackMetaData.MovementLength * (1.0 - MovementPctAtHit);
	}

	void TraceForHitsForActiveAttack()
	{
		FGravityBladeCombatAttackAnimationMetaData AttackMetaData = ActiveAttackData.AnimationData.AttackMetaData;

		float MovementLength = GetMovementLengthAfterHit(ActiveAttackData.AnimationData.AnimationWithMetaData);
		float KnockbackLength = MovementLength * HitWindowPushbackMultiplier + HitWindowExtraPushback;
		KnockbackLength = Math::Max(KnockbackLength, GravityBladeCombat::MinimumKnockbackLength * HitWindowPushbackMultiplier);

		TraceForHits(
			AttackMetaData.Damage,
			KnockbackLength,
			ActiveAttackData.MovementType,
			ActiveAttackData.AnimationType,
			HitActors);
	}

	void ClearPreviousHitActors()
	{
		HitActors.Reset();
	}


	private const float BladeStart = -50.0;
	private const float BladeLength = 130.0;
	private const int Iterations = 20;

	private bool TraceBladeMovementAgainstMesh(
		UPrimitiveComponent TraceComp,
		FTransform PreviousBladeTransform,
		FTransform BladeTransform,

		FVector&out ImpactPoint,
		FVector&out ImpactNormal,
	)
	{
		FHazeTraceSettings BladeTrace = Trace::InitAgainstComponent(TraceComp);

		FHitResult ClosestHit;
		float ClosestHitDistance = MAX_flt;

		for (int i = 0; i < Iterations; ++i)
		{
			float Offset = BladeStart + (BladeLength - BladeStart) / Iterations * i;
			FVector TraceStart = PreviousBladeTransform.Location + PreviousBladeTransform.Rotation.UpVector * Offset;
			FVector TraceEnd = BladeTransform.Location + BladeTransform.Rotation.UpVector * (Offset + 0.01);

			FHitResult Hit = BladeTrace.QueryTraceComponent(TraceStart, TraceEnd);

			#if !RELEASE
			if (GravityBladeCombat::CVar_DebugBladeTraces.GetInt() != 0)
			{
				Debug::DrawDebugLine(TraceStart, TraceEnd, FLinearColor::Red, Duration = 10.0);
			}
			#endif

			float Distance = 0;
			if (Hit.bBlockingHit)
			{
				Distance = Hit.Location.Distance(TraceStart);
			}
			else if (Hit.bStartPenetrating)
			{
				Distance = 0.0;
			}
			else
			{
				continue;
			}

			if (Distance < ClosestHitDistance)
			{
				ClosestHit = Hit;
				ClosestHitDistance = Distance;
			}
		}

		if (ClosestHit.bBlockingHit)
		{
			ImpactPoint = ClosestHit.ImpactPoint;
			ImpactNormal = ClosestHit.ImpactNormal;
			return true;
		}
		else if (ClosestHit.bStartPenetrating)
		{
			ImpactPoint = ClosestHit.ImpactPoint;
			ImpactNormal = (ClosestHit.TraceEnd - ClosestHit.TraceStart).GetSafeNormal();
			return true;
		}
		else
		{
			return false;
		}
	}

	private bool TraceHitObstructedByWall(UPrimitiveComponent TraceComp, FVector ImpactPoint)
	{
		FHazeTraceSettings ObstructTrace;
		ObstructTrace.UseLine();

		ObstructTrace.TraceWithChannel(ECollisionChannel::WorldGeometry);
		ObstructTrace.IgnorePlayers();
		ObstructTrace.IgnoreActor(TraceComp.Owner);
		
		FHitResult ObstructHit = ObstructTrace.QueryTraceSingle(Player.ActorCenterLocation, ImpactPoint);
		if (ObstructHit.bBlockingHit || ObstructHit.bStartPenetrating)
			return true;
		return false;
	}

	void TraceForHits(float Damage, float MovementLength,
		EGravityBladeAttackMovementType MovementType,
		EGravityBladeAttackAnimationType AnimationType,
		TArray<AActor>& PreviouslyHitActors
	)
	{
		bool bHasHitAnythingBefore = PreviouslyHitActors.Num() > 0;
		bool bAttackHasTarget = ActiveAttackData.IsValid() && ActiveAttackData.GetTarget() != nullptr;

		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceMio);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);
		Trace.IgnoreActors(PreviouslyHitActors);
		Trace.UseSphereShape(GravityBladeCombat::HitRange);

		FTransform PreviousBladeTransform = GetBladeComp().Blade.PreviousFrameStartBladeTranform;
		FTransform BladeTransform = GetBladeComp().Blade.CurrentFrameStartBladeTranform;

#if !RELEASE
		if (GravityBladeCombat::CVar_DebugBladeTraces.GetInt() != 0)
		{
			Trace.DebugDrawOneFrame();

			Debug::DrawDebugLine(
				PreviousBladeTransform.TransformPosition(FVector(0, 0, BladeStart)),
				PreviousBladeTransform.TransformPosition(FVector(0, 0, BladeLength)),
				FLinearColor::Blue, Duration = 10.0);

			Debug::DrawDebugLine(
				BladeTransform.TransformPosition(FVector(0, 0, BladeStart)),
				BladeTransform.TransformPosition(FVector(0, 0, BladeLength)),
				FLinearColor::Green, Duration = 10.0);

			Debug::DrawDebugLine(
				BladeTransform.TransformPosition(FVector(0, 0, BladeLength)),
				PreviousBladeTransform.TransformPosition(FVector(0, 0, BladeLength)),
				FLinearColor::Yellow, Duration = 10.0);
		}
#endif

		auto Overlaps = Trace.QueryOverlaps(Player.ActorCenterLocation);
		for (auto Overlap : Overlaps.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;

			if(PreviouslyHitActors.Contains(Overlap.Actor))
				continue;

			auto ResponseComp = UGravityBladeCombatResponseComponent::Get(Overlap.Actor);
			if (ResponseComp != nullptr
				&& !ResponseComp.IsResponseComponentDisabled()
				&& HasControl())
			{
				FVector ImpactPoint;
				FVector ImpactNormal;

				UPrimitiveComponent TraceComp = Overlap.Component;

				// Trace against the character mesh if we hit one
				AHazeCharacter Character = Cast<AHazeCharacter>(TraceComp);
				if (Character != nullptr)
					TraceComp = Character.Mesh;

				if (bHitWindowGuaranteeHitTargetEnemyImmediately)
				{
					if (ActiveAttackData.IsValid()
						&& ActiveAttackData.GetTarget() != nullptr
						&& Overlap.Actor == ActiveAttackData.GetTarget().Owner)
					{
						TraceComp.GetClosestPointOnCollision(Player.ActorCenterLocation, ImpactPoint);
						ImpactNormal = Player.ActorForwardVector;
					}
					else
					{
						continue;
					}
				}
				else
				{
					bool bHasHit = TraceBladeMovementAgainstMesh(TraceComp,
						PreviousBladeTransform, BladeTransform,
						ImpactPoint, ImpactNormal);
					if (!bHasHit)
						continue;
				}

				if (ResponseComp.bPreventHittingThroughCollision && TraceHitObstructedByWall(TraceComp, ImpactPoint))
					continue;

				FGravityBladeHitData HitData;
				HitData.Damage = Damage;
				HitData.DamageType = EDamageType::MeleeSharp;
				HitData.AttackMovementLength = MovementLength;
				HitData.Actor = Overlap.Actor;
				HitData.Component = Overlap.Component;
				HitData.ImpactPoint = ImpactPoint;
				HitData.ImpactNormal = ImpactNormal;
				HitData.MovementType = MovementType;
				HitData.AnimationType = AnimationType;

				CrumbHit(ResponseComp, HitData, !bHasHitAnythingBefore);
				
				bHasHitAnythingBefore = true;
				PreviouslyHitActors.Add(Overlap.Actor);
			}
		}

		// Check if we've hit Zoe
		if (Game::Zoe.HasControl()
			&& !PreviouslyHitActors.Contains(Game::Zoe)
			&& !bAttackHasTarget
			&& Player.ActorCenterLocation.Distance(Game::Zoe.ActorLocation) < GravityBladeCombat::HitRange
			&& !Game::Zoe.IsPlayerInvulnerable()
			&& !Game::Zoe.IsCapabilityTagBlocked(n"PvPDamage")
			)
		{
			FVector ImpactPoint;
			FVector ImpactNormal;

			bool bHasHit = TraceBladeMovementAgainstMesh(Game::Zoe.Mesh,
				PreviousBladeTransform, BladeTransform,
				ImpactPoint, ImpactNormal);

			if (bHasHit && !TraceHitObstructedByWall(Game::Zoe.Mesh, ImpactPoint))
			{
				FVector HorizontalDirection = -ImpactNormal;
				HorizontalDirection = HorizontalDirection.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

				auto HealthComp = UPlayerHealthComponent::Get(Game::Zoe);
				if (HealthComp.WouldDieFromDamage(0.5, true) && HealthComp.CanTakeDamage(false))
				{
					USkylinePVPEffectHandler::Trigger_KilledByOtherPlayer(Game::Zoe);

					auto RespawnComp = UPlayerRespawnComponent::Get(Game::Zoe);
					RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawnAfterKilledByOtherPlayer");
				}
				else
				{
					USkylinePVPEffectHandler::Trigger_HitByOtherPlayer(Game::Zoe);
				}

				Game::Zoe.DamagePlayerHealth(0.5);
				Game::Zoe.ApplyKnockdown(HorizontalDirection * 300, 1.0);
				PreviouslyHitActors.Add(Game::Zoe);

				if (HitForceFeedback != nullptr)
					Player.PlayForceFeedback(HitForceFeedback, false, true, this, 2);
			}
		}
	}

	UFUNCTION()
	private void OnRespawnAfterKilledByOtherPlayer(AHazePlayerCharacter RespawnedPlayer)
	{
		auto RespawnComp = UPlayerRespawnComponent::Get(RespawnedPlayer);
		RespawnComp.OnPlayerRespawned.UnbindObject(this);

		USkylinePVPEffectHandler::Trigger_RespawnedAfterKilledByOtherPlayer(RespawnedPlayer);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHit(UGravityBladeCombatResponseComponent ResponseComp, FGravityBladeHitData HitData, bool bPlayCameraShake)
	{
		float CameraImpulseMultiplier = 1.0;
		if (ActiveAttackData.IsValid() && ActiveAttackData.MovementType == EGravityBladeAttackMovementType::OpportunityAttack)
			CameraImpulseMultiplier = GravityBladeCombat::OpportunityAttackCameraImpulseMultiplier;

		if (bPlayCameraShake && !SceneView::IsFullScreen())
		{
			FVector HorizontalDirection = -HitData.ImpactNormal;
			HorizontalDirection = HorizontalDirection.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			FHazeCameraImpulse Impulse;
			Impulse.WorldSpaceImpulse = HorizontalDirection * 600.0 * CameraImpulseMultiplier;
			//Impulse.CameraSpaceImpulse = FVector(1600,0,0);
			Impulse.ExpirationForce = 25.0;
			Impulse.Dampening = 1.0;
			Player.ApplyCameraImpulse(Impulse, this);
		}

		if (bPlayCameraShake && !SceneView::IsFullScreen())
		{
			FVector HorizontalDirection = -HitData.ImpactNormal;
			HorizontalDirection = HorizontalDirection.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			FHazeCameraImpulse Impulse;
			//Impulse.WorldSpaceImpulse = HorizontalDirection * 600.0;
			Impulse.CameraSpaceImpulse = FVector(500,0,0) * CameraImpulseMultiplier;
			Impulse.ExpirationForce = 25.0;
			Impulse.Dampening = 1.0;
			Player.ApplyCameraImpulse(Impulse, this);
		}

		if (IsValid(ResponseComp))
		{
			ResponseComp.Hit(this, HitData);

			float HitStopDuration = 0.05;

			auto PlayerHitStopComp = UCombatHitStopComponent::GetOrCreate(Player);
			if (PlayerHitStopComp != nullptr)
				PlayerHitStopComp.ApplyHitStop(this, HitStopDuration);

			auto TargetHitStopComp = UCombatHitStopComponent::Get(ResponseComp.Owner);
			if (TargetHitStopComp != nullptr)
				TargetHitStopComp.ApplyHitStop(this, HitStopDuration);

			if (HitForceFeedback != nullptr)
				Player.PlayForceFeedback(HitForceFeedback, false, true, this, 2);
		}

		UGravityBladeCombatEventHandler::Trigger_OnHitEnemy(GetBladeComp().Blade, HitData);
	}

	void OnTargetKilled(UGravityBladeCombatTargetComponent Target)
	{
		
	}

	// FB TODO: Quick fix
	UGravityBladeUserComponent GetBladeComp() const
	{
		return UGravityBladeUserComponent::Get(Owner);
	}

#if EDITOR
	void DebugDrawAttack(FVector ForwardVector, float MinimumSuctionDistance) const
	{
		if (Console::GetConsoleVariableInt("Haze.AutoAimDebug") <= 0)
			return;

		const FVector Origin = Player.ActorLocation;
		const FVector UpVector = Player.MovementWorldUp;

		Debug::DrawDebugLine(Origin, Origin + ForwardVector * GravityBladeCombat::MaxRushDistance, FLinearColor::Yellow);
		const float HitWindowAlpha = (bInsideHitWindow ? 1.0 : 0.25);
		Debug::DrawDebugArc(GravityBladeCombat::MaxHitAngle * 2.0,
			Origin,
			GravityBladeCombat::HitRange,
			ForwardVector,
			FLinearColor::Red * HitWindowAlpha,
			3.0,
			UpVector);

		Debug::DrawDebugCircle(Origin, GravityBladeCombat::HitSafeRange, LineColor = FLinearColor::DPink);

		if (ActiveAttackData.Target != nullptr)
		{
			const FVector GroundLocation = ActiveAttackData.Target.WorldLocation.PointPlaneProject(Player.ActorLocation, Player.MovementWorldUp);
			Debug::DrawDebugCircle(GroundLocation, MinimumSuctionDistance);
		}
	}
#endif
}

namespace GravityBladeGloryKillDevToggles
{
	const FHazeDevToggleCategory Category = FHazeDevToggleCategory(n"GloryKill");
	const FHazeDevToggleBool Disable = FHazeDevToggleBool(Category, n"Disable glory kills"); 
	const FHazeDevToggleGroup Index = FHazeDevToggleGroup(Category, n"Glory kill index");
	const FHazeDevToggleGroup Side = FHazeDevToggleGroup(Category, n"Glory kill side");
	const FHazeDevToggleOption IndexAny = FHazeDevToggleOption(Index, n"Any", true);
	const FHazeDevToggleOption Index0 = FHazeDevToggleOption(Index, n"0");
	const FHazeDevToggleOption Index1 = FHazeDevToggleOption(Index, n"1");
	const FHazeDevToggleOption Index2 = FHazeDevToggleOption(Index, n"2");
	const FHazeDevToggleOption Index3 = FHazeDevToggleOption(Index, n"3");
	const FHazeDevToggleOption SideBest = FHazeDevToggleOption(Side, n"Best", true);
	const FHazeDevToggleOption SideLeft = FHazeDevToggleOption(Side, n"Left");
	const FHazeDevToggleOption SideRight = FHazeDevToggleOption(Side, n"Right");

	int GetOverrideIndex(int CurIndex, int NumAvailable)
	{
		if (IndexAny.IsEnabled() || NumAvailable == 0)
			return CurIndex;
		if (Index0.IsEnabled())
			return 0;
		if (Index1.IsEnabled())
			return 1 % NumAvailable;
		if (Index2.IsEnabled())
			return 2 % NumAvailable;
		if (Index3.IsEnabled())
			return 3 % NumAvailable;
		return CurIndex;
	}

	bool GetOverrideSideRight(bool CurSide)
	{
		if (SideLeft.IsEnabled())
			return false;
		if (SideRight.IsEnabled())
			return true;
		return CurSide;
	}
}
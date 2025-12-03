UCLASS(Abstract)
class UFeatureAnimInstanceCopsGunAimOverride : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureCopsGunAimOverride Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureCopsGunAimOverrideAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimSpaceVariable;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimValues;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset LeftArmBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset RightArmBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset SwingingBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset MovementBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset DefaultArmBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset AttachOnlyBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset SpineBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset DetonateRightArmBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset DetonateLeftArmBoneFilter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUsingRightAimspace;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotThisTickLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotGrenadeThisTickLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDetonatingLeftGrenade;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotThisTickRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotGrenadeThisTickRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDetonatingRightGrenade;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingShootAnimationLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingShootGrenadeAnimationLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingDetonateGrenadeAnimationLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingDetonateGrenadeAnimationRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingShootAnimationRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingShootGrenadeAnimationRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDetonateBackwardRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsOverheated;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bOverheatedThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSideScroller;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator OverHeatSpineRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator OverHeatSpineRotationNegative;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SwingingRotation;

	UIslandRedBlueWeaponUserComponent RedBlueWeaponComp;
	UPlayerWallRunComponent WallRunComp;
	UPlayerActionModeComponent ActionModeComp;
	UPlayerSwingComponent SwingComp;
	UPlayerRollDashComponent RollDashComp;

	bool bFromRollDashJump;
	bool bFromRollDash;
	bool bFromAnimationThatBlockedWeapons;
	bool bOneHandedGrenadeDetonate;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		RedBlueWeaponComp = UIslandRedBlueWeaponUserComponent::Get(HazeOwningActor);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(HazeOwningActor);
		ActionModeComp = UPlayerActionModeComponent::GetOrCreate(HazeOwningActor);
		SwingComp = UPlayerSwingComponent::GetOrCreate(Player);
		RollDashComp = UPlayerRollDashComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureCopsGunAimOverride NewFeature = GetFeatureAsClass(ULocomotionFeatureCopsGunAimOverride);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		AimValues = CalculateAimAngles(RedBlueWeaponComp.WeaponAnimData.AimDirection, Player.ActorTransform);
		bUsingRightAimspace = AimValues.X >= 0;

		SwingingRotation = FRotator::ZeroRotator;

		bSideScroller = Feature.Tag == n"CopsGunAimOverride2D";
		bFromRollDashJump = RollDashComp.bTriggeredRollDashJump;
		float TimeSince = Time::GetGameTimeSince(RollDashComp.LastRollDashActivation);
		bFromRollDash = TimeSince < 0.5;

		bFromAnimationThatBlockedWeapons = false;
		if (RedBlueWeaponComp.TimeOfUnblockWeaponsFromAnimation.IsSet())
		{
			TimeSince = Time::GetGameTimeSince(RedBlueWeaponComp.TimeOfUnblockWeaponsFromAnimation.Value);
			bFromAnimationThatBlockedWeapons = TimeSince < 0.3;
		}

		bIsPlayingDetonateGrenadeAnimationLeft = false;
		bIsPlayingDetonateGrenadeAnimationRight = false;
		bOneHandedGrenadeDetonate = false;
		UpdateWeaponCompGrenadeAnimRunningBools();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		ActionModeComp.IncreaseActionScore(0.1 * DeltaTime);

		if (CheckValueChangedAndSetBool(bShotThisTickRight, RedBlueWeaponComp.WeaponAnimData.bShotThisTickRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootAnimationRight = true;

		if (CheckValueChangedAndSetBool(bShotThisTickLeft, RedBlueWeaponComp.WeaponAnimData.bShotThisTickLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootAnimationLeft = true;

		if (CheckValueChangedAndSetBool(bShotGrenadeThisTickRight, RedBlueWeaponComp.WeaponAnimData.bShotGrenadeThisTickRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootGrenadeAnimationRight = true;

		if (CheckValueChangedAndSetBool(bShotGrenadeThisTickLeft, RedBlueWeaponComp.WeaponAnimData.bShotGrenadeThisTickLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootGrenadeAnimationLeft = true;

		bOverheatedThisTick = CheckValueChangedAndSetBool(bIsOverheated, RedBlueWeaponComp.WeaponAnimData.bIsOverheated, EHazeCheckBooleanChangedDirection::FalseToTrue);

		// ------ AIM VALUES --------

		FTransform ActorAimCalcTransform = Player.ActorTransform;
		if (LocomotionAnimationTag == n"SwingAir")
		{
			SwingingRotation = SwingComp.AnimData.SwingRotation;

			// If we're in swinging, modify the actor transform to take the swing rotation into accout.
			ActorAimCalcTransform.SetRotation(Player.ActorTransform.TransformRotation(SwingingRotation));
		}
		else if (SwingingRotation != FRotator::ZeroRotator)
			SwingingRotation = Math::RInterpTo(SwingingRotation, FRotator::ZeroRotator, DeltaTime, 5);

		if (bSideScroller)
			CalculateAimValues2D(ActorAimCalcTransform);
		else
			CalculateAimValues3D(ActorAimCalcTransform);

		OverHeatSpineRotation.Pitch = Math::FInterpTo(OverHeatSpineRotation.Pitch,
													  Math::Clamp(HazeOwningActor.ActorVelocity.SizeSquared() / 500000, 0.0, 1.0) * -30,
													  DeltaTime,
													  8);
		OverHeatSpineRotationNegative.Pitch = -OverHeatSpineRotation.Pitch;

		if (CheckValueChangedAndSetBool(bDetonatingRightGrenade, RedBlueWeaponComp.WeaponAnimData.bDetonatingRightGrenade, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			bDetonateBackwardRight = (bSideScroller && AimSpaceVariable.X < 0);

			bOneHandedGrenadeDetonate = !RedBlueWeaponComp.WeaponAnimData.bDetonatingHeldWeapons;
			if (bDetonateBackwardRight)
				bIsPlayingDetonateGrenadeAnimationLeft = true;
			else if (!bOneHandedGrenadeDetonate && AimSpaceVariable.X > 0)
				bIsPlayingDetonateGrenadeAnimationLeft = true;
			else
				bIsPlayingDetonateGrenadeAnimationRight = true;

		}

		if (CheckValueChangedAndSetBool(bDetonatingLeftGrenade, RedBlueWeaponComp.WeaponAnimData.bDetonatingLeftGrenade, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			bDetonateBackwardRight = (bSideScroller && AimSpaceVariable.X < 0);

			bOneHandedGrenadeDetonate = !RedBlueWeaponComp.WeaponAnimData.bDetonatingHeldWeapons;

			if (bDetonateBackwardRight)
				bIsPlayingDetonateGrenadeAnimationLeft = true;
			else if (!bOneHandedGrenadeDetonate && AimSpaceVariable.X < 0)
				bIsPlayingDetonateGrenadeAnimationRight = true;
			else
				bIsPlayingDetonateGrenadeAnimationLeft = true;
		}

		if (!bIsPlayingDetonateGrenadeAnimationLeft && !bIsPlayingDetonateGrenadeAnimationRight)
			bOneHandedGrenadeDetonate = false;

		UpdateWeaponCompGrenadeAnimRunningBools();
	}

	void UpdateWeaponCompGrenadeAnimRunningBools()
	{
		bool bLeftWasRunning = RedBlueWeaponComp.bIsLeftGrenadeAnimRunning;
		bool bRightWasRunning = RedBlueWeaponComp.bIsRightGrenadeAnimRunning;

		RedBlueWeaponComp.bIsLeftGrenadeAnimRunning = bIsPlayingDetonateGrenadeAnimationLeft || bIsPlayingShootGrenadeAnimationLeft;
		RedBlueWeaponComp.bIsRightGrenadeAnimRunning = bIsPlayingDetonateGrenadeAnimationRight || bIsPlayingShootGrenadeAnimationRight;

		if(bLeftWasRunning && !RedBlueWeaponComp.bIsLeftGrenadeAnimRunning)
		{
			RedBlueWeaponComp.TimeOfLeftGrenadeAnimStopped.Set(Time::GetGameTimeSeconds());
		}

		if(bRightWasRunning && !RedBlueWeaponComp.bIsRightGrenadeAnimRunning)
		{
			RedBlueWeaponComp.TimeOfRightGrenadeAnimStopped.Set(Time::GetGameTimeSeconds());
		}
	}

	void CalculateAimValues3D(FTransform& ActorTransform)
	{
		AimValues = CalculateAimAngles(RedBlueWeaponComp.WeaponAnimData.AimDirection, ActorTransform);
		AimSpaceVariable = AimValues;

		if (bUsingRightAimspace)
		{
			bUsingRightAimspace = AimValues.X >= 0 || AimValues.X < -155;
			if (bUsingRightAimspace && AimValues.X < -155)
			{
				float ExtraValue = 180 + AimSpaceVariable.X;
				AimSpaceVariable.X = 180 + ExtraValue;
			}
		}
		else
		{
			bUsingRightAimspace = !(AimValues.X < 0 || AimValues.X > 155);
			if (!bUsingRightAimspace && AimValues.X > 155)
			{
				float ExtraValue = 180 - AimSpaceVariable.X;
				AimSpaceVariable.X = -180 - ExtraValue;
			}
		}
	}

	void CalculateAimValues2D(FTransform& ActorTransform)
	{
		const FVector AimDirCS = ActorTransform.InverseTransformVectorNoScale(RedBlueWeaponComp.WeaponAnimData.AimDirection);
		AimSpaceVariable = FVector2D(AimDirCS.X, AimDirCS.Z);
	}

	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{
		if (OverrideFeatureTag == NAME_None)
		{
			if (RedBlueWeaponComp.HasWeaponsInHands())
			{
				if (!RedBlueWeaponComp.WeaponAnimData.bIsOverheated ||
					(TopLevelGraphRelevantStateName == n"Overheat" && TopLevelGraphRelevantAnimTimeRemaining < 0.2))
				{
					bOutUseMeshSpaceBlend = false;
					OutBlendTime = 0.4;
					return AttachOnlyBoneFilter;
				}
			}
		}

		bOutUseMeshSpaceBlend = true;
		if (LocomotionAnimationTag == n"WallRun")
		{
			if (WallRunComp.AnimData.RunAngle > 0)
			{
				return LeftArmBoneFilter;
			}

			return RightArmBoneFilter;
		}

		if (LocomotionAnimationTag == n"SwingAir")
			return SwingingBoneFilter;

		if (LocomotionAnimationTag == n"Slide")
			return Player.IsMio() ? LeftArmBoneFilter : RightArmBoneFilter;

		if (LocomotionAnimationTag == n"Jetpack")
			return SpineBoneFilter;

		if (bOneHandedGrenadeDetonate)
		{
			bOutUseMeshSpaceBlend = false;

			if (bIsPlayingDetonateGrenadeAnimationLeft)
				return DetonateLeftArmBoneFilter;
			return DetonateRightArmBoneFilter;
		}

		if (GetActiveAnimationTag() == n"Movement")
			return MovementBoneFilter;

		return DefaultArmBoneFilter;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"KnockDown")
			return true;

		if (HasAnimationStatus(n"DoubleJump"))
			return true;

		if (LocomotionAnimationTag == n"Dash")
			return true;

		if (RedBlueWeaponComp.HasWeaponsInHands())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (bFromRollDashJump)
			return 0.2;

		if (bFromRollDash)
			return 0.2;

		if (bFromAnimationThatBlockedWeapons)
			return 0.2;

		return 0.05;
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTimeToNullFeature() const
	{
		if (LocomotionAnimationTag == n"Dash")
			return 0.05;

		return 0.4;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	UFUNCTION()
	void AnimNotify_StopShootingLeft()
	{
		bIsPlayingShootAnimationLeft = false;
	}

	UFUNCTION()
	void AnimNotify_StopShootingRight()
	{
		bIsPlayingShootAnimationRight = false;
	}

	UFUNCTION()
	void AnimNotify_StopShootingGrenadeLeft()
	{
		bIsPlayingShootGrenadeAnimationLeft = false;
		UpdateWeaponCompGrenadeAnimRunningBools();
	}

	UFUNCTION()
	void AnimNotify_StopShootingGrenadeRight()
	{
		bIsPlayingShootGrenadeAnimationRight = false;
		UpdateWeaponCompGrenadeAnimRunningBools();
	}

	UFUNCTION()
	void AnimNotify_StopDetonateRight()
	{
		bIsPlayingDetonateGrenadeAnimationRight = false;
		UpdateWeaponCompGrenadeAnimRunningBools();
	}

	UFUNCTION()
	void AnimNotify_StopDetonateLeft()
	{
		bIsPlayingDetonateGrenadeAnimationLeft = false;
		UpdateWeaponCompGrenadeAnimRunningBools();
	}
}

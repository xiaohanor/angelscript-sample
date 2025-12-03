UCLASS(Abstract)
class UFeatureAnimInstanceCopsGunAimOverrideMeltdown : UHazeFeatureSubAnimInstance
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

	UPROPERTY()
	bool bUsingRightAimspace;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotThisTickLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotGrenadeThisTickLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDetonatingLeftGrenadeThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDetonatingLeftGrenade;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotThisTickRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotGrenadeThisTickRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDetonatingRightGrenade;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDetonatingRightGrenadeThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingShootAnimationLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingShootGrenadeAnimationLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingShootAnimationRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingShootGrenadeAnimationRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsOverheated;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bOverheatedThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SwingingRotation;

	UPROPERTY()
	UHazeBoneFilterAsset LeftArmBoneFilter;

	UPROPERTY()
	UHazeBoneFilterAsset RightArmBoneFilter;

	UPROPERTY()
	UHazeBoneFilterAsset SwingingBoneFilter;

	UPROPERTY()
	UHazeBoneFilterAsset DefaultArmBoneFilter;

	UMeltdownGlitchShootingUserComponent RedBlueWeaponComp;
	UPlayerWallRunComponent WallRunComp;
	UPlayerSwingComponent SwingComp;
	
	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		RedBlueWeaponComp = UMeltdownGlitchShootingUserComponent::Get(HazeOwningActor);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(HazeOwningActor);
		SwingComp = UPlayerSwingComponent::GetOrCreate(Player);
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

		RedBlueWeaponComp = UMeltdownGlitchShootingUserComponent::Get(HazeOwningActor);

		AimValues = CalculateAimAngles(RedBlueWeaponComp.AimDirection, Player.ActorTransform);
		bUsingRightAimspace = AimValues.X >= 0;

		SwingingRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		FTransform ActorAimCalcTransform = Player.ActorTransform;
		if (LocomotionAnimationTag == n"SwingAir")
		{
			SwingingRotation = SwingComp.AnimData.SwingRotation;

			// If we're in swinging, modify the actor transform to take the swing rotation into accout.
			ActorAimCalcTransform.SetRotation(Player.ActorTransform.TransformRotation(SwingingRotation));
		}
		else if (SwingingRotation != FRotator::ZeroRotator)
			SwingingRotation = Math::RInterpTo(SwingingRotation, FRotator::ZeroRotator, DeltaTime, 5);

		AimValues = CalculateAimAngles(RedBlueWeaponComp.AimDirection, ActorAimCalcTransform);

		// if (CheckValueChangedAndSetBool(bShotThisTickRight, RedBlueWeaponComp.WeaponAnimData.bShotThisTickRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
		// 	bIsPlayingShootAnimationRight = true;

		// if (CheckValueChangedAndSetBool(bShotThisTickLeft, RedBlueWeaponComp.WeaponAnimData.bShotThisTickLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
		// 	bIsPlayingShootAnimationLeft = true;

		// if (CheckValueChangedAndSetBool(bShotGrenadeThisTickRight, RedBlueWeaponComp.WeaponAnimData.bShotGrenadeThisTickRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
		// 	bIsPlayingShootGrenadeAnimationRight = true;

		// if (CheckValueChangedAndSetBool(bShotGrenadeThisTickLeft, RedBlueWeaponComp.WeaponAnimData.bShotGrenadeThisTickLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
		// 	bIsPlayingShootGrenadeAnimationLeft = true;

		// bDetonatingRightGrenade = RedBlueWeaponComp.WeaponAnimData.bDetonatingRightGrenade;
		// bDetonatingLeftGrenade = RedBlueWeaponComp.WeaponAnimData.bDetonatingLeftGrenade;

		// bOverheatedThisTick = CheckValueChangedAndSetBool(bIsOverheated, RedBlueWeaponComp.WeaponAnimData.bIsOverheated, EHazeCheckBooleanChangedDirection::FalseToTrue);

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

		// PrintToScreen("X; " + AimSpaceVariable.X + " Y; " + AimSpaceVariable.Y);
	}

	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{

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

		return DefaultArmBoneFilter;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{

		if (LocomotionAnimationTag == n"KnockDown")
			return true;


		if (LocomotionAnimationTag == n"Dash")
			return true;

		if (HasAnimationStatus(n"DoubleJump"))
			return true;

		if (TopLevelGraphRelevantStateName == n"Overheat")
			return IsTopLevelGraphRelevantAnimFinished();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.05;
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTimeToNullFeature() const
	{
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
	}

	UFUNCTION()
	void AnimNotify_StopShootingGrenadeRight()
	{
		bIsPlayingShootGrenadeAnimationRight = false;
	}
}

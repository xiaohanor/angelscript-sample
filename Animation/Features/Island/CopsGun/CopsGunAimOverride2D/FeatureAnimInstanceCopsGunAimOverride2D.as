UCLASS(Abstract)
class UFeatureAnimInstanceCopsGunAimOverride2D : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureCopsGunAimOverride2D Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureCopsGunAimOverride2DAnimData AnimData;

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

	UIslandRedBlueWeaponUserComponent RedBlueWeaponComp;

	UPROPERTY()
	UScifiPlayerCopsGunSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureCopsGunAimOverride2D NewFeature = GetFeatureAsClass(ULocomotionFeatureCopsGunAimOverride2D);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		RedBlueWeaponComp = UIslandRedBlueWeaponUserComponent::Get(HazeOwningActor);

		AimValues = CalculateAimAngles(RedBlueWeaponComp.WeaponAnimData.AimDirection, Player.ActorTransform);
		bUsingRightAimspace = AimValues.X >= 0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		AimValues = CalculateAimAngles(RedBlueWeaponComp.WeaponAnimData.AimDirection, Player.ActorTransform);

		if (CheckValueChangedAndSetBool(bShotThisTickRight, RedBlueWeaponComp.WeaponAnimData.bShotThisTickRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootAnimationRight = true;

		if (CheckValueChangedAndSetBool(bShotThisTickLeft, RedBlueWeaponComp.WeaponAnimData.bShotThisTickLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootAnimationLeft = true;

		if (CheckValueChangedAndSetBool(bShotGrenadeThisTickRight, RedBlueWeaponComp.WeaponAnimData.bShotGrenadeThisTickRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootGrenadeAnimationRight = true;

		if (CheckValueChangedAndSetBool(bShotGrenadeThisTickLeft, RedBlueWeaponComp.WeaponAnimData.bShotGrenadeThisTickLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootGrenadeAnimationLeft = true;

		bDetonatingRightGrenade = RedBlueWeaponComp.WeaponAnimData.bDetonatingRightGrenade;
		bDetonatingLeftGrenade = RedBlueWeaponComp.WeaponAnimData.bDetonatingLeftGrenade;

		bOverheatedThisTick = CheckValueChangedAndSetBool(bIsOverheated, RedBlueWeaponComp.WeaponAnimData.bIsOverheated, EHazeCheckBooleanChangedDirection::FalseToTrue);

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

		//PrintToScreen("X; " + AimSpaceVariable.X + " Y; " + AimSpaceVariable.Y);
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

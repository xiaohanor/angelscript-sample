UCLASS(Abstract)
class UFeatureAnimInstanceSlowMoFire : UHazeFeatureSubAnimInstance

{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSlowMoFire Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSlowMoFireAnimData AnimData;

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
	UHazeBoneFilterAsset DefaultArmBoneFilter;

	UPROPERTY(BlueprintReadOnly, Category = "BoneFilters")
	UHazeBoneFilterAsset SpineBoneFilter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingDetonateGrenadeAnimationLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingDetonateGrenadeAnimationRight;

	UIslandRedBlueWeaponUserComponent RedBlueWeaponComp;
	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{

		if (HazeOwningActor == nullptr)
			return;
		RedBlueWeaponComp = UIslandRedBlueWeaponUserComponent::Get(HazeOwningActor);
	}

	UPROPERTY()
	bool bUsingRightAimspace;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAming;

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

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSlowMoFire NewFeature = GetFeatureAsClass(ULocomotionFeatureSlowMoFire);
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

		if (CheckValueChangedAndSetBool(bShotThisTickRight, RedBlueWeaponComp.WeaponAnimData.bShotThisTickRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootAnimationRight = true;

		if (CheckValueChangedAndSetBool(bShotThisTickLeft, RedBlueWeaponComp.WeaponAnimData.bShotThisTickLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootAnimationLeft = true;

		if (CheckValueChangedAndSetBool(bShotGrenadeThisTickRight, RedBlueWeaponComp.WeaponAnimData.bShotGrenadeThisTickRight, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootGrenadeAnimationRight = true;

		if (CheckValueChangedAndSetBool(bShotGrenadeThisTickLeft, RedBlueWeaponComp.WeaponAnimData.bShotGrenadeThisTickLeft, EHazeCheckBooleanChangedDirection::FalseToTrue))
			bIsPlayingShootGrenadeAnimationLeft = true;

		bIsAming = true;//RedBlueWeaponComp.WeaponAnimData.IsAimingThisFrame();

		FTransform ActorAimCalcTransform = Player.ActorTransform;
		CalculateAimValues3D(ActorAimCalcTransform);

		if (CheckValueChangedAndSetBool(bDetonatingRightGrenade, RedBlueWeaponComp.WeaponAnimData.bDetonatingRightGrenade, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			bIsPlayingDetonateGrenadeAnimationLeft = true;
			if (AimSpaceVariable.X > 0)
				bIsPlayingDetonateGrenadeAnimationLeft = true;
			else
				bIsPlayingDetonateGrenadeAnimationRight = true;
		}

		if (CheckValueChangedAndSetBool(bDetonatingLeftGrenade, RedBlueWeaponComp.WeaponAnimData.bDetonatingLeftGrenade, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			if (AimSpaceVariable.X < 0)
				bIsPlayingDetonateGrenadeAnimationRight = true;
			else
				bIsPlayingDetonateGrenadeAnimationLeft = true;
		}

		PrintToScreenScaled("AimSpaceVariable: " + AimSpaceVariable, 0.f, Scale = 3.f);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"AirMovement")
			return false;

		return true;
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

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	UFUNCTION()
	void AnimNotify_StopDetonateRight()
	{
		bIsPlayingDetonateGrenadeAnimationRight = false;
	}

	UFUNCTION()
	void AnimNotify_StopDetonateLeft()
	{
		bIsPlayingDetonateGrenadeAnimationLeft = false;
	}
}

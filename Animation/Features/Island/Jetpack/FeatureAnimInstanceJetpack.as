UCLASS(Abstract)
class UFeatureAnimInstanceJetpack : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureJetpack Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureJetpackAnimData AnimData;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysAnimProfile;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashedThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRefill;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInPhaseWallSpline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BoostDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LocalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalDot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveShakeAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D FlyingBlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D DashBlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeAcceleratedRotator SpringRotation;

	UHazePhysicalAnimationComponent PhysComp;
	UIslandJetpackComponent JetpackComp;
	UPlayerMovementComponent MoveComp;
	UIslandSidescrollerComponent SidescrollerComp;

	float LastRefillTime;

	bool bAimOverride;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);
		JetpackComp = UIslandJetpackComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureJetpack NewFeature = GetFeatureAsClass(ULocomotionFeatureJetpack);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		PhysComp.ApplyProfileAsset(this, PhysAnimProfile);

		FlyingBlendspaceValues = GetBlendspaceValues(0);
		SpringRotation.SnapTo(GetHipsTargetRotation(FlyingBlendspaceValues) * 1);

		SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		if (JetpackComp.bDashing)
			return 0.15;

		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bDashedThisTick = CheckValueChangedAndSetBool(bDashing, JetpackComp.bDashing, EHazeCheckBooleanChangedDirection::FalseToTrue);

		bInPhaseWallSpline = JetpackComp.InPhasableWallSpline();
		bRefill = GetAnimTrigger(n"Refill");
		if (bRefill)
			LastRefillTime = Time::GameTimeSeconds;
		const bool bIsRefilling = Time::GameTimeSeconds < LastRefillTime + 1;

		LocalVelocity = Player.GetActorLocalVelocity();

		float UpVelocity = Math::Clamp((LocalVelocity.Z / 850), 0, 1);
		VerticalDot = MoveComp.Velocity.GetSafeNormal().DotProduct(MoveComp.WorldUp) * UpVelocity;

		AdditiveShakeAlpha = 1 - VerticalDot;
		BoostDirection = JetpackComp.AnimLastPhaseWallDirection;

		FlyingBlendspaceValues = GetBlendspaceValues();

		if (bDashing || bIsRefilling)
		{
			FVector LocalMoveDir = LocalVelocity.GetSafeNormal();
			DashBlendspaceValues = FVector2D(LocalMoveDir.Y, LocalMoveDir.X);

			float SpeedRatio = LocalVelocity.Size() / 1750;
			if (bIsRefilling)
			{
				float Alpha = 1 - (Time::GameTimeSeconds - LastRefillTime);
				Alpha = Math::Min(Alpha * 1.75, 1);
				SpeedRatio *= 2 * Alpha;
				SpeedRatio = Math::Min(SpeedRatio, 1.3);
			}
			else
			{
				SpeedRatio = Math::Min(SpeedRatio, 1);
			}

			FRotator Target = FRotator(-LocalMoveDir.X * 70,
									   0,
									   LocalMoveDir.Y * 70);

			SpringRotation.SpringTo(Target * SpeedRatio,
									80,
									0.5,
									DeltaTime);
		}
		else
		{
			SpringRotation.SpringTo(GetHipsTargetRotation(FlyingBlendspaceValues) * Math::Clamp((1 - VerticalDot), 0.5, 1.0),
									30,
									0.3,
									DeltaTime);
		}

		if (CheckValueChangedAndSetBool(bAimOverride, OverrideFeatureTag == n"CopsGunAimOverride" || OverrideFeatureTag == n"CopsGunAimOverride2D"))
		{
			if (bAimOverride)
			{
				PhysComp.SetBoneSimulated(n"LeftArm", false, BlendTime = 0.08);
				PhysComp.SetBoneSimulated(n"RightArm", false, BlendTime = 0.08);
			}
			else
			{
				PhysComp.SetBoneSimulated(n"LeftArm", true, BlendTime = 0.2);
				PhysComp.SetBoneSimulated(n"RightArm", true, BlendTime = 0.2);
			}
		}
	}

	FVector2D GetBlendspaceValues(float YawVelocityAlpha = 1) const
	{
		const FVector Input = MoveComp.GetSyncedLocalSpaceMovementInputForAnimationOnly();
		float YawVelocity = MoveComp.GetMovementYawVelocity(false) * YawVelocityAlpha;

		YawVelocity = Math::Clamp(YawVelocity / 600, -1.0, 1.0);

		return FVector2D(Math::Clamp(Input.Y + YawVelocity, -1.0, 1.0),
						 Input.X);
	}

	FRotator GetHipsTargetRotation(const FVector2D& Input) const
	{
		float YawVelocity = MoveComp.GetMovementYawVelocity(false) / -8;
		if (SidescrollerComp != nullptr && SidescrollerComp.IsInSidescrollerMode())
			YawVelocity = 0;

		return FRotator(-Input.Y * 25,
						YawVelocity,
						Input.X * 25);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"AirMovement")
			SetAnimFloatParam(n"AirMovementBlendTime", 0.6);

		PhysComp.ClearProfileAsset(this, 1);
	}
}

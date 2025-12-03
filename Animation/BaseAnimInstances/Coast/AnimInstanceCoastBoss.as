enum ECoastBossPistonType
{
	UpperLeft,
	UpperRight,
	MiddleLeft,
	MiddleRight,
	LowerLeft,
	LowerRight
}

class UAnimInstanceCoastBoss : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform LeftTurretTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform RightTurretTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform LeftUpperBarrelTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform RightUpperBarrelTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform LeftLowerBarrelTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform RightLowerBarrelTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Alpha = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector PistonOffsetUpperLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector PistonOffsetUpperRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector PistonOffsetMiddleRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector PistonOffsetMiddleLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector PistonOffsetLowerRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector PistonOffsetLowerLeft;

	FHazeAcceleratedVector AccPistonOffsetUpperLeft;
	FHazeAcceleratedVector AccPistonOffsetUpperRight;
	FHazeAcceleratedVector AccPistonOffsetMiddleRight;
	FHazeAcceleratedVector AccPistonOffsetMiddleLeft;
	FHazeAcceleratedVector AccPistonOffsetLowerRight;
	FHazeAcceleratedVector AccPistonOffsetLowerLeft;

	FHazeAcceleratedRotator AccMeshRotation;
	bool bAccMeshRotationInit = false;

	ACoastBoss CoastBoss;
	ACoastBossActorReferences CoastBossReferences;
	AWingsuitBoss WingsuitBoss;
	AWingSuitBots WingsuitBots;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)
			return;

		CoastBoss = Cast<ACoastBoss>(HazeOwningActor);
		WingsuitBoss = Cast<AWingsuitBoss>(HazeOwningActor);
		WingsuitBots = Cast<AWingSuitBots>(HazeOwningActor);
		bAccMeshRotationInit = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(HazeOwningActor == nullptr)
			return;

		CoastBossReferences = TListedActors<ACoastBossActorReferences>().Single;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;

		FCoastBossAnimData AnimData = GetAnimData();
		if(!AnimData.bInitialized)
			return;

		Alpha = 1.0;
		TMap<FName, FTransform> BoneTransforms;
		AnimData.GetCurrentBoneTransforms(BoneTransforms);

		if(AnimData.RotationInterpSpeed <= 0.0)
		{
			LeftTurretTransform = BoneTransforms[AnimData.LeftTurretBoneName];
			RightTurretTransform = BoneTransforms[AnimData.RightTurretBoneName];
		}
		else
		{
			LeftTurretTransform.Location = BoneTransforms[AnimData.LeftTurretBoneName].Location;
			RightTurretTransform.Location = BoneTransforms[AnimData.RightTurretBoneName].Location;

			LeftTurretTransform.Scale3D = BoneTransforms[AnimData.LeftTurretBoneName].Scale3D;
			RightTurretTransform.Scale3D = BoneTransforms[AnimData.RightTurretBoneName].Scale3D;

			LeftTurretTransform.SetRotation(Math::RInterpConstantShortestPathTo(LeftTurretTransform.Rotator(), BoneTransforms[AnimData.LeftTurretBoneName].Rotator(), DeltaTime, AnimData.RotationInterpSpeed));
			RightTurretTransform.SetRotation(Math::RInterpConstantShortestPathTo(RightTurretTransform.Rotator(), BoneTransforms[AnimData.RightTurretBoneName].Rotator(), DeltaTime, AnimData.RotationInterpSpeed));
		}

		FRotator LeftRotator = LeftTurretTransform.Rotator();
		FRotator RightRotator = RightTurretTransform.Rotator();

		const float MaxAngle = 20.0;

		float BaseAngle = 0.0;
		if(Math::Abs(LeftRotator.Yaw) > 90)
			BaseAngle = 180.0 * Math::Sign(LeftRotator.Yaw);
		float Yaw = Math::Clamp(LeftRotator.Yaw, BaseAngle - MaxAngle, BaseAngle + MaxAngle);
		LeftTurretTransform.SetRotation(FRotator(LeftRotator.Pitch, Yaw, LeftRotator.Roll));

		BaseAngle = 0.0;
		if(Math::Abs(RightRotator.Yaw) > 90)
			BaseAngle = 180.0 * Math::Sign(RightRotator.Yaw);
		Yaw = Math::Clamp(RightRotator.Yaw, BaseAngle - MaxAngle, BaseAngle + MaxAngle);
		RightTurretTransform.SetRotation(FRotator(RightRotator.Pitch, Yaw, RightRotator.Roll));

		LeftUpperBarrelTransform = BoneTransforms[AnimData.LeftUpBarrelBoneName];
		RightUpperBarrelTransform = BoneTransforms[AnimData.RightUpBarrelBoneName];
		LeftLowerBarrelTransform = BoneTransforms[AnimData.LeftDownBarrelBoneName];
		RightLowerBarrelTransform = BoneTransforms[AnimData.RightDownBarrelBoneName];
		
		// float TestAlpha = 0.0;
		// SetAlphaForCylinder(TestAlpha, ECoastBossPistonType::UpperLeft, 1.0);
		// SetAlphaForCylinder(TestAlpha, ECoastBossPistonType::UpperRight, 1.0);
		// SetAlphaForCylinder(TestAlpha, ECoastBossPistonType::MiddleLeft, 1.0);
		// SetAlphaForCylinder(TestAlpha, ECoastBossPistonType::MiddleRight, 1.0);
		// SetAlphaForCylinder(TestAlpha, ECoastBossPistonType::LowerLeft, 1.0);
		// SetAlphaForCylinder(TestAlpha, ECoastBossPistonType::LowerRight, 1.0);

		if(WingsuitBots != nullptr)
		{
			const float RollThresholdDegrees = 5.0;

			FTransform BossTransform = GetBossTransform();
			FRotator RotationWithoutRoll = FRotator::MakeFromXZ(BossTransform.Rotation.ForwardVector, FVector::UpVector);
			FVector UpVectorWithoutRoll = RotationWithoutRoll.UpVector;
			float AmountOfRoll = UpVectorWithoutRoll.GetAngleDegreesTo(BossTransform.Rotation.UpVector);

			int RollDirection = 0;
			if(AmountOfRoll > RollThresholdDegrees)
				RollDirection = Math::RoundToInt(Math::Sign(RotationWithoutRoll.RightVector.DotProduct(BossTransform.Rotation.UpVector)));

			float LeftAlpha = 0.65;
			float RightAlpha = 0.65;
			if(RollDirection > 0)
			{
				RightAlpha = 0.3;
				LeftAlpha = 1.0;
			}
			else if(RollDirection < 0)
			{
				LeftAlpha = 0.3;
				RightAlpha = 1.0;
			}

			SetAlphaForCylinder(LeftAlpha, ECoastBossPistonType::UpperLeft, DeltaTime);
			SetAlphaForCylinder(RightAlpha, ECoastBossPistonType::UpperRight, DeltaTime);
			SetAlphaForCylinder(LeftAlpha, ECoastBossPistonType::MiddleLeft, DeltaTime);
			SetAlphaForCylinder(RightAlpha, ECoastBossPistonType::MiddleRight, DeltaTime);
			SetAlphaForCylinder(LeftAlpha, ECoastBossPistonType::LowerLeft, DeltaTime);
			SetAlphaForCylinder(RightAlpha, ECoastBossPistonType::LowerRight, DeltaTime);
		}
		else
		{
			const float VerticalSpeedThreshold = 500.0;
			float VerticalSpeed = GetBossVelocity().DotProduct(FVector::UpVector);

			float UpperAlpha = 0.3;
			float MiddleAlpha = 0.3;
			float LowerAlpha = 0.3;
			LowerAlpha = Math::GetMappedRangeValueClamped(FVector2D(-VerticalSpeedThreshold, VerticalSpeedThreshold), FVector2D(0.3, 1.0), VerticalSpeed);
			UpperAlpha = Math::GetMappedRangeValueClamped(FVector2D(-VerticalSpeedThreshold, VerticalSpeedThreshold), FVector2D(1.0, 0.3), VerticalSpeed);
			MiddleAlpha = Math::GetMappedRangeValueClamped(FVector2D(-VerticalSpeedThreshold, VerticalSpeedThreshold), FVector2D(0.1, 0.8), VerticalSpeed);
			if(CoastBoss != nullptr)
			{
				float HorizontalSpeed = 0.0;

				if(CoastBossReferences != nullptr)
					HorizontalSpeed = GetBossVelocity().DotProduct(CoastBossReferences.CoastBossPlane2D.ActorRightVector);

				if(CoastBoss.bDead)
					HorizontalSpeed = 0.0;

				float Stiffness = 50.0;
				float Damping = 0.4;
				float Sign = -1.0;
				if(CoastBoss.GunBossMovementMode == ECoastBossMovementMode::Drillbazz && CoastBoss.ChargeAlpha > 0.3)
					Sign = 1.0;

				if(CoastBoss.GunBossMovementMode == ECoastBossMovementMode::PingPong && HorizontalSpeed > 500.0)
					Sign = 1.0;

				FVector BaseForward = CoastBoss.ActorRightVector * Sign;
				FRotator Target = FRotator::MakeFromXZ(BaseForward.RotateAngleAxis(Math::Clamp(VerticalSpeed, -500.0, 500.0) / 40.0, CoastBoss.ActorForwardVector * Sign), FVector::UpVector);
				if(CoastBoss.GunBossMovementMode == ECoastBossMovementMode::CloudRainSinus && !CoastBoss.bRainRecover)
				{
					Target = FRotator::MakeFromXZ(-CoastBoss.ActorForwardVector.RotateAngleAxis(25.0, -CoastBoss.ActorRightVector), FVector::UpVector);
					if(!CoastBoss.bRainRecover)
						Stiffness = 20.0;
				}
				if(!bAccMeshRotationInit)
				{
					AccMeshRotation.SnapTo(CoastBoss.BossMeshComp.WorldRotation);
					bAccMeshRotationInit = true;
				}

				if(bAccMeshRotationInit)
					CoastBoss.BossMeshComp.WorldRotation = AccMeshRotation.SpringTo(Target, Stiffness, Damping, DeltaTime);
			}

			SetAlphaForCylinder(UpperAlpha, ECoastBossPistonType::UpperLeft, DeltaTime);
			SetAlphaForCylinder(UpperAlpha, ECoastBossPistonType::UpperRight, DeltaTime);
			SetAlphaForCylinder(MiddleAlpha, ECoastBossPistonType::MiddleLeft, DeltaTime);
			SetAlphaForCylinder(MiddleAlpha, ECoastBossPistonType::MiddleRight, DeltaTime);
			SetAlphaForCylinder(LowerAlpha, ECoastBossPistonType::LowerLeft, DeltaTime);
			SetAlphaForCylinder(LowerAlpha, ECoastBossPistonType::LowerRight, DeltaTime);
		}
	}

	FCoastBossAnimData GetAnimData()
	{
		if(CoastBoss != nullptr)
			return CoastBoss.AnimData;

		if(WingsuitBoss != nullptr)
			return WingsuitBoss.AnimData;

		if(WingsuitBots != nullptr)
			return WingsuitBots.AnimData;

		devError("Tried to get anim data from an actor that is not CoastBoss, WingsuitBoss or WingsuitBots");
		return FCoastBossAnimData();
	}

	FVector GetBossVelocity() const
	{
		if(CoastBoss != nullptr)
		{
			FVector PlaneVelocity = FVector::ZeroVector;
			if(CoastBossReferences != nullptr)
				PlaneVelocity = CoastBossReferences.CoastBossPlane2D.GetRawLastFrameTranslationVelocity();

			return CoastBoss.GetRawLastFrameTranslationVelocity() - PlaneVelocity;
		}

		if(WingsuitBoss != nullptr)
			return WingsuitBoss.ActorVelocity;

		if(WingsuitBots != nullptr)
			return WingsuitBots.GetRawLastFrameTranslationVelocity();

		devError("Tried to get velocity from an actor that is not CoastBoss, WingsuitBoss or WingsuitBots");
		return FVector();
	}

	FTransform GetBossTransform()
	{
		if(CoastBoss != nullptr)
			return CoastBoss.ActorTransform;

		if(WingsuitBoss != nullptr)
			return WingsuitBoss.ActorTransform;

		if(WingsuitBots != nullptr)
			return WingsuitBots.ActorTransform;

		devError("Tried to get transform from an actor that is not CoastBoss, WingsuitBoss or WingsuitBots");
		return FTransform();
	}
	
	void SetAlphaForCylinder(float In_Alpha, ECoastBossPistonType PistonType, float DeltaTime)
	{
		float Stiffness = 50.0;
		float Damping = 0.2;

		if(CoastBoss != nullptr)
		{
			Stiffness = 100.0;
			Damping = 0.6;
		}

		switch(PistonType)
		{
			case ECoastBossPistonType::UpperLeft:
				PistonOffsetUpperLeft = AccPistonOffsetUpperLeft.SpringTo(FVector::UpVector * Math::Lerp(-500.0, 0.0, In_Alpha), Stiffness, Damping, DeltaTime);
			break;
			case ECoastBossPistonType::UpperRight:
				PistonOffsetUpperRight = AccPistonOffsetUpperRight.SpringTo(FVector::UpVector * Math::Lerp(-500.0, 0.0, In_Alpha), Stiffness, Damping, DeltaTime);
			break;
			case ECoastBossPistonType::MiddleLeft:
				PistonOffsetMiddleLeft = AccPistonOffsetMiddleLeft.SpringTo(FVector::UpVector * Math::Lerp(-300.0, 0.0, In_Alpha), Stiffness, Damping, DeltaTime);
			break;
			case ECoastBossPistonType::MiddleRight:
				PistonOffsetMiddleRight = AccPistonOffsetMiddleRight.SpringTo(FVector::UpVector * Math::Lerp(-300.0, 0.0, In_Alpha), Stiffness, Damping, DeltaTime);
			break;
			case ECoastBossPistonType::LowerLeft:
				PistonOffsetLowerLeft = AccPistonOffsetLowerLeft.SpringTo(FVector::UpVector * Math::Lerp(-350.0, 0.0, In_Alpha), Stiffness, Damping, DeltaTime);
			break;
			case ECoastBossPistonType::LowerRight:
				PistonOffsetLowerRight = AccPistonOffsetLowerRight.SpringTo(FVector::UpVector * Math::Lerp(-350.0, 0.0, In_Alpha), Stiffness, Damping, DeltaTime);
			break;
		}
	}
}
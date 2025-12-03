UCLASS(Abstract)
class UFeatureAnimInstanceSketchbookBow : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSketchbookBow Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSketchbookBowAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	USketchbookBowPlayerComponent BowComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShoot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AimAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAimFwd;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Charge;

	bool bIsShooting;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSketchbookBow NewFeature = GetFeatureAsClass(ULocomotionFeatureSketchbookBow);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		BowComp = USketchbookBowPlayerComponent::Get(Player);

		if (BowComp.BowMeshComponent != nullptr)
		{
			const FName Socket = BowComp.AnimLocalAimDir.X > 0 ? n"LeftAttach" : n"RightAttach";
			BowComp.BowMeshComponent.AttachToComponent(Player.Mesh, Socket);
		}

		if (BowComp.ArrowAnimMeshComponent != nullptr)
			BowComp.ArrowAnimMeshComponent.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (BowComp == nullptr)
			return;

		bShoot = CheckValueChangedAndSetBool(bIsShooting, BowComp.bIsFiringBow, EHazeCheckBooleanChangedDirection::FalseToTrue);

		if (BowComp.ArrowAnimMeshComponent != nullptr)
		{
			if (BowComp.ArrowAnimMeshComponent.bHiddenInGame)
			{
				if (TopLevelGraphRelevantStateName != n"Shoot")
					BowComp.ArrowAnimMeshComponent.SetHiddenInGame(false);
				else if (TopLevelGraphRelevantAnimTimeRemaining < 0.1)
				{
					BowComp.ArrowAnimMeshComponent.SetHiddenInGame(false);
					SetAnimTrigger(n"RefreshPose");
				}
			}
			else if (bShoot)
				BowComp.ArrowAnimMeshComponent.SetHiddenInGame(true);
		}

		Charge = BowComp.GetChargeFactor();

		AimAngle = Math::RadiansToDegrees(Math::Asin(BowComp.AnimLocalAimDir.Z)) / 90;
		bAimFwd = BowComp.AnimLocalAimDir.X > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantStateName == n"Shoot")
			return TopLevelGraphRelevantAnimTimeRemaining < 0.1;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (BowComp.BowMeshComponent != nullptr)
		{
			BowComp.BowMeshComponent.AttachToComponent(Player.Mesh, n"Backpack");
			BowComp.BowMeshComponent.SetAnimTrigger(n"Exit");
		}
		if (BowComp.ArrowAnimMeshComponent != nullptr)
			BowComp.ArrowAnimMeshComponent.SetHiddenInGame(true);

		SetAnimTrigger(n"RefreshPose");
	}
}

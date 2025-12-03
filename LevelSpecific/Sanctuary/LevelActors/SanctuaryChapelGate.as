class ASanctuaryChapelGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.SpringStrength = 0.0;
	default RotateComp.LocalRotationAxis = FVector::RightVector;
	default RotateComp.bConstrain = true;
	default RotateComp.ConstrainAngleMax = 1.5;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = FVector::ForwardVector * -200.0;
	default ForceComp.bWorldSpace = false;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UDarkPortalTargetComponent TargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftLockPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightLockPivot;

	UPROPERTY(DefaultComponent)
	USanctuaryFauxAlphaComponent LeftAlphaComp;
	default LeftAlphaComp.AlphaFromAxis = EAlphaFromContraints::TranslationZ;

	UPROPERTY(DefaultComponent)
	USanctuaryFauxAlphaComponent RightAlphaComp;
	default RightAlphaComp.AlphaFromAxis = EAlphaFromContraints::TranslationZ;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UPROPERTY(EditAnywhere)
	float LockLength = 300.0;

	bool bIsOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LeftLockPivot.RelativeLocation = FVector::UpVector * (LeftAlphaComp.GetCurrentAlpha() - 1.0) * -LockLength;
		RightLockPivot.RelativeLocation = FVector::UpVector * (RightAlphaComp.GetCurrentAlpha() - 1.0) * -LockLength;

		if (!bIsOpen && Math::IsNearlyZero(LeftAlphaComp.GetCurrentAlpha()) && Math::IsNearlyZero(RightAlphaComp.GetCurrentAlpha()))
		{
			if (RotateComp.CurrentRotation > Math::DegreesToRadians(RotateComp.ConstrainAngleMax - 1.0))
			{
				bIsOpen = true;
				ForceComp.Force *= -2.0;
				RotateComp.ConstrainAngleMax = 90.0;
				TargetComp.Disable(this);
				PrintToScreen("OPEN GATE", 3.0);
			}
		}
	}
};
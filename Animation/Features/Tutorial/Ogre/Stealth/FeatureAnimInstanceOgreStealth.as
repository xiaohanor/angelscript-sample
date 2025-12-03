UCLASS(Abstract)
class UFeatureAnimInstanceOgreStealth : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureOgreStealthAnimData AnimData;

	AVillageStealthOgre Ogre;

	UPROPERTY()
	ULocomotionFeatureOgreStealth Feature;

	UPROPERTY(BlueprintReadOnly)
	EVillageStealthOgreState CurrentOgreState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator ThrowSpineRotation;

	UPROPERTY(BlueprintReadOnly)
	bool bTurnedAround = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		Ogre = Cast<AVillageStealthOgre>(HazeOwningActor);
		AnimData = Feature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Ogre == nullptr)
			return;

		bTurnedAround = Ogre.bTurnedAround;

		if (Ogre.CurrentState == EVillageStealthOgreState::Throwing && (TopLevelGraphRelevantAnimTime < 0.5 || (TopLevelGraphRelevantStateName != n"Throw" && TopLevelGraphRelevantStateName != n"ThrowTurned")))
		{
			FVector AimDirection = (Ogre.AnimTargetLoc - OwningComponent.WorldLocation).GetSafeNormal();
			if (bTurnedAround)
				AimDirection *= -1;

			const float FwdDot = AimDirection.DotProduct(OwningComponent.ForwardVector);
			const float RightDot = AimDirection.DotProduct(OwningComponent.RightVector);
			const float Angle = Math::RadiansToDegrees(Math::Atan2(RightDot, FwdDot));

			ThrowSpineRotation.Yaw = Math::Clamp(Angle, -50.0, 50.0) / 3;
		}

		CurrentOgreState = Ogre.CurrentState;
	}
}

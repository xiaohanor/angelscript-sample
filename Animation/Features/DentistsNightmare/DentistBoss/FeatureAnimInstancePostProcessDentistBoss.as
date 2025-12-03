
UCLASS(Abstract)
class UFeatureAnimInstancePostProcessDentistBoss : UAnimInstance
{
	ADentistBoss DentistActor;
	
	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (GetOwningComponent() == nullptr)
			return;
		DentistActor = Cast<ADentistBoss>(GetOwningComponent().GetOwner());
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	float GetRightArmAlpha() const
	{
		if (DentistActor == nullptr)
			return 0.0;
		return DentistActor.RightArmCablePhysicsAlpha;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	float GetLeftArmAlpha() const
	{
		if (DentistActor == nullptr)
			return 0.0;
		return DentistActor.LeftArmCablePhysicsAlpha;
	}
}
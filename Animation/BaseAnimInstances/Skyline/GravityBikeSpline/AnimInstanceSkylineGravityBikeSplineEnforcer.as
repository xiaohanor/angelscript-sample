UCLASS(Abstract)
class UAnimInstanceSkylineGravityBikeSplineEnforcer : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeSplineEnforcer Enforcer;

	UPROPERTY(Category = "MH")
	FHazePlayBlendSpaceData IdleBlendSpace;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsIdle = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsShooting = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGrabbed = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bThrown = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDropped = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Enforcer = Cast<AGravityBikeSplineEnforcer>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Enforcer == nullptr)
			return;

		bIsIdle = Enforcer.State == EGravityBikeSplineEnforcerState::Idle;
		bIsShooting = Enforcer.bIsShooting;
		bGrabbed = Enforcer.State == EGravityBikeSplineEnforcerState::Grabbed;
		bThrown = Enforcer.State == EGravityBikeSplineEnforcerState::Thrown;
		bDropped = Enforcer.State == EGravityBikeSplineEnforcerState::Dropped;
	}
}
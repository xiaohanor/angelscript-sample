UCLASS(Abstract)
class UIslandRobotArmAnimInstance : UAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	float BaseAlpha;

	UPROPERTY(BlueprintReadOnly)
	float ArmAlpha;

	UPROPERTY(BlueprintReadOnly)
	float HeadArmAlpha;

	UPROPERTY(BlueprintReadOnly)
	float HeadAlpha;

	UPROPERTY(BlueprintReadOnly)
	float JawsAlpha;

	float LastJawsAlpha;

	UPROPERTY(BlueprintReadOnly)
	FIslandRobotArmRotation BaseRotation;

	UPROPERTY(BlueprintReadOnly)
	FIslandRobotArmRotation TargetRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		auto RobotArm = Cast<AIslandRobotArm>(GetOwningComponent().Owner);

		if(RobotArm == nullptr)
			return;

		if(!GetWorld().IsGameWorld() && RobotArm.bShowVisualizer)
		{
			BaseRotation = FIslandRobotArmRotation();
			TargetRotation = FIslandRobotArmRotation();
		}
		else
		{
			BaseRotation = RobotArm.GetCurrentBaseRotation();
			TargetRotation = RobotArm.TargetRotation;
		}

		if(RobotArm.bJawsOpen)
		{
			JawsAlpha = Math::FInterpConstantTo(JawsAlpha, 1, GetDeltaSeconds(), 1);
		}
		else
		{
			JawsAlpha = Math::FInterpConstantTo(JawsAlpha, 0, GetDeltaSeconds(), 12);
		}

		if(!RobotArm.bIsMoving)
			return;

		BaseAlpha = GetAlpha(RobotArm.BaseProgressRange, RobotArm.EaseInOutExponent, RobotArm.MoveAlpha);
		ArmAlpha = GetAlpha(RobotArm.ArmProgressRange, RobotArm.EaseInOutExponent, RobotArm.MoveAlpha);
		HeadArmAlpha = GetAlpha(RobotArm.HeadArmProgressRange, RobotArm.EaseInOutExponent, RobotArm.MoveAlpha);
		HeadAlpha = GetAlpha(RobotArm.HeadProgressRange, RobotArm.EaseInOutExponent, RobotArm.MoveAlpha);

		RobotArm.bHasSnapped = false;
	}

	float GetAlpha(FVector2D AlphaRange, float Exp, float Alpha)
	{
		float RemappedValue = Math::GetMappedRangeValueClamped(AlphaRange, FVector2D(0.0, 1.0), Alpha);
		return Math::EaseInOut(0.0, 1.0, RemappedValue, Exp);
	}
}
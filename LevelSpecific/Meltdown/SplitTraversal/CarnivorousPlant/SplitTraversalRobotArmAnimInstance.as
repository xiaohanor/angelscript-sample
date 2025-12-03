UCLASS(Abstract)
class USplitTraversalRobotArmAnimInstance : UAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	FSplitTraversalRobotArmRotation Rotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		auto RobotArm = Cast<ASplitTraversalCarnivorousPlant>(GetOwningComponent().Owner);

		if(RobotArm == nullptr)
			return;

		Rotation = RobotArm.Rotation;
	}
}
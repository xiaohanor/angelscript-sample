
UCLASS(Abstract)
class UWorld_Island_Rift_Platform_RobotArm_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnOpenJaw(){}

	UFUNCTION(BlueprintEvent)
	void OnCloseJaw(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	float BaseAlpha;

	UPROPERTY(BlueprintReadOnly)
	float ArmAlpha;

	UPROPERTY(BlueprintReadOnly)
	float HeadArmAlpha;

	UPROPERTY(BlueprintReadOnly)
	float HeadAlpha;

	UPROPERTY(BlueprintReadOnly)
	AIslandRobotArm IslandRobotArm;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		IslandRobotArm = Cast<AIslandRobotArm>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		BaseAlpha = GetAlpha(IslandRobotArm.BaseProgressRange, IslandRobotArm.EaseInOutExponent, IslandRobotArm.MoveAlpha);
		ArmAlpha = GetAlpha(IslandRobotArm.ArmProgressRange, IslandRobotArm.EaseInOutExponent, IslandRobotArm.MoveAlpha);
		HeadArmAlpha = GetAlpha(IslandRobotArm.HeadArmProgressRange, IslandRobotArm.EaseInOutExponent, IslandRobotArm.MoveAlpha);
		HeadAlpha = GetAlpha(IslandRobotArm.HeadProgressRange, IslandRobotArm.EaseInOutExponent, IslandRobotArm.MoveAlpha);
	}

	float GetAlpha(FVector2D AlphaRange, float Exp, float Alpha)
	{
		float RemappedValue = Math::GetMappedRangeValueClamped(AlphaRange, FVector2D(0.0, 1.0), Alpha);
		return Math::EaseInOut(0.0, 1.0, RemappedValue, Exp);
	}

}
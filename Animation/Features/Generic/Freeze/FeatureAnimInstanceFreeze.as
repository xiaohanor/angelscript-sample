UCLASS(Abstract)
class UFeatureAnimInstanceFreeze : UHazeFeatureSubAnimInstance
{
	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return 999; // :)
	}
}

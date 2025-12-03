class UCameraImpulseSettings : UHazeComposableSettings
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraImpulse")
	bool bClampTranslation = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraImpulse", meta = (EditCondition = "bClampTranslation"))
	FVector TranslationalClamps = FVector(200.0, 200.0, 200.0);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraImpulse")
	bool bClampRotation = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraImpulse", meta = (EditCondition = "bClampRotation"))
	FRotator RotationalClamps = FRotator(30.0, 30.0, 30.0);

	void ApplyClamps(FVector& InOutTranslation, FRotator& InOutRotation)
	{
		if (bClampTranslation)
		{
			InOutTranslation.X = Math::Clamp(InOutTranslation.X, -TranslationalClamps.X, TranslationalClamps.X);
			InOutTranslation.Y = Math::Clamp(InOutTranslation.Y, -TranslationalClamps.Y, TranslationalClamps.Y);
			InOutTranslation.Z = Math::Clamp(InOutTranslation.Z, -TranslationalClamps.Z, TranslationalClamps.Z);
		}
		if (bClampRotation)
		{
			InOutRotation.Yaw = Math::Clamp(FRotator::NormalizeAxis(InOutRotation.Yaw), -RotationalClamps.Yaw, RotationalClamps.Yaw);
			InOutRotation.Pitch = Math::Clamp(FRotator::NormalizeAxis(InOutRotation.Pitch), -RotationalClamps.Pitch, RotationalClamps.Pitch);
			InOutRotation.Roll = Math::Clamp(FRotator::NormalizeAxis(InOutRotation.Roll), -RotationalClamps.Roll, RotationalClamps.Roll);
		}
	}
}
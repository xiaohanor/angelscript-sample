class UBattlefieldHoverboardGoingBackwardsSnipeSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Time")
	float GraceTime = 1.5;

	UPROPERTY(Category = "Time")
	float WarningTime = 1.75;

	UPROPERTY(Category = "Setup")
	FName BoneToAttachTo = n"Head";

	UPROPERTY(Category = "Angle")
	FRotator OffsetFromPlayer = FRotator(-50.0, 90.0, 0.0);
}
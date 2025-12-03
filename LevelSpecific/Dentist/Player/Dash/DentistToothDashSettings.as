class UDentistToothDashSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Input")
	float DashInputBufferTime = 0.2;

	UPROPERTY(Category = "Dash")
	float DashImpulse = 1600;

	UPROPERTY(Category = "Dash")
	float DashAngle = 35;

	UPROPERTY(Category = "Dash")
	int MaxDashCount = 1;

	UPROPERTY(Category = "Acceleration")
	float DashHorizontalAcceleration = 8000;

	UPROPERTY(Category = "Acceleration")
	float DashMinimumHorizontalVelocity = 750;

	UPROPERTY(Category = "Rotation")
	FRuntimeFloatCurve DashRotationSpeedOverDurationCurve;

	UPROPERTY(Category = "Rotation")
	float DashResetOffsetDuration = 0.1;

	UPROPERTY(Category = "Bounce|Ground")
	bool bBounceOnHitBouncyGround = true;
	
	UPROPERTY(Category = "Bounce|Ground")
	float GroundBounceRestitution = 0.8;

	UPROPERTY(Category = "Land")
	float DashLandDuration = 0.6;

	UPROPERTY(Category = "Roll")
	float DashLandRollDuration = 0.6;

	UPROPERTY(Category = "Roll")
	float DashLandRollStopIfInputAfterAlpha = 0.5;

	UPROPERTY(Category = "Roll")
	FRuntimeFloatCurve DashLandRollAngleAlphaCurve;

	UPROPERTY(Category = "Player Impacts")
	float HorizontalImpulse = 1000;

	UPROPERTY(Category = "Player Impacts")
	float VerticalImpulse = 500;

	UPROPERTY(Category = "Player Impacts")
	FDentistToothApplyRagdollSettings RagdollSettings;

	/**
	 * If false, we basically just do a straightening, but a full backflip is a big rotation
	 */
	UPROPERTY(Category = "Backflip")
	bool bActuallyDoABackflip = true;

	UPROPERTY(Category = "Backflip")
	float BackflipDurationMultiplier = 1;

	UPROPERTY(Category = "Backflip")
	float BackflipExponent = 1.5;
};

namespace Dentist
{
	namespace Tags
	{
		const FName Dash = n"Dash";
		const FName DashLand = n"DashLand";
		const FName BlockedWhileDash = n"BlockedWhileDash";
	}

	namespace Dash
	{
		const bool bApplyRotation = true;
	}
}
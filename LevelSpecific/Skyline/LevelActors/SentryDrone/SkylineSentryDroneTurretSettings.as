class USkylineSentryDroneTurretSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Targeting")
	bool bUseTargetTracking = true;

	UPROPERTY(Category = "Targeting")
	bool bIgnoreLineOfSightTrace = false;

	UPROPERTY(Category = "Targeting")
	float Range = 3000.0;

	UPROPERTY(Category = "Targeting")
	float Angle = 60.0;

	UPROPERTY(Category = "Targeting")
	float RotationSpeed = 6.0;

	UPROPERTY(Category = "Targeting")
	FName DefaultTargetTeamName = n"BasicAITeam";

	UPROPERTY(Category = "Targeting")
	bool bTargetMio = true;

	UPROPERTY(Category = "Targeting")
	bool bTargetZoe = true;

	UPROPERTY(Category = "Fire")
	float FireInterval = 0.05;

	UPROPERTY(Category = "Fire")
	float LaunchSpeed = 10000.0;

	UPROPERTY(Category = "Fire")
	float SpreadAngle = 2.0;

	UPROPERTY(Category = "GravityWhip Sling Settings")
	bool bFireWhenSlinged = true;

	UPROPERTY(Category = "GravityWhip Sling Settings")
	bool bAIHostileWhenGrabbed = true;

	UPROPERTY(Category = "GravityWhip Sling Settings")
	bool bPlayerHostileWhenGrabbed = false;

	UPROPERTY(Category = "GravityWhip Sling Settings")
	bool bUseGrabberAutoAimForTargeting = true;
}
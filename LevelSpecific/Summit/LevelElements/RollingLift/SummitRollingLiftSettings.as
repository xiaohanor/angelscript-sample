
class USummitRollingLiftSettings : UHazeComposableSettings
{
	// How long from the dash finish, can we dash again
	UPROPERTY()
	float DashCooldown = 2;

	UPROPERTY()
	bool bDashWhileGrounded = true;

	UPROPERTY()
	bool bDashWhileAirBourne = true;

	
}

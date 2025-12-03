class UMoonMarketSausageMovementSettings : UHazeComposableSettings
{
	UPROPERTY()
	float ForwardSpeed = 200.0;

	UPROPERTY()
	float WobbleMultiplier = 3.0;

	UPROPERTY(Category = "Jump")
	float JumpImpulse = 600.0;

}
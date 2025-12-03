class UForgePipePlayerLaunchComponent : UActorComponent
{
	bool bCanLaunch;
	FVector LaunchVelocity;
	bool bIsAtStart;


	void SetLaunch(FVector Velocity, bool bAtStart)
	{
		LaunchVelocity = Velocity;
		bCanLaunch = true;
		bIsAtStart = bAtStart;
	}
}
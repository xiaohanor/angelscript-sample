class USkylineSniperProjectileComponent : UBasicAIProjectileComponent
{
	float ExpiredTime = 0.0;

	void Launch(FVector LaunchVelocity) override
	{
		Super::Launch(LaunchVelocity);
		ExpiredTime = 0.0;
	}

	void Launch(FVector LaunchVelocity, FRotator LaunchRotation) override
	{
		Super::Launch(LaunchVelocity, LaunchRotation);
		ExpiredTime = 0.0;
	}

	void Expire() override
	{
		ExpiredTime = Time::GetGameTimeSeconds();
		bIsExpired = true;
	}

	void DelayedExpire()
	{
		bIsPrimed = false;
		bIsLaunched = false;
		Target = nullptr;
		Owner.SetActorTickEnabled(false);
		HazeOwner.AddActorDisable(this);
		if (LaunchedEffectComp != nullptr)
			LaunchedEffectComp.Deactivate();

		// Make this available for respawn
		RespawnComp.UnSpawn();
	}
}
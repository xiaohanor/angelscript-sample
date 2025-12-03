class UHackablePinballMovePaddlesCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	AHackablePinball HackablePinball;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HackablePinball = Cast<AHackablePinball>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HackablePinball.bIsHacked)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (!HackablePinball.bIsHacked)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto Paddle : Pinball::GetPaddles())
		{
			// For some reason, Chaos just breaks on the collision on the paddles
			// So just toggle it on and off, since this seemed to work in GameShow and is much less hacky
			// than the previous wiggle fix lol
			Paddle.AddActorCollisionBlock(this);
			Paddle.RemoveActorCollisionBlock(this);

			Paddle.ApplyPaddleRotation();
		}
	}
}
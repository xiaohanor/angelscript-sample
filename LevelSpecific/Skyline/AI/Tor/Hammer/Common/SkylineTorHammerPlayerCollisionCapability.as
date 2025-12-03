class USkylineTorHammerPlayerCollisionCapability : UHazeCapability
{
	ASkylineTorHammer Hammer;
	USkylineTorHammerPlayerCollisionComponent CollisionComp;
	float Scale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hammer = Cast<ASkylineTorHammer>(Owner);
		Hammer.PlayerCollision.WorldScale3D = FVector(0, 0, 1);
		Hammer.PlayerCollision.CollisionProfileName = CollisionProfile::NoCollision;
		CollisionComp = USkylineTorHammerPlayerCollisionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Hammer.PlayerCollision.CollisionProfileName = CollisionProfile::BlockOnlyPlayerCharacter;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Hammer.PlayerCollision.CollisionProfileName = CollisionProfile::NoCollision;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CollisionComp.bEnabled && Scale < 1)
			Scale += DeltaTime * 2;
		else if(!CollisionComp.bEnabled && Scale > 0)
			Scale -= DeltaTime * 2;
		Scale = Math::Clamp(Scale, 0, 1);
		Hammer.PlayerCollision.WorldScale3D = FVector(Scale, Scale, 1);
	}
}
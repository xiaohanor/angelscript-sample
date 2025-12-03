class UDeathEffect_Falling : UDeathEffect
{
	UPlayerHealthComponent HealthComp;
	UPlayerMovementComponent MoveComp;

	bool bExploded = false;
	bool bDied = false;
	bool bFinishedDying = false;
	bool bRespawned = false;

	float ActiveDuration = 0.0;
	float ExplodedTime = 0.0;

	FVector PreviousPlayerLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		HealthComp = UPlayerHealthComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent)
	void ExplodeDueToTimeout() {}

	UFUNCTION(BlueprintEvent)
	void ExplodeDueToObstacle() {}

	UFUNCTION(BlueprintOverride)
	void Died()
	{
		bDied = true;
		Player.CameraOffsetComponent.SnapToLocation(this, Player.CameraOffsetComponent.WorldLocation);
		PreviousPlayerLocation = Player.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void FinishedDying()
	{
		Super::FinishedDying();
		bFinishedDying = true;

		if (bExploded)
		{
			Player.UnblockCapabilities(CapabilityTags::Visibility, this);
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void RespawnTriggered()
	{
		Super::RespawnTriggered();
		Player.CameraOffsetComponent.ClearOffset(this);
		bRespawned = true;
	}

	void OnExplodeTriggered()
	{
		bExploded = true;
		ExplodedTime = ActiveDuration;

		Player.BlockCapabilities(CapabilityTags::Visibility, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bDied)
			return;
		if (bFinishedDying)
			return;
		if (bRespawned)
			return;

		ActiveDuration += DeltaTime;

		if (!bExploded)
		{
			if (ActiveDuration >= DeathEffectDuration - 0.3)
			{
				OnExplodeTriggered();
				ExplodeDueToTimeout();
			}
			else
			{
				if (MoveComp.HasGroundContact())
				{
					OnExplodeTriggered();
					ExplodeDueToObstacle();
				}
			}
		}
		else if (ActiveDuration >= ExplodedTime + 0.3)
		{
			HealthComp.TriggerDeathEffectCompleted();
		}

		// At the beginning, the camera should still move a bit with the actor, later it should stop
		FVector PlayerLocation = Player.ActorLocation;
		float MovedDistance = (PlayerLocation - PreviousPlayerLocation).Size();
		float CameraMoveDistance = MovedDistance * Math::Lerp(1.0, 0.0, Math::Saturate(ActiveDuration / 0.5));

		FVector MoveVector = (PlayerLocation - PreviousPlayerLocation).GetSafeNormal() * CameraMoveDistance;
		Player.CameraOffsetComponent.SnapToLocation(this, Player.CameraOffsetComponent.WorldLocation + MoveVector);

		PreviousPlayerLocation = PlayerLocation;
	}
}
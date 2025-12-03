class UPigSiloTumbleCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"PigSiloTumble");
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerPigSiloComponent PigSiloComponent;
	UPigSiloMovementSettings MovementSettings;

	bool bPlayerCollided = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigSiloComponent = UPlayerPigSiloComponent::Get(Player);
		MovementSettings = UPigSiloMovementSettings::GetSettings(Player);

		PigSiloComponent.OnObstacleCollision.AddUFunction(this, n"OnObstacleCollision");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PigSiloComponent.IsSiloMovementActive())
			return false;

		if (!bPlayerCollided)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= MovementSettings.TumbleDecelerationDuration + MovementSettings.TumbleSpeedRecoveryTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bPlayerCollided = false;
		PigSiloComponent.bTumbling = true;

		Player.PlayForceFeedback(PigSiloComponent.ObstacleCollisionFF, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PigSiloComponent.bTumbling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (ActiveDuration < MovementSettings.TumbleDecelerationDuration)
		// {
		// 	float InterpSpeed = (MovementSettings.MoveSpeedMax - MovementSettings.MoveSpeedMin) / MovementSettings.TumbleDecelerationDuration;
		// 	MovementSettings.CurrentMoveSpeed = Math::FInterpConstantTo(MovementSettings.CurrentMoveSpeed, MovementSettings.MoveSpeedMin, DeltaTime, InterpSpeed);
		// }
		// else
		// {
		// 	float InterpSpeed = (MovementSettings.MoveSpeedMax - MovementSettings.MoveSpeedMin) / MovementSettings.TumbleSpeedRecoveryTime;
		// 	MovementSettings.CurrentMoveSpeed = Math::FInterpConstantTo(MovementSettings.CurrentMoveSpeed, MovementSettings.MoveSpeedMax, DeltaTime, InterpSpeed);
		// }

		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"SiloCrash", this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnObstacleCollision(const APigSiloObstacle Obstacle)
	{
		bPlayerCollided = true;
	}
}
struct FCentipedeWaterOutletBiteCapabilityActivationParams
{
	ACentipedeWaterOutlet WaterOutlet = nullptr;
}

class UCentipedeWaterOutletBiteCapability : UHazePlayerCapability
{
	// UCentipedeBiteComponent has networked bite
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::ActionMovement;

	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent CentipedeBiteComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	ACentipedeWaterOutlet WaterOutlet;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		CentipedeBiteComponent = UCentipedeBiteComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeWaterOutletBiteCapabilityActivationParams& ActivationParams) const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		UCentipedeBiteResponseComponent BittenComponent = CentipedeBiteComponent.GetBittenComponent();
		if (BittenComponent == nullptr)
			return false;

		ACentipedeWaterOutlet CentipedeWaterOutlet = Cast<ACentipedeWaterOutlet>(BittenComponent.Owner);
		if (CentipedeWaterOutlet == nullptr)
			return false;

		ActivationParams.WaterOutlet = CentipedeWaterOutlet;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (!CentipedeBiteComponent.IsBitingSomething())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCentipedeWaterOutletBiteCapabilityActivationParams ActivationParams)
	{
		WaterOutlet = ActivationParams.WaterOutlet;
		FCentipedeWaterOutletEventParams EventParams;
		EventParams.BitingPlayer = Player;
		EventParams.SprayingPlayer = Player.OtherPlayer;
		UCentipedeWaterOutletEventHandler::Trigger_OnAttachWaterOutlet(WaterOutlet, EventParams);
		UCentipedeEventHandler::Trigger_OnAttachWaterOutlet(Player, EventParams);
		UCentipedeEventHandler::Trigger_OnAttachWaterOutlet(Player.OtherPlayer, EventParams);
		UCentipedeEventHandler::Trigger_OnAttachWaterOutlet(CentipedeComponent.Centipede, EventParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.SetActorVelocity(WaterOutlet.GetLetGoPushForce());
		FCentipedeWaterOutletEventParams EventParams;
		EventParams.BitingPlayer = Player;
		EventParams.SprayingPlayer = Player.OtherPlayer;
		UCentipedeWaterOutletEventHandler::Trigger_OnDetachWaterOutlet(WaterOutlet, EventParams);
		UCentipedeEventHandler::Trigger_OnDetachWaterOutlet(Player, EventParams);
		UCentipedeEventHandler::Trigger_OnDetachWaterOutlet(Player.OtherPlayer, EventParams);
		UCentipedeEventHandler::Trigger_OnDetachWaterOutlet(CentipedeComponent.Centipede, EventParams);
		WaterOutlet = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				// Get target location
				FTransform TargetTransform = WaterOutlet.TargetTransformComp.WorldTransform;

				// Move to target
				FVector NextLocation = Math::VInterpTo(Player.ActorLocation, TargetTransform.Location, DeltaTime, 15);
				FVector MoveDelta = (NextLocation - Player.ActorLocation).ConstrainToPlane(Player.MovementWorldUp);
				MoveData.AddDelta(MoveDelta);

				MoveData.AddGravityAcceleration();

				// Rotate towards outlet
				MoveData.InterpRotationTo(TargetTransform.Rotation, 10, false);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}
	}
}
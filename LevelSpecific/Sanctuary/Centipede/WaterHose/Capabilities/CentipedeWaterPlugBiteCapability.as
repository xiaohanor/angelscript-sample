struct FCentipedeWaterPlugBiteCapabilityActivationParams
{
	ACentipedeWaterPlug WaterPlug = nullptr;
}

class UCentipedeWaterPlugBiteCapability : UHazePlayerCapability
{
	// UCentipedeBiteComponent has networked bite
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;

	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent CentipedeBiteComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	ACentipedeWaterPlug WaterPlug;
	bool bInterpolated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		CentipedeBiteComponent = UCentipedeBiteComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeWaterPlugBiteCapabilityActivationParams& ActivationParams) const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		UCentipedeBiteResponseComponent BittenComponent = CentipedeBiteComponent.GetBittenComponent();
		if (BittenComponent == nullptr)
			return false;

		ACentipedeWaterPlug CentipedeWaterPlug = Cast<ACentipedeWaterPlug>(BittenComponent.Owner);
		if (CentipedeWaterPlug == nullptr)
			return false;

		if (CentipedeWaterPlug.bIsDragged)
			return false;

		if (CentipedeWaterPlug.bIsUnplugged)
			return false;

		ActivationParams.WaterPlug = CentipedeWaterPlug;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (!CentipedeBiteComponent.IsBitingSomething())
			return true;

		if (bInterpolated)
			return true;

		if (WaterPlug == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCentipedeWaterPlugBiteCapabilityActivationParams ActivationParams)
	{
		WaterPlug = ActivationParams.WaterPlug;
		bInterpolated = false;
		Player.BlockCapabilities(CentipedeTags::CentipedeMovement, this);
		WaterPlug.SetActorControlSide(Player);
		WaterPlug.BitingPlayer = Player;
		UCentipedeWaterPlugEventHandler::Trigger_OnPlayerAttached(WaterPlug, WaterPlug.GetEventData());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (WaterPlug != nullptr)
		{
			if (CentipedeBiteComponent.IsBitingSomething())
				WaterPlug.bIsDragged = true;
			UCentipedeWaterPlugEventHandler::Trigger_OnPlayerDetach(WaterPlug, WaterPlug.GetEventData());
		}
		WaterPlug = nullptr;
		Player.UnblockCapabilities(CentipedeTags::CentipedeMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				if (SanctuaryCentipedeDevToggles::Draw::WaterThings.IsEnabled())
					Debug::DrawDebugString(Player.ActorLocation, "\n PlugBite Interp", ColorDebug::Magenta);

				// Get target location
				FTransform TargetTransform = WaterPlug.TargetTransformComp.WorldTransform;

				// Move to target
				FVector NextLocation = Math::VInterpTo(Player.ActorLocation, TargetTransform.Location, DeltaTime, 15);
				FVector MoveDelta = (NextLocation - Player.ActorLocation).ConstrainToPlane(Player.MovementWorldUp);
				MoveData.AddDelta(MoveDelta);

				// MoveData.AddGravityAcceleration();

				// Rotate towards Plug
				MoveData.InterpRotationTo(TargetTransform.Rotation, 180, false);

				if (ActiveDuration > 0.2)
				{
					MoveData.SetRotation(TargetTransform.Rotation);
					FVector ToTargetLocation = (TargetTransform.Location - Player.ActorLocation).ConstrainToPlane(Player.MovementWorldUp);
					MoveData.AddDelta(ToTargetLocation);
					bInterpolated = true;
				}
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}
	}
}
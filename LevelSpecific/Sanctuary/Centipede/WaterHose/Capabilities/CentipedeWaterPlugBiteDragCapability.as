struct FCentipedeWaterPlugBiteDragCapabilityActivationParams
{
	ACentipedeWaterOutlet Outlet = nullptr;
	ACentipedeWaterPlug WaterPlug = nullptr;
}

class UCentipedeWaterPlugBiteDragCapability : UHazePlayerCapability
{
	FCentipedeWaterPlugBiteDragCapabilityActivationParams Params;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent CentipedeBiteComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;
	UCentipedeMovementSettings Settings;

	FVector OriginalLocation;

	FHazeAcceleratedFloat AccSpeed;
	FHazeAcceleratedVector AccImpulse;

	float DistanceToDrag = 50.0;

	FVector LastLocation;
	bool bWasPulling = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		CentipedeBiteComponent = UCentipedeBiteComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSteppingMovementData();
		Settings = UCentipedeMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeWaterPlugBiteDragCapabilityActivationParams& ActivationParams) const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		UCentipedeBiteResponseComponent BittenComponent = CentipedeBiteComponent.GetBittenComponent();
		if (BittenComponent == nullptr)
			return false;

		ACentipedeWaterPlug CentipedeWaterPlug = Cast<ACentipedeWaterPlug>(BittenComponent.Owner);
		if (CentipedeWaterPlug == nullptr)
			return false;

		if (!CentipedeWaterPlug.bIsDragged)
			return false;

		ACentipedeWaterOutlet CentipedeWaterOutlet = Cast<ACentipedeWaterOutlet>(CentipedeWaterPlug.AttachParentActor);
		if (CentipedeWaterOutlet == nullptr)
			return false;

		ActivationParams.WaterPlug = CentipedeWaterPlug;
		ActivationParams.Outlet = CentipedeWaterOutlet;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (Params.WaterPlug.bIsUnplugged && AccImpulse.Velocity.Size() < 500.0)
			return true;

		if (!Params.WaterPlug.bIsUnplugged && !CentipedeBiteComponent.IsBitingSomething())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCentipedeWaterPlugBiteDragCapabilityActivationParams ActivationParams)
	{
		Params = ActivationParams;
		OriginalLocation = Player.ActorLocation;
		AccSpeed.SnapTo(0.0);
		AccImpulse.SnapTo(FVector());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Params.WaterPlug.bIsDragged = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				HandleControlMovement(DeltaTime);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}
			
			MovementComponent.ApplyMove(MoveData);
			HandleEventsData();
		}
	}

	private void HandleEventsData()
	{
		if (LastLocation.Size() > KINDA_SMALL_NUMBER)
		{
			bool bIsPulling = LastLocation.Distance(Player.ActorLocation) > 0.5;
			if (bWasPulling != bIsPulling)
			{
				if (bIsPulling)
					UCentipedeWaterPlugEventHandler::Trigger_OnStartPulling(Params.WaterPlug, Params.WaterPlug.GetEventData());
				else
					UCentipedeWaterPlugEventHandler::Trigger_OnStopPulling(Params.WaterPlug, Params.WaterPlug.GetEventData());
			}
			bWasPulling = bIsPulling;
			LastLocation = Player.ActorLocation;
		}
		else
			LastLocation = Player.ActorLocation;
	}

	private void HandleControlMovement(float DeltaTime)
	{
		FVector NewLocation = Player.ActorLocation;
		FVector Diff = NewLocation - OriginalLocation;
		float Alpha = Math::Clamp(Diff.Size() / DistanceToDrag, 0.0, 1.0);
		const FVector MoveInput = CentipedeComponent.GetMovementInput();
		FVector FromPlugVelocity = MoveInput.ConstrainToCone(Params.Outlet.ActorForwardVector, Math::DegreesToRadians(10.0) * 0.5) * 100.0 * DeltaTime;
		if (Params.Outlet.ActorForwardVector.DotProduct(MoveInput) < KINDA_SMALL_NUMBER)
			FromPlugVelocity = FVector();

		if (!Params.WaterPlug.bIsUnplugged && FromPlugVelocity.Size() > KINDA_SMALL_NUMBER)
		{
			Player.SetFrameForceFeedback(1.0, 1.0, 1.0, 1.0, 0.3); // Math::EaseIn(0.0, 0.2, Alpha, 3.0)
			if (Alpha >= 1.0 - KINDA_SMALL_NUMBER)
			{
				if (Params.WaterPlug.UnpluggedForceFeedback != nullptr)
					Player.PlayForceFeedback(Params.WaterPlug.UnpluggedForceFeedback, false, false, this);
				
				AccImpulse.SnapTo(Diff.GetSafeNormal() * 2700.0);
				Params.WaterPlug.Unplug();
			}
		}
		AccImpulse.AccelerateTo(FVector(), 1.2, DeltaTime);

		if (AccImpulse.Value.Size() > 10.0)
			FromPlugVelocity = AccImpulse.Value * DeltaTime;

		{
			MoveData.AddDelta(FromPlugVelocity);
			MoveData.SetRotation(FRotator::MakeFromXZ(-Params.Outlet.ActorForwardVector, MovementComponent.GroundContact.Normal));

			MoveData.AddGravityAcceleration();
		}

		if (!Params.WaterPlug.bIsUnplugged && FromPlugVelocity.Size() > KINDA_SMALL_NUMBER)
		{
			FVector NewPlugLocation = Params.WaterPlug.ActorLocation + FromPlugVelocity;
			Params.WaterPlug.SetActorLocation(NewPlugLocation);
		}

		if (SanctuaryCentipedeDevToggles::Draw::WaterThings.IsEnabled())
		{
			Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + MoveInput * 500.0, ColorDebug::Cyan, 5.0, 0.0, true);
			Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + FromPlugVelocity.GetSafeNormal() * 500.0, ColorDebug::Magenta, 5.0, 0.0, true);
			Debug::DrawDebugString(Player.ActorLocation, "\nPlugBite Drag", ColorDebug::Lavender);
		}
	}
}
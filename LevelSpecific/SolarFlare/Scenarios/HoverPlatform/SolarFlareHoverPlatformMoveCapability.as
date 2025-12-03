class USolarFlareHoverPlatformMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SolarFlareHoverPlatformMoveCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASolarFlareHoverPlatform Platform;
	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	float ForwardSpeed = 800.0;

	FHazeAcceleratedVector AccelVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ASolarFlareHoverPlatform>(Owner);
		MoveComp = Platform.MoveComp;
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelVector.SnapTo(Platform.TargetVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			if (Platform.bIsActive)
			{
				FHazeTraceDebugSettings DebugSettings;
				DebugSettings.Thickness = 20.0;
				DebugSettings.TraceColor = FLinearColor::Red;

				FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				TraceSettings.IgnoreActor(Platform);
				TraceSettings.IgnoreActor(Game::Mio);
				TraceSettings.IgnoreActor(Game::Zoe);
				TraceSettings.UseBoxShape(FVector(600.0, 250.0, 120.0));
				TraceSettings.DebugDraw(DebugSettings);

				FVector Start = Platform.ActorLocation + Platform.ActorForwardVector * 1000.0;
				Start += FVector::UpVector * -70.0;
				FHitResult Hit = TraceSettings.QueryTraceSingle(Start, Start + Platform.ActorForwardVector);

				if (!Hit.bBlockingHit)
				{
					Platform.TargetVelocity += Platform.ActorForwardVector * ForwardSpeed;
				}
				// else
				// {
				// 	PrintToScreen("BLOCKING: " + Hit.Actor);
				// }
			}

			AccelVector.AccelerateTo(Platform.TargetVelocity, 0.75, DeltaTime);
			Movement.AddVelocity(AccelVector.Value);
		}

		Platform.CheckThrusterActivations();
		MoveComp.ApplyMove(Movement);

		Platform.TargetVelocity = FVector(0.0);
	}
}
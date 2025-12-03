namespace SwarmDrone
{
	FVector GetSwarmBotRelativeLocationOnDroneMesh(int Id, float DroneRadius)
	{
		float DistributionCount;
		float Radius;
		float LayerId;
		float Factor;

		bool bRetracedInnerLayer = Id >= SwarmDrone::TotalBotCount - SwarmDrone::RetractedInnerLayerBotCount;
		if (bRetracedInnerLayer)
		{
			DistributionCount = SwarmDrone::RetractedInnerLayerBotCount;
			Radius = DroneRadius * 0.73;
			LayerId = Id - SwarmDrone::TotalBotCount + SwarmDrone::RetractedInnerLayerBotCount;
			Factor = 5.1;
		}
		else
		{
			DistributionCount = SwarmDrone::TotalBotCount - SwarmDrone::RetractedInnerLayerBotCount;
			Radius = DroneRadius;
			LayerId = Id;
			Factor = 5.0;
		}

		// Fibonacci lattice
		float P = PI * (1.0 - Math::Sqrt(Factor));
		float T = P * LayerId;

		// Map from -1 to 1
		float Y = 1.0 - (LayerId / (DistributionCount - 1.0)) * 2.0;
		float R = Math::Sqrt(1.0 - Y * Y);
		float X = Math::Cos(T) * R;
		float Z = Math::Sin(T) * R;

		return FVector(X, Y, Z) * Radius;
	}

	void Blah(FTransform SwarmDroneWorldTransform, FTransform BotWorldTransform, FTransform BotInitialTransform, float DeltaTime)
	{
		// FQuat RotationOffset = FQuat::Identity;
		// FVector DroneCoreToBot = (BotOwner.ActorLocation - BotOwner.PlayerSwarmDroneComponent.DroneMesh.WorldLocation).GetSafeNormal();

		// if (!DroneVelocity.IsNearlyZero(20.0))
		// {
		// 	float FaceDot = DroneVelocity.GetSafeNormal().DotProduct(DroneCoreToBot);
		// 	if (FaceDot < 0)
		// 	{
		// 		float AlingmentMultiplier = Math::Min(DroneCoreToBot.DotProduct(WorldUp), 0.0);
		// 		if (AlingmentMultiplier > -0.8 && AlingmentMultiplier < -0.6)
		// 		{
		// 			// AlingmentMultiplier *= BotOwner.PlayerSwarmDroneComponent.CurrentSpeedFraction;

		// 			float Angle = -20 * Math::Abs(AlingmentMultiplier * 4);
		// 			FVector RotationAxis = DroneVelocity.GetSafeNormal();
		// 			RotationAxis = BotOwner.PlayerSwarmDroneComponent.Player.ActorVelocity.ConstrainToPlane(WorldUp).GetSafeNormal();

		// 			RotationAxis = RotationAxis.CrossProduct(WorldUp);
		// 			RotationAxis = BotOwner.ActorTransform.InverseTransformVector(RotationAxis);
		// 			// Debug::DrawDebugDirectionArrow(BotOwner.ActorLocation, BotOwner.ActorTransform.TransformVector(RotationAxis), 100, 1, FLinearColor::Green, 1);

		// 			RotationOffset = FQuat(RotationAxis, Math::DegreesToRadians(Angle));
		// 		}
		// 	}
		// }

		// // Rotate bot to give slate-acceleration appearance
		// FQuat Rotation = BotOwner.InitialTransformOnMesh.Rotation * RotationOffset;
		// float AccelerationTime = Math::Min(1.0, 90.0 / Math::Max(DroneVelocity.Size(), DeltaTime));
		// AcceleratedBotRotation.AccelerateTo(Rotation, AccelerationTime, DeltaTime);
		// BotOwner.RootComponent.SetRelativeRotation(AcceleratedBotRotation.Value);

		// Do some fun translations here
		// FVector DroneCoreToBot = (BotInitialTransform.Location - BotOwner.PlayerSwarmDroneComponent.DroneMesh.WorldLocation).GetSafeNormal();
		// float Alignment = DroneCoreToBot.DotProduct(WorldUp);
		// if (Alignment < 0.0)
		// {
			// Squish the bottom bots up
			// FVector Offset = BotInitialTransform.TransformVectorNoScale(DroneCoreToBot) * 15.0 * Math::Abs(Alignment);
			// BotOwner.RootComponent.SetRelativeLocation(BotOwner.InitialTransformOnMesh.Location + Offset);
		// }
		// else
		{
			// Extend upper bots up
			// Height offset
			// FVector Offset = BotOwner.RootComponent.RelativeTransform.TransformVectorNoScale(DroneCoreToBot) * Alignment * DroneVelocity.Size() * DeltaTime * 0.5;
			// BotOwner.RootComponent.SetRelativeLocation(BotOwner.InitialTransformOnMesh.Location + Offset);
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	void ApplySwarmTransitionBlock(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Drone::GetSwarmDronePlayer());
		if (SwarmDroneComponent != nullptr)
			SwarmDroneComponent.ApplySwarmTransitionBlock(Instigator, Priority);
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	void ClearSwarmTransitionBlock(FInstigator Instigator)
	{
		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Drone::GetSwarmDronePlayer());
		if (SwarmDroneComponent != nullptr)
			SwarmDroneComponent.ClearSwarmTransitionBlock(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	void StartHijack(ASwarmDroneHijackable Hijackable)
	{
		auto HijackComp = UPlayerSwarmDroneHijackComponent::Get(Drone::GetSwarmDronePlayer());
		HijackComp.StartHijack(Hijackable);
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	void ApplySwarmHijackCancelBlock(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		auto HijackComp = UPlayerSwarmDroneHijackComponent::Get(Drone::GetSwarmDronePlayer());
		HijackComp.SwarmHijackCancelBlocks.Apply(true, Instigator, Priority);
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	void ClearSwarmHijackCancelBlock(FInstigator Instigator)
	{
		auto HijackComp = UPlayerSwarmDroneHijackComponent::Get(Drone::GetSwarmDronePlayer());
		HijackComp.SwarmHijackCancelBlocks.Clear(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	void ForceHijack(USwarmDroneHijackTargetableComponent HijackableTargetComponent)
	{
		auto HijackComp = UPlayerSwarmDroneHijackComponent::Get(Drone::GetSwarmDronePlayer());
		HijackComp.ForceHijack(HijackableTargetComponent);
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	bool IsSwarmHijackCancelBlocked()
	{
		auto HijackComp = UPlayerSwarmDroneHijackComponent::Get(Drone::GetSwarmDronePlayer());
		return HijackComp.IsSwarmHijackCancelBlocked();
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	bool IsHijackActive()
	{
		auto HijackComp = UPlayerSwarmDroneHijackComponent::Get(Drone::GetSwarmDronePlayer());
		return HijackComp.IsHijackActive();
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	bool IsHijackDiving()
	{
		auto HijackComp = UPlayerSwarmDroneHijackComponent::Get(Drone::GetSwarmDronePlayer());
		return HijackComp.IsHijackDiving();
	}

	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	bool IsExitingHijack()
	{
		auto HijackComp = UPlayerSwarmDroneHijackComponent::Get(Drone::GetSwarmDronePlayer());
		return HijackComp.IsExitingHijack();
	}

	// Deactivates swarm mode if active
	UFUNCTION(BlueprintCallable, Category = "Prison | Swarm Drone")
	void ConsumeSwarmMode()
	{
		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Drone::GetSwarmDronePlayer());
		if (SwarmDroneComponent != nullptr)
			SwarmDroneComponent.ConsumeSwarmMode();
	}
}
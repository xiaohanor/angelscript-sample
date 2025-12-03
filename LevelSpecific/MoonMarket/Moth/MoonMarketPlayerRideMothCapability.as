class UMoonMarketPlayerRideMothCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 1000;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UMoonMarketPlayerRideMothComponent RiderComp;

	AMoonMarketMoth Moth;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		RiderComp = UMoonMarketPlayerRideMothComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(RiderComp.Moth == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
		bool ShouldDeactivate() const
	{
		if(RiderComp.Moth == nullptr)
			return true;

		// if(MoveComp.HasGroundContact())
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Moth = RiderComp.Moth;

		Owner.AttachToComponent(RiderComp.Moth.MeshComp);
		Owner.SetActorRelativeLocation(FVector::DownVector * 247 + FVector::BackwardVector * 20);
		Owner.SetActorRelativeRotation(FRotator::ZeroRotator);

		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilities(CapabilityTags::Death, this);

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		Moth.MeshComp.PlaySlotAnimation(Moth.AnimHover);
		Player.PlaySlotAnimation(RiderComp.Moth.Settings.SlotAnimParams);

		Player.ApplyCameraSettings(RiderComp.Moth.Settings.CamSettings, 2.0, this, EHazeCameraPriority::Medium);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.DetachFromActor();

		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(CapabilityTags::Death, this);

		Player.StopSlotAnimation();

		Player.ClearCameraSettingsByInstigator(this);

		UMoonMarketMothEventHandler::Trigger_OnStopRiding(Moth, FMoonMarketInteractingPlayerEventParams(Player));

		if(RiderComp.Moth != nullptr)
			RiderComp.Moth.ThrowOffRider();
		
		// Niagara::SpawnOneShotNiagaraSystemAtLocation(Moth.DisintegrateOneshot, Moth.ActorLocation);
		// Debug::DrawDebugSphere(Moth.ActorLocation, 100, 12, FLinearColor::Red);
		
		Moth = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			Moth.SteerInput.Value = MoveInput;
			Moth.TargetTiltValue.Value = MoveInput.Y;
		}

		float FFFrequency = 25.0;
		FHazeFrameForceFeedback FF;
		FF.RightMotor = 1.25 + Math::Sin(Time::GameTimeSeconds * FFFrequency);
		FF.LeftMotor = 1.25 + Math::Sin(Time::GameTimeSeconds * -FFFrequency);
		Player.SetFrameForceFeedback(FF, 0.15);

		float Alpha = ActiveDuration / Moth.Settings.RideDuration;
		Moth.NiagaraDisintegrateComp.SetFloatParameter(n"SpawnRate", Math::Pow(Alpha, 2) * 0);
		Owner.SetActorRelativeLocation(FVector::DownVector * 247 + FVector::BackwardVector * 20);
		Owner.SetActorRelativeRotation(FRotator::ZeroRotator);
	}
}
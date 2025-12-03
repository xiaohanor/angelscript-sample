class UCoastTrainDroneScanCartBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastTrainDroneSettings Settings;

	ACoastTrainCart TrainCart;
	FVector TrainCartBounds;
	float PauseTime;
	float MoveDir;
	bool bHasDetectedPlayer = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastTrainDroneSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
		OnRespawn(); // In case owner is not spawned by spawner
	}

	UFUNCTION()
	private void OnRespawn()
	{
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor);
		else if (Owner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(Owner.AttachParentActor);
		else
			TrainCart = nullptr;

		if (TrainCart != nullptr)
		{
			// Get dimensions of cart
			FVector Dummy;
			TrainCart.GetActorLocalBounds(true, Dummy, TrainCartBounds);
		}			
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TrainCart == nullptr)
			return false;
		// Don't start scanning until we're above the cart
		if (Owner.ActorLocation.Z < TrainCart.ActorLocation.Z + Settings.ScanCartHeight * 0.5)
			return false;
		// Don't start scanning until we're fairly centered above the cart
		float RightDistance = TrainCart.ActorRightVector.DotProduct(Owner.ActorLocation - TrainCart.ActorLocation);
		if (Math::Abs(RightDistance) > Settings.ScanCartSpeed * 0.5)
			return false;
		if (!HasPlayerInRange(Settings.ScanCartActivationRange, Settings.ScanCartActivationRange* 0.5))
			return false;
		return true;
	}

	bool HasPlayerInRange(float Before, float After) const
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector FromCart = Player.ActorCenterLocation - TrainCart.ActorCenterLocation;
			float DistAlongCart = TrainCart.ActorForwardVector.DotProduct(FromCart);
			if ((DistAlongCart > -Before) && (DistAlongCart < After))
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!HasPlayerInRange(Settings.ScanCartActivationRange * 1.2, Settings.ScanCartActivationRange* 0.6))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PauseTime = Time::GameTimeSeconds + Settings.ScanCartPauseDuration;
		bHasDetectedPlayer = false;

		FVector FromCart = Owner.ActorCenterLocation - TrainCart.ActorCenterLocation;
		float DistAlongCart = TrainCart.ActorForwardVector.DotProduct(FromCart);
		MoveDir = (DistAlongCart < -TrainCartBounds.X * 0.75) ? 1.0 : -1.0;

		UCoastTrainDroneEffectHandler::Trigger_OnStartScanning(Owner, FTrainDroneScanParams(TrainCart));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UCoastTrainDroneEffectHandler::Trigger_OnStopScanning(Owner);
		Cooldown.Set(Settings.ScanCartCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateInDirection(TrainCart.ActorForwardVector * MoveDir);

		if (bHasDetectedPlayer)
		{
			// Stop in place
			return;
		}

		FVector TrainCartFwd = TrainCart.ActorForwardVector;
		if (Time::GameTimeSeconds > PauseTime)
		{
			// Move towards end of cart
			FVector BoundsCenter = TrainCart.ActorCenterLocation + TrainCartFwd * (Settings.ScanCartExtraInFront - Settings.ScanCartExtraBehind) * 0.5;
			float TrainCartHalLength = TrainCartBounds.X + (Settings.ScanCartExtraInFront + Settings.ScanCartExtraBehind) * 0.5;
			FVector FromCart = Owner.ActorCenterLocation - BoundsCenter;
			float DistAlongCart = TrainCartFwd.DotProduct(FromCart);
			FVector Destination = BoundsCenter + TrainCartFwd * (DistAlongCart + MoveDir * 100.0);
			Destination += FVector::UpVector * Settings.ScanCartHeight;

			float Speed = Settings.ScanCartSpeed;
			if (DistAlongCart * MoveDir > TrainCartHalLength)
				Speed *= 2.0; // Move faster back to cart
			DestinationComp.MoveTowards(Destination, Speed);

			// Turn around?
			if (DistAlongCart * MoveDir > TrainCartHalLength - Settings.ScanCartSpeed * 0.5)
			{
				// Every now and then I get a little bit lonely and you're never comin' round
				PauseTime = Time::GameTimeSeconds + Settings.ScanCartPauseDuration;
				MoveDir *= -1.0;
			}
		}

		DestinationComp.RotateInDirection(TrainCartFwd * MoveDir);

		// Check if we spot a player
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;
			
			// Near enough to scanning plane?
			FVector ToPlayer = Player.ActorLocation - Owner.ActorLocation;
			float DistAlongCart = TrainCartFwd.DotProduct(ToPlayer);
			if (Math::Abs(DistAlongCart) > Settings.ScanCartDetectionDepth)
				continue;

			// Within width of beam?
			float DistAcrossCart = TrainCart.ActorRightVector.DotProduct(ToPlayer);
			FVector2D InputRange = FVector2D(-Settings.ScanCartHeight * 0.75, 0.0);
			float ScanWidth = Settings.ScanCartDetectionWidth * Math::GetMappedRangeValueClamped(InputRange, FVector2D(1.0, 0.1), ToPlayer.Z); 
			if (Math::Abs(DistAcrossCart) > ScanWidth)
				continue;

			// Busted!
			// TODO: Investigate how best to network this, might be a netfunction would do better or we might need to switch control side when a player approaches.
			CrumbDetectPlayer(Player);
		}

#if EDITOR
		// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector Origin = TrainCart.ActorCenterLocation + TrainCart.ActorForwardVector * (Settings.ScanCartExtraInFront - Settings.ScanCartExtraBehind) * 0.5;
			FVector Extents = TrainCartBounds;
			Extents.X += (Settings.ScanCartExtraInFront + Settings.ScanCartExtraBehind) * 0.5;
			Debug::DrawDebugBox(Origin, Extents, TrainCart.ActorRotation, FLinearColor::DPink, 10);
		}
#endif		
	}

	UFUNCTION(CrumbFunction)
	void CrumbDetectPlayer(AHazePlayerCharacter Player)
	{
		TargetComp.SetTarget(Player);
		bHasDetectedPlayer = true;
	}
}
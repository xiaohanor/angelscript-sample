class USanctuaryLavamoleBittenByOneCapability : UHazeCapability
{
	// Local for snappiness
	AAISanctuaryLavamole Lavamole;
	USanctuaryLavamoleSettings Settings;
	USanctuaryLavamoleCentipedeBiteResponseComponent CachedBittenComp;
	UHazeActionQueueComponent ActionComp;

	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;
	float WiggleRotationTimer;
	FVector StartForward;
	FVector StartUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Lavamole = Cast<AAISanctuaryLavamole>(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		ActionComp = UHazeActionQueueComponent::GetOrCreate(Owner);

		Lavamole.Bite2Comp.DisableForPlayer(Game::Mio, this);
		Lavamole.Bite2Comp.DisableForPlayer(Game::Zoe, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SanctuaryCentipedeDevToggles::Mole::TearCoopMoles.IsEnabled())
			return false;

		if (!Lavamole.bHasBeenPulledOutOfBurrow)
			return false;

		if (Lavamole.Bite1Comp.IsBitten() && Lavamole.Bite2Comp.IsBitten())
			return false;

		if (Lavamole.Bite1Comp.IsBitten() || Lavamole.Bite2Comp.IsBitten())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Lavamole.Bite1Comp.IsBitten() && Lavamole.Bite2Comp.IsBitten())
			return true;

		if (Lavamole.Bite1Comp.IsBitten() || Lavamole.Bite2Comp.IsBitten())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
		CachedBittenComp = Lavamole.Bite1Comp.IsBitten() ? Lavamole.Bite1Comp : Lavamole.Bite2Comp;

		if (Lavamole.Bite1Comp.IsBitten())
			Lavamole.Bite2Comp.EnableForPlayer(CachedBittenComp.Biter.OtherPlayer, this);

		Lavamole.DisableAutoTargeting(true);
		StartForward = Owner.GetActorRotation().ForwardVector;
		StartUp = Owner.GetActorRotation().UpVector;
		WiggleRotationTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
		
		if (!Lavamole.Bite2Comp.IsBitten())
		{
			if (HasControl())
			{
				ActionComp.Empty();
				ActionComp.Capability(USanctuaryLavamoleActionEscapeCapability, FSanctuaryLavamoleActionEscapeData());
				ActionComp.Capability(USanctuaryLavamoleActionScaredCapability, FSanctuaryLavamoleActionScaredData());
			}

			Lavamole.Bite2Comp.DisableForPlayer(Game::Mio, this);
			Lavamole.Bite2Comp.DisableForPlayer(Game::Zoe, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WiggleRotationTimer += DeltaTime * Settings.PulledWiggleRotationSpeed;
		float SinTimer = Math::Sin(WiggleRotationTimer);
		float WiggleDegrees = SinTimer * Settings.PulledWiggleRotationMax;

		FVector TowardsHead = -CachedBittenComp.BiterParams.Player.ActorForwardVector;
		FVector NewDirection = TowardsHead; 

		// are we biting the mole feet instead of the head?
		if (!Lavamole.Bite1Comp.IsBitten()) 
			NewDirection = -NewDirection;

		if (ActiveDuration < Settings.PullRotateTowardsCentoForwardDuration)
		{
			float DurationInterpolation = Math::Clamp(ActiveDuration / Settings.PullRotateTowardsCentoForwardDuration, 0.0, 1.0);
			FVector NewForward = Math::Lerp(StartForward, Lavamole.Settings.DraggedOutFacingVector, DurationInterpolation);
			FVector NewUp = Math::Lerp(StartUp, NewDirection, DurationInterpolation);
			Owner.SetActorRotation(FRotator::MakeFromXZ(NewForward, NewUp));
		}
		else 
		{
			FQuat Wiggle = FQuat(FVector::UpVector, Math::DegreesToRadians(WiggleDegrees));
			FQuat NewRotation = FRotator::MakeFromZX(NewDirection, Lavamole.Settings.DraggedOutFacingVector).Quaternion() * Wiggle;
			// Debug::DrawDebugString(Lavamole.ActorLocation, "" + WiggleDegrees);
			Owner.SetActorRotation(NewRotation.Rotator());
			// Debug::DrawDebugCoordinateSystem(Lavamole.ActorLocation, Lavamole.ActorRotation, 300.0);
		}

		FVector CentoPinchLocation = CachedBittenComp.BiterParams.Player.ActorLocation + CachedBittenComp.BiterParams.Player.ActorForwardVector * Settings.DesiredDistanceToCentoHead;
		FVector ToBiteComp = Lavamole.ActorLocation - CachedBittenComp.WorldLocation;
		Owner.SetActorLocation(CentoPinchLocation + ToBiteComp);

		// Set FF right / left according to wiggling :D
		if (Lavamole.GrabbedForceFeedbackEffect != nullptr && CachedBittenComp.Biter != nullptr && CachedBittenComp.Biter.HasControl())
		{
			float Lerpy = SinTimer * 0.5;
			Lerpy += 0.5;
			float LeftAmount = Settings.BiteForceFeedbackStrength * Lerpy;
			float RightAmount = Settings.BiteForceFeedbackStrength * (1.0 - Lerpy);
			CachedBittenComp.Biter.SetFrameForceFeedback(LeftAmount, RightAmount, LeftAmount, RightAmount, 1.0);
		}
	}
}

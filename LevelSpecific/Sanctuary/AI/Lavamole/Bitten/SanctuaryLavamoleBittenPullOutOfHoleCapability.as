class USanctuaryLavamoleBittenPullOutOfHoleCapability : UHazeCapability
{
	// Local for snappiness
	AAISanctuaryLavamole Lavamole;
	USanctuaryLavamoleSettings Settings;
	AAISanctuaryLavamole Mole;
	
	float WiggleRotationTimer;
	float StartedHeight = 0.0;
	float GrabbedTimer = 0.0;

	USanctuaryLavamoleCentipedeBiteResponseComponent CachedBittenComp;
	UHazeActionQueueComponent ActionComp;

	FVector OriginalHeadLocation;
	FVector OriginalMoleLocation;
	FRotator OriginalMoleRotation;
	FVector MoleStartedFacingDirection;

	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;

	bool bHunkeringDown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mole = Cast<AAISanctuaryLavamole>(Owner);
		Lavamole = Cast<AAISanctuaryLavamole>(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		ActionComp = UHazeActionQueueComponent::GetOrCreate(Owner);
		SanctuaryCentipedeDevToggles::Mole::TearCoopMoles.MakeVisible();
		SanctuaryCentipedeDevToggles::Mole::DragaMoles.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SanctuaryCentipedeDevToggles::Mole::TearCoopMoles.IsEnabled())
			return false;

		if (Mole.bHasBeenPulledOutOfBurrow)
			return false;

		if (Mole.Bite1Comp.IsBitten() && Mole.Bite2Comp.IsBitten())
			return false;

		if (Mole.Bite1Comp.IsBitten() || Mole.Bite2Comp.IsBitten())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Mole.bHasBeenPulledOutOfBurrow)
			return true;

		if (Mole.Bite1Comp.IsBitten() && Mole.Bite2Comp.IsBitten())
			return true;

		if (Mole.Bite1Comp.IsBitten() || Mole.Bite2Comp.IsBitten())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHunkeringDown = true;
		Owner.BlockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
		CachedBittenComp = Mole.Bite1Comp.IsBitten() ? Mole.Bite1Comp : Mole.Bite2Comp;

		UCentipedeMovementSettings::SetMoveSpeed(CachedBittenComp.Biter, Settings.GrabbedPlayerMaxSpeedSlowdown, this);
		CachedBittenComp.OnBeforeCentipedeBiteStopped.AddUFunction(this, n"BeforeCentipedeBiteStopped");
	}

	void StoreOriginalData()
	{
		OriginalMoleLocation = Mole.ActorLocation;
		OriginalMoleRotation = Mole.ActorRotation;
		MoleStartedFacingDirection = Mole.ActorForwardVector;
		AccLocation.SnapTo(OriginalMoleLocation);
		AccRotation.SnapTo(OriginalMoleRotation);

		{
			FVector ToBiteTarget = CachedBittenComp.WorldLocation - CachedBittenComp.BiterParams.Player.ActorLocation;
			ToBiteTarget.Z = 0.0;
			FVector HeadTargetLocation = CachedBittenComp.WorldLocation - ToBiteTarget.GetSafeNormal() * Settings.DesiredDistanceToCentoHead;
			OriginalHeadLocation = HeadTargetLocation;
			UCentipedeBiteComponent BiteComp = UCentipedeBiteComponent::Get(CachedBittenComp.Biter);
			if (CachedBittenComp.Biter.HasControl())
				BiteComp.BiteSnapToLocation(HeadTargetLocation, ToBiteTarget, Settings.GrabAlignPlayerHeadDuration);
		}
	}

	UFUNCTION()
	private void BeforeCentipedeBiteStopped(FCentipedeBiteEventParams BiteParams)
	{
		UCentipedeMovementSettings::ClearMoveSpeed(CachedBittenComp.Biter, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CachedBittenComp.Biter != nullptr)
			UCentipedeMovementSettings::ClearMoveSpeed(CachedBittenComp.Biter, this);
		CachedBittenComp.OnBeforeCentipedeBiteStopped.Unbind(this, n"BeforeCentipedeBiteStopped");

		Owner.UnblockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
		if (!Mole.bHasBeenPulledOutOfBurrow)
		{
			Owner.SetActorLocation(OriginalMoleLocation);
			Owner.SetActorRotation(OriginalMoleRotation);

			// queue scared
			if (HasControl())
			{
				ActionComp.Empty();
				ActionComp.Capability(USanctuaryLavamoleActionScaredCapability, FSanctuaryLavamoleActionScaredData());
			}
		}

		if (Lavamole.HasControl() && SanctuaryCentipedeDevToggles::Mole::DragaMoles.IsEnabled())
		{
			bool bKilledByTearing = false;
			Lavamole.CrumbKillMole(bKilledByTearing); 
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Settings.GrabOutOfBurrowDistance < KINDA_SMALL_NUMBER)
			return;

		bool bStillHunkeringDown = ActiveDuration < Settings.MoleBittenBurrowSlightlyDuration;
		if (bHunkeringDown != bStillHunkeringDown)
		{
			StoreOriginalData();
		}
		else if (bHunkeringDown)
		{
			// scared location
			FVector InterpolatedOffset = FVector::ZeroVector;
			float HeightInterpolation = Math::Clamp(ActiveDuration / Settings.GrabAlignPlayerHeadDuration, 0.0, 1.0);
			InterpolatedOffset.Z = Math::EaseOut(StartedHeight, Settings.ScaredHeightOffset, HeightInterpolation, 2.0);
			Owner.SetActorLocation(Mole.OccupiedHole.ActorLocation + InterpolatedOffset);
			return;
		}
		bHunkeringDown = bStillHunkeringDown;

		bool bAligningPlayer = ActiveDuration > Settings.MoleBittenBurrowSlightlyDuration && ActiveDuration < Settings.GrabAlignPlayerHeadDuration;
		if (bAligningPlayer)
			return;

		FVector BiterLocation = CachedBittenComp.BiterParams.Player.ActorLocation;
		FVector BiterForward = CachedBittenComp.BiterParams.Player.ActorForwardVector;

		float MovedDistance = BiterLocation.Distance(OriginalHeadLocation);
		float GrabOutOfBurrowDistance = Settings.GrabOutOfBurrowDistance;
		if (SanctuaryCentipedeDevToggles::Mole::DragaMoles.IsEnabled())
			GrabOutOfBurrowDistance = Settings.GrabOutOfBurrowKillDistance;
		float DistanceInterpolation = Math::Clamp(MovedDistance / GrabOutOfBurrowDistance, 0.0, 1.0);
		float Speed = Math::EaseOut(Settings.GrabbedPlayerMaxSpeedSlowdown, Settings.GrabbedPlayerMoveSpeed, DistanceInterpolation, 2.0);
		UCentipedeMovementSettings::SetMoveSpeed(CachedBittenComp.Biter, Speed, this);

		// Update mole location & rotation
		FVector CentoPinchLocation = BiterLocation + BiterForward * Settings.DesiredDistanceToCentoHead;
		FVector HoleLocation = Lavamole.OccupiedHole.ActorLocation;
		//if (SanctuaryCentipedeDevToggles::DragaMoles.IsEnabled())
		//	HoleLocation.Z -= 100.0;
		FVector HeadToHole = HoleLocation - CentoPinchLocation;
		HeadToHole.Z = 0.0;

		FVector InterpolatedFacing = Math::EaseOut(MoleStartedFacingDirection, Lavamole.Settings.DraggedOutFacingVector, DistanceInterpolation, 3.0);
		FVector InterpolatedUp = Math::EaseOut(FVector::UpVector, -HeadToHole.GetSafeNormal(), DistanceInterpolation, 3.0);

		// no wiggle on pull
		// WiggleRotationTimer += DeltaTime * Settings.GrabbedWiggleRotationSpeed;
		// float WiggleDegrees = Math::Sin(WiggleRotationTimer) * Settings.GrabbedWiggleRotationMax;
		// FVector FacingDirecton = InterpolatedFacing.RotateAngleAxis(WiggleDegrees, InterpolatedUp);

		AccRotation.AccelerateTo(FRotator::MakeFromZX(InterpolatedUp, InterpolatedFacing), 0.1, DeltaTime);
		Owner.SetActorRotation(AccRotation.Value);

		FVector ToBiteComp = Lavamole.ActorLocation - CachedBittenComp.WorldLocation;
		AccLocation.AccelerateTo(Math::Lerp(OriginalMoleLocation, CentoPinchLocation + ToBiteComp, DistanceInterpolation), 0.1, DeltaTime);
		FVector LocationWithHeightOffset = AccLocation.Value;
		LocationWithHeightOffset.Z = Math::EaseOut(OriginalMoleLocation.Z, CentoPinchLocation.Z + 100.0, DistanceInterpolation, 2.0);
		Owner.SetActorLocation(LocationWithHeightOffset);

		if(Mole.ActorLocation.Distance(OriginalMoleLocation) > GrabOutOfBurrowDistance && HasControl())
			CrumbHasBeenPulledOut();

		// Set FF right / left according to wiggling :D
		if (Lavamole.GrabbedForceFeedbackEffect != nullptr && CachedBittenComp.Biter != nullptr && CachedBittenComp.Biter.HasControl())
		{
			float LeftAmount = Settings.BiteForceFeedbackStrength;
			float RightAmount = Settings.BiteForceFeedbackStrength;
			CachedBittenComp.Biter.SetFrameForceFeedback(LeftAmount, RightAmount, LeftAmount, RightAmount, DistanceInterpolation);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHasBeenPulledOut()
	{
		Mole.bHasBeenPulledOutOfBurrow = true;
	}
}
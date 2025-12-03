class USanctuaryLavamoleBittenByBothCapability : UHazeCapability
{
	// Local for snappiness
	AAISanctuaryLavamole Lavamole;
	USanctuaryLavamoleSettings Settings;
	
	FVector StartedFacingDirection;
	float WiggleRotationTimer;
	float TimeSinceBite = 0.0;
	float StartedHeight = 0.0;

	float GrabbedTimer = 0.0;
	
	FVector OriginalDistanceBetweenPoints;

	bool bSentKill = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Lavamole = Cast<AAISanctuaryLavamole>(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SanctuaryCentipedeDevToggles::Mole::TearCoopMoles.IsEnabled())
			return false;
		if (Lavamole.Bite1Comp.IsBitten() && Lavamole.Bite2Comp.IsBitten())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Lavamole.Bite1Comp.IsBitten() && Lavamole.Bite2Comp.IsBitten())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
		Lavamole.Bite2Comp.bAutoTargetWhileBitten = true;
		OriginalDistanceBetweenPoints = Lavamole.Bite1Comp.WorldLocation - Lavamole.Bite2Comp.WorldLocation;
		if (Lavamole.Bite2Comp.Biter.HasControl())
		{
			UCentipedeBiteComponent BiteComp = UCentipedeBiteComponent::Get(Lavamole.Bite2Comp.Biter);
			FVector BiterHeadLocation = Lavamole.Bite2Comp.BiterParams.Player.ActorLocation;
			FVector ToBiteTarget = Lavamole.Bite2Comp.WorldLocation - BiterHeadLocation;
			const FVector SecondHeadTargetLocation = BiterHeadLocation + ToBiteTarget - ToBiteTarget.GetSafeNormal() * Settings.DesiredDistanceToCentoHead;
			BiteComp.BiteSnapToLocation(SecondHeadTargetLocation, ToBiteTarget, Settings.GrabAlignPlayerHeadDuration);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
		Lavamole.MeshOffsetComponent.SetWorldScale3D(FVector::OneVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector FirstCentoPinchLocation = Lavamole.Bite1Comp.BiterParams.Player.ActorLocation + Lavamole.Bite1Comp.BiterParams.Player.ActorForwardVector * Settings.DesiredDistanceToCentoHead;
		FVector SecondCentoPinchLocation = Lavamole.Bite2Comp.BiterParams.Player.ActorLocation + Lavamole.Bite2Comp.BiterParams.Player.ActorForwardVector * Settings.DesiredDistanceToCentoHead;

		// Debug::DrawDebugSphere(FirstCentoPinchLocation, 75, 12, FLinearColor::LucBlue, 3.0, 5.0, true);
		// Debug::DrawDebugSphere(SecondCentoPinchLocation, 75, 12, FLinearColor::LucBlue, 3.0, 5.0, true);

		FVector Between = SecondCentoPinchLocation - FirstCentoPinchLocation;
		float ScalingFraction = Between.Size() / OriginalDistanceBetweenPoints.Size();
		FVector MoleUpDirection = -Between.GetSafeNormal();

		WiggleRotationTimer += DeltaTime * Settings.GrabbedWiggleRotationSpeed * ScalingFraction;
		float WiggleDegrees = Math::Sin(WiggleRotationTimer) * Settings.GrabbedWiggleRotationMax;
		FVector FacingDirection = Lavamole.Settings.DraggedOutFacingVector.RotateAngleAxis(WiggleDegrees, MoleUpDirection);

		Owner.SetActorRotation(FRotator::MakeFromZX(MoleUpDirection, FacingDirection));
		
		FVector InBetweenHeads = FirstCentoPinchLocation - SecondCentoPinchLocation;
		Owner.SetActorLocation(FirstCentoPinchLocation - InBetweenHeads * 0.5);

		// Debug::DrawDebugSphere(Owner.ActorLocation, 50.0, 12, ColorDebug::Magenta, 3.0, 0.0, true);
		// Debug::DrawDebugLine(FirstCentoPinchLocation, SecondCentoPinchLocation);
		// Debug::DrawDebugSphere(FirstCentoPinchLocation - InBetweenHeads * 0.5, 50.0, 12, ColorDebug::White, 3.0, 0.0, true);
		
		bool bShouldKill = OriginalDistanceBetweenPoints.Size() < SMALL_NUMBER || Between.Size() > Settings.TearDistance;
		if (bShouldKill && !bSentKill)
		{
			bSentKill = true;
			// We send this from both control and remote to be sure, since any player may be the one initiating the kill, and killing will 
			bool bKilledByTearing = true;
			Lavamole.CrumbKillMole(bKilledByTearing); 
			return;
		}

		float Intensity = Math::Clamp(ScalingFraction, 0.0, 1.0);
		if (Lavamole.TearingForceFeedbackEffect != nullptr)
		{
			if (Lavamole.Bite1Comp != nullptr && Lavamole.Bite1Comp.Biter != nullptr)
				Lavamole.Bite1Comp.Biter.PlayForceFeedback(Lavamole.TearedForceFeedbackEffect, false, false, this, Intensity);

			if (Lavamole.Bite2Comp != nullptr && Lavamole.Bite2Comp.Biter != nullptr)
				Lavamole.Bite2Comp.Biter.PlayForceFeedback(Lavamole.TearedForceFeedbackEffect, false, false, this, Intensity);
		}

		// Scale dat mole
		FVector Scaling = FVector::OneVector;
		Scaling.X = ScalingFraction;

		// Debug::DrawDebugString(Lavamole.ActorLocation, "Scaling " + ScalingFraction);

		if (ScalingFraction > 1.0)
		{
			float ScalingValue = 1 + (1 - Scaling.X) * 0.5;
			if (ScalingValue < 0.05)
				return;

			Scaling.Z = ScalingValue;
			Scaling.Y = ScalingValue;
		}
		Lavamole.MeshOffsetComponent.SetWorldScale3D(Scaling);
		// Owner.SetActorScale3D(Scaling);
	}
}
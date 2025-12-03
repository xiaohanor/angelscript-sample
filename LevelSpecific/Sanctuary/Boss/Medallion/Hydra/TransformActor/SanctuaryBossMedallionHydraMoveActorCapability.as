class USanctuaryBossMedallionHydraMoveActorCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	USanctuaryBossMedallionHydraMoveActorComponent MoveActorComp;
	ASanctuaryBossMedallionHydra Hydra;
	USimpleMovementData Movement;

	FSanctuaryBossMedallionHydraMoveActorRequest LastRequest;
	FHazeAcceleratedVector AccActorLocation;
	FHazeAcceleratedRotator AccActorRotation;

	float StartBlendTimestamp;

	FTransform HydraOGTransform;
	FVector StartBlendLocation;
	FRotator StartBlendRotation;
	bool bLastRequestSnap = false;

	FHazeEasedQuat EasedAttackRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveActorComp = USanctuaryBossMedallionHydraMoveActorComponent::GetOrCreate(Owner);
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		HydraOGTransform = Hydra.ActorTransform;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveActorComp.MoveActorRequests.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveActorComp.MoveActorRequests.Num() > 0)
			return false;
		if (HasLocation())
			return false;
		if (HasRotation())
			return false;
		return true;
	}

	bool HasLocation() const
	{
		return AccActorLocation.Value.Distance(HydraOGTransform.Location) > KINDA_SMALL_NUMBER;
	}

	bool HasRotation() const
	{
		return AccActorRotation.Value.ForwardVector.AngularDistance(HydraOGTransform.Rotation.ForwardVector) > KINDA_SMALL_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccActorLocation.SnapTo(Hydra.ActorLocation);
		AccActorRotation.SnapTo(Hydra.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Hydra.AttackedTransformOverride.IsEmpty())
		{
			EasedAttackRotation.EaseTo(Hydra.AttackedTransformStartRotation, FQuat(), 2.5, DeltaTime, EEasing::EaseInOut);
			FRotator AttackedRotation = EasedAttackRotation.GetValue().Rotator();
			AccActorRotation.SnapTo(AttackedRotation);
			// AccActorRotation.AccelerateToWithStop(FRotator(), 4.0, DeltaTime, 0.01);
			Hydra.SetActorLocation(AccActorLocation.Value);
			Hydra.SetActorRotation(AccActorRotation.Value);
			return;
		}
		else
			EasedAttackRotation.ForceResetProgress();

		if (MoveActorComp.MoveActorRequests.Num() == 0)
		{
			if (LastRequest.Instigator != nullptr)
			{
				StartBlendTimestamp = Time::GameTimeSeconds;
				LastRequest.Instigator = nullptr;
				StartBlendLocation = Hydra.ActorLocation;
				StartBlendRotation = Hydra.ActorRotation;
			}
			
			if (LastRequest.bSnapOnExit)
			{
				AccActorLocation.SnapTo(HydraOGTransform.Location);
				AccActorRotation.SnapTo(HydraOGTransform.Rotator());
			}
			else
			{
				AccActorLocation.AccelerateToWithStop(HydraOGTransform.Location, 1.0, DeltaTime, 0.01);
				AccActorRotation.AccelerateToWithStop(HydraOGTransform.Rotator(), 1.0, DeltaTime, 0.01);
			}

			if (SanctuaryMedallionHydraDevToggles::Draw::HydraTransformActor.IsEnabled())
			{
				FVector End = HydraOGTransform.Location;
				FVector Direction = StartBlendLocation - End;
				Debug::DrawDebugLine(StartBlendLocation, End, Hydra.DebugColor, 5.0, 0.0, true);
				Debug::DrawDebugCone(End, Direction, 500, LineColor = Hydra.DebugColor, bDrawInForeground = true);
				Debug::DrawDebugArrow(End, End + HydraOGTransform.Rotation.ForwardVector * 500, 10, Hydra.DebugColor, 10, 0.0, true);
			}

			TEMPORAL_LOG(Hydra, "Requesters").Sphere("Transforms Actor Pivot Loc", LastRequest.ComponentToFollow.WorldLocation, 100.0, ColorDebug::Gray);
		}
		else
		{
			FSanctuaryBossMedallionHydraMoveActorRequest ActiveRequest = MoveActorComp.MoveActorRequests[0];
			if (LastRequest.Instigator != ActiveRequest.Instigator)
			{
				StartBlendTimestamp = Time::GameTimeSeconds;
				bLastRequestSnap = LastRequest.bSnapOnExit;
				LastRequest = ActiveRequest;
				StartBlendLocation = Hydra.ActorLocation;
				StartBlendRotation = Hydra.ActorRotation;
				MoveActorComp.MoveActorRequests[0].NumActivations += 1;
			}

			bool bShouldSnap = (LastRequest.bSnapFirstTime && MoveActorComp.MoveActorRequests[0].NumActivations == 1) || (LastRequest.BlendInDuration < KINDA_SMALL_NUMBER) || bLastRequestSnap;
			if (bShouldSnap)
			{
				AccActorLocation.SnapTo(LastRequest.ComponentToFollow.WorldLocation);
				AccActorRotation.SnapTo(LastRequest.ComponentToFollow.WorldRotation);
			}
			else
			{
				float Alpha = Math::GetMappedRangeValueClamped(FVector2D(StartBlendTimestamp, StartBlendTimestamp + LastRequest.BlendInDuration), FVector2D(0.0, 1.0), Time::GameTimeSeconds);
				float EasedAlpha = Math::EaseInOut(0.0, 1.0, Alpha, 2);
				FVector Location = Math::Lerp(StartBlendLocation, LastRequest.ComponentToFollow.WorldLocation, EasedAlpha);
				FRotator Rotation = Math::LerpShortestPath(StartBlendRotation, LastRequest.ComponentToFollow.WorldRotation, EasedAlpha);
				AccActorLocation.SnapTo(Location);
				AccActorRotation.SnapTo(Rotation);
			}

			if (SanctuaryMedallionHydraDevToggles::Draw::HydraTransformActor.IsEnabled())
			{
				FVector End = LastRequest.ComponentToFollow.WorldLocation;
				FVector Direction = StartBlendLocation - End;
				Debug::DrawDebugLine(StartBlendLocation, End, Hydra.DebugColor, 5.0, 0.0, true);
				Debug::DrawDebugCone(End, Direction, 400, LineColor = Hydra.DebugColor, bDrawInForeground = true);
				Debug::DrawDebugSphere(AccActorLocation.Value, 500, 12, ColorDebug::White, 10, 0.0, true);
				ColorDebug::DrawTintedTransform(End, LastRequest.ComponentToFollow.WorldRotation, Hydra.DebugColor);
				Debug::DrawDebugString(End, "transformer:\n" + LastRequest.ComponentToFollow.Owner.ActorNameOrLabel, Hydra.DebugColor);
			}
		}

		Hydra.SetActorLocation(AccActorLocation.Value);
		Hydra.SetActorRotation(AccActorRotation.Value);
	}
};
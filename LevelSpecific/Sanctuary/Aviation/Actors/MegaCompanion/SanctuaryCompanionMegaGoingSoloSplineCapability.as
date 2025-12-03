class USanctuaryCompanionMegaGoingSoloSplineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::MegaCompanion);
	
	ASanctuaryMegaCompanion MegaCompanion;
	USanctuaryCompanionMegaCompanionPlayerComponent PlayerComponent;
	USanctuaryCompanionAviationPlayerComponent AviationComponent;
	FHazeRuntimeSpline Spliney;

	bool bArrived = false;

	float OGDistance = 0.0;
	float CurrentDistance = 0.0;
	float OGSpeed = 0.0;
	bool bStart = false;

	ASanctuaryHydraTempleGate Gate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComponent = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
		PlayerComponent.bTutorialStayForDoor = true;
		AviationComponent = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		AviationComponent.OnAviationStopped.AddUFunction(this, n"AviationStopped");
	}

	UFUNCTION()
	private void AviationStopped(AHazePlayerCharacter ThePlayer)
	{
		bStart = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// LOCAL!
		if (!bStart)
			return false;
		if (bArrived)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bArrived)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MegaCompanion = PlayerComponent.MegaCompanion;
		TArray<FVector> Pointies;
		Pointies.Add(MegaCompanion.ActorLocation - MegaCompanion.ActorForwardVector * 200.0);
		Pointies.Add(MegaCompanion.ActorLocation);

		TListedActors<ASanctuaryHydraTempleGate> Gates;
		Gate = Gates.Single;
		if (MegaCompanion.bIsLightBird)
		{
			Pointies.Add(Gate.BirdStatueLocation.WorldLocation - Gate.BirdStatueLocation.WorldRotation.ForwardVector * 500.0);
			Pointies.Add(Gate.BirdStatueLocation.WorldLocation);
		}
		else
		{
			Pointies.Add(Gate.FishStatueLocation.WorldLocation - Gate.FishStatueLocation.WorldRotation.ForwardVector * 500.0);
			Pointies.Add(Gate.FishStatueLocation.WorldLocation);
		}

		Spliney.SetPoints(Pointies);

		CurrentDistance = Spliney.GetClosestSplineDistanceToLocation(MegaCompanion.ActorLocation);
		OGDistance = CurrentDistance;
		OGSpeed = AviationComponent.Settings.TutorialSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (MegaCompanion.bIsLightBird)
		{
			FHazePlaySlotAnimationParams Params;
			Params.Animation = Gate.BirdSitAnimation;
			Params.bLoop = true;
			MegaCompanion.SkeletalMesh.PlaySlotAnimation(Params);

			MegaCompanion.SetActorLocation(Gate.BirdStatueLocation.WorldLocation);
			MegaCompanion.SetActorRotation(Gate.BirdStatueLocation.WorldRotation);
		}
		else
		{
			MegaCompanion.SetActorLocation(Gate.FishStatueLocation.WorldLocation);
			MegaCompanion.SetActorRotation(Gate.FishStatueLocation.WorldRotation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float DistanceToTravese = Spliney.Length - OGDistance;
		float TraversedAlpha = Math::Clamp((CurrentDistance - OGDistance) / DistanceToTravese, 0.0, 1.0);
		float Speed = Math::Lerp(OGSpeed, 500.0, TraversedAlpha);
		CurrentDistance += Speed * DeltaTime;
		if (CurrentDistance > Spliney.Length)
		{
			CurrentDistance = Spliney.Length;
			bArrived = true;
		}
		FVector NewLocation;
		FRotator NewRotation;
		Spliney.GetLocationAndRotationAtDistance(CurrentDistance, NewLocation, NewRotation);
		// Spliney.DrawDebugSpline();
		MegaCompanion.SetActorLocation(NewLocation);
		MegaCompanion.SetActorRotation(NewRotation);
	}
};
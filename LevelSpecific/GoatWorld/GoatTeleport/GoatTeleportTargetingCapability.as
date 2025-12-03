class UGoatTeleportTargetingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UGoatTeleportPlayerComponent TeleportComp;
	AGoatTeleportPreviewActor PreviewActor;

	float ForwardTraceMinCameraPitch = -30.0;
	float ForwardTraceMaxCameraPitch = 30.0;
	float ForwardsTraceForwardsOffset = 600.0;
	float ForwardTraceUpOffset = 300.0;
	float ForwardTraceMinLength = 3000.0;
	float ForwardTraceMaxLength = 4500.0;
	float ForwardTracePullback = 200.0;

	float DownTraceLength = 650.0;

	int BackwardsTraceSegments = 6.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TeleportComp = UGoatTeleportPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviewActor = TeleportComp.PreviewActor;
		PreviewActor.ActivatePreview();

		Player.ApplyCameraSettings(TeleportComp.TargetCamSettings, 0.5, this, EHazeCameraPriority::High);

		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PreviewActor.DeactivatePreview();

		TeleportComp.bValidTarget = false;

		Player.ClearCameraSettingsByInstigator(this, 0.5);

		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CameraPitch = Player.ViewRotation.Pitch;
		float TraceLength = Math::GetMappedRangeValueClamped(FVector2D(ForwardTraceMinCameraPitch, ForwardTraceMaxCameraPitch), FVector2D(ForwardTraceMinLength, ForwardTraceMaxLength), CameraPitch);

		FVector ForwardTraceStart = Player.ViewLocation + (Player.ViewRotation.UpVector * ForwardTraceUpOffset) + (Player.ViewRotation.ForwardVector * ForwardsTraceForwardsOffset);
		FVector ForwardTraceEnd = ForwardTraceStart + (Player.ViewRotation.ForwardVector * TraceLength);

		bool bValidTarget = false;
		FVector PreviewLocation;
		FVector FurthestInvalidLocation;

		for (int i = 0; i < BackwardsTraceSegments; i++)
		{
			float TraceBackwardsOffset = Math::Clamp(TraceLength/BackwardsTraceSegments * i, 0.0, ForwardTraceMaxLength - 1000.0);
			FVector TraceEnd = ForwardTraceEnd - (Player.ViewRotation.ForwardVector * TraceBackwardsOffset);
			FHitResult Hit = GetForwardHitResult(ForwardTraceStart, TraceEnd);

			if (i == 0)
				FurthestInvalidLocation = Hit.TraceEnd;

			if (Hit.bBlockingHit)
			{
				FVector PulledBackImpactPoint = Hit.ImpactPoint + (Player.ViewRotation.ForwardVector * -ForwardTracePullback);
				FHitResult DownHit = GetDownHitResult(PulledBackImpactPoint, PulledBackImpactPoint - (FVector::UpVector * DownTraceLength));
				if (DownHit.bBlockingHit)
				{
					PreviewLocation = DownHit.ImpactPoint;
					bValidTarget = true;
				}
				else
				{
					PreviewLocation = Hit.TraceEnd;
					bValidTarget = false;
					
				}
				break;
			}
			else
			{
				FHitResult DownHit = GetDownHitResult(TraceEnd, TraceEnd - (FVector::UpVector * DownTraceLength));
				if (DownHit.bBlockingHit)
				{
					PreviewLocation = DownHit.ImpactPoint;
					bValidTarget = true;
					
					break;
				}
				else
				{
					PreviewLocation = FurthestInvalidLocation;
					bValidTarget = false;
				}
			}
		}

		// Debug::DrawDebugSphere(FurthestInvalidLocation, 100.0, 12, FLinearColor::Red, 10.0);

		PreviewActor.SetPreviewValidity(bValidTarget);
		TeleportComp.bValidTarget = bValidTarget;

		PreviewActor.SetActorLocation(PreviewLocation);
		FVector PreviewDirection = Player.ViewRotation.Vector().ConstrainToPlane(FVector::UpVector);
		PreviewActor.SetActorRotation(PreviewDirection.Rotation());

		float PreviewScale = Math::GetMappedRangeValueClamped(FVector2D(1000.0, ForwardTraceMaxLength), FVector2D(1.5, 3.0), Player.GetDistanceTo(PreviewActor));
		PreviewActor.PreviewMesh.SetRelativeScale3D(FVector(PreviewScale));
	}

	FHitResult GetForwardHitResult(FVector TraceStart, FVector TraceEnd)
	{
		FHazeTraceSettings ForwardTraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		ForwardTraceSettings.IgnorePlayers();
		ForwardTraceSettings.UseLine();

		FHitResult ForwardHitResult = ForwardTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

		FVector Loc = ForwardHitResult.bBlockingHit ? ForwardHitResult.ImpactPoint : ForwardHitResult.TraceEnd;

		// Debug::DrawDebugSphere(Loc, 50.0, 24, FLinearColor::Green, 5.0);

		return ForwardHitResult;
	}

	FHitResult GetDownHitResult(FVector TraceStart, FVector TraceEnd)
	{
		FHazeTraceSettings DownTraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		DownTraceSettings.IgnorePlayers();
		DownTraceSettings.UseLine();

		FHitResult DownHitResult = DownTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		FVector Loc = DownHitResult.bBlockingHit ? DownHitResult.ImpactPoint : DownHitResult.TraceEnd;

		// Debug::DrawDebugSphere(Loc, 50.0, 24, FLinearColor::Purple, 5.0);

		return DownHitResult;
	}
}
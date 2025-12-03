struct FMagnetHarpoonLaunchedActivateParams
{
	FVector StartLocation;
	FVector AimDirection;
};

struct FMagnetHarpoonLaunchedDeactivateParams
{
	bool bStartRetracting;
	bool bWasBadHit;
};

class UMagnetHarpoonLaunchedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMagnetHarpoon MagnetHarpoon;
	AHazePlayerCharacter Player;
	UPlayerAimingComponent AimingComp;

	FMagnetHarpoonLaunchedActivateParams LaunchParams;
	FVector CurrentOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetHarpoon = Cast<AMagnetHarpoon>(Owner);
		Player = Drone::GetSwarmDronePlayer();

		AimingComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetHarpoonLaunchedActivateParams& Params) const
	{
		if (!MagnetHarpoon.HijackTargetableComp.IsHijacked())
			return false;

		if(!MagnetHarpoon.bHasLetGoOfPrimary)
			return false;

		if (!WasActionStarted(ActionNames::WeaponFire))
			return false;

		if(MagnetHarpoon.State != EMagnetHarpoonState::Aim)
			return false;

		if(!AimingComp.IsAiming())
			return false;

		Params.StartLocation = MagnetHarpoon.HarpoonRoot.WorldLocation;
		Params.AimDirection = GetAimDirection();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMagnetHarpoonLaunchedDeactivateParams& Params) const
	{
		if (!MagnetHarpoon.HijackTargetableComp.IsHijacked())
			return true;

		if(MagnetHarpoon.State != EMagnetHarpoonState::Launched)
			return true;

		if(MagnetHarpoon.AttachData.HasHit() && !MagnetHarpoon.AttachData.CanAttach())
		{
			Params.bStartRetracting = true;
			Params.bWasBadHit = true;
			return true;
		}

		// Don't deactivate if player releases trigger mid-launch
		// if (!IsActioning(ActionNames::WeaponFire))
		// {
		// 	Params.bStartRetracting = true;
		// 	return true;
		// }

		if (MagnetHarpoon.HarpoonRoot.WorldLocation.Distance(MagnetHarpoon.DefaultHarpoonWorldLocation) >= MagnetHarpoon.AutoRetractDistance)
		{
			Params.bStartRetracting = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetHarpoonLaunchedActivateParams Params)
	{
		MagnetHarpoon.State = EMagnetHarpoonState::Launched;
		LaunchParams = Params;
		CurrentOffset = FVector::ZeroVector;
		MagnetHarpoon.HarpoonRoot.SetAbsolute(true, true);
		MagnetHarpoon.HarpoonRoot.SetWorldRotation(FRotator::MakeFromX(Params.AimDirection));

		// Play camera shake
		Player.PlayCameraShake(MagnetHarpoon.LaunchCameraShake, this);

		UMagnetHarpoonEventHandler::Trigger_OnLaunch(Owner);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMagnetHarpoonLaunchedDeactivateParams Params)
	{
		if(Params.bStartRetracting)
		{
			MagnetHarpoon.State = EMagnetHarpoonState::Retracting;

			if(Params.bWasBadHit)
				UMagnetHarpoonEventHandler::Trigger_OnHitFail(Owner);
		}

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector Delta = LaunchParams.AimDirection * MagnetHarpoon.LaunchSpeed * DeltaTime;
		CurrentOffset += Delta;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.IgnoreActor(MagnetHarpoon);
		Trace.IgnorePlayers();
		Trace.UseSphereShape(40);

		const FHitResult HitResult = Trace.QueryTraceSingle(MagnetHarpoon.HarpoonRoot.WorldLocation, MagnetHarpoon.HarpoonRoot.WorldLocation + Delta);

		if(HasControl())
		{
			if(HitResult.bBlockingHit)
				MagnetHarpoon.AttachData = FMagnetHarpoonAttachData(HitResult);
		}
		else
		{
			// Stick around hit instead of going through surface while we wait for control side
			if (HitResult.bBlockingHit)
				CurrentOffset -= Delta.GetSafeNormal() * (Delta.Size() - HitResult.Distance);
		}

		MagnetHarpoon.HarpoonRoot.SetWorldLocation(LaunchParams.StartLocation + CurrentOffset);

		// Update cable length with arbitrary offset
		// float CableLength = Math::Abs(MagnetHarpoon.ActorLocation.Distance(MagnetHarpoon.HarpoonRoot.WorldLocation)) - 2000.0;   // WTF this is stupid sometimes?? Comment for now
		// MagnetHarpoon.CableComp.CableLength = CableLength;

		// Play FF
		float Strength = 1.0 - Math::Square(Math::Saturate(ActiveDuration / 0.133));
		FHazeFrameForceFeedback ForceFeedback;
		ForceFeedback.RightTrigger = 0.1;
		ForceFeedback.RightMotor = 0.2 * Strength;
		ForceFeedback.LeftMotor = 0.1 * Strength;
		Player.SetFrameForceFeedback(ForceFeedback);
	}

	FVector GetAimDirection() const
	{
		FAimingResult AimResult = AimingComp.GetAimingTarget(MagnetHarpoon);
		
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(MagnetHarpoon);
		Trace.IgnorePlayers();
		Trace.UseLine();

		FHitResult Hit = Trace.QueryTraceSingle(AimResult.AimOrigin, AimResult.AimOrigin + (AimResult.AimDirection * MagnetHarpoon.AutoRetractDistance));
		FVector TargetLoc = Hit.bBlockingHit ? Hit.ImpactPoint : Hit.TraceEnd;

		FVector Dir = (TargetLoc - MagnetHarpoon.HarpoonRoot.WorldLocation).GetSafeNormal();
		return Dir;
	}
};
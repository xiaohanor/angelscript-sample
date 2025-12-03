class UAdultDragonAcidBeamFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(BlockedWhileIn::Dash);	
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AcidFire");
	default CapabilityTags.Add(n"Aim");

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"AdultDragon";

	UPlayerAimingComponent AimComp;
	UPlayerAcidAdultDragonComponent DragonComp;
	float BeamTimer = 0.0;
	float PuddleTimer = 0.0;
	bool bBeamStarted = false;

	float HitTimer = 0.0;
	UAcidResponseComponent PreviousHitComponent;
	FAcidHit PreviousHitParams;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;
		if (DeactiveDuration < AdultDragonAcidBeam::BeamRechargeCooldown)
			return false;
		if (DragonComp.RemainingAcidAlpha < AdultDragonAcidBeam::BeamMinimumAcidCharge)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility) && ActiveDuration > AdultDragonAcidBeam::BeamMinimumDuration)
			return true;
		if (DragonComp.RemainingAcidAlpha <= 0.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.bIsFiringAcid = true;
		DragonComp.AnimParams.bIsShooting = true;
		//DragonComp.bUseStrafeMovement = true;
		Player.PlayCameraShake(DragonComp.AcidBeamCameraShake, this);

		UAdultDragonAcidBeamEventHandler::Trigger_BeamChargeStarted(Player);

		bBeamStarted = false;
		BeamTimer = 0.0;
		PuddleTimer = 0.0;

		HitTimer = 0.0;
		PreviousHitComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bIsFiringAcid = false;
		DragonComp.AnimParams.bIsShooting = false;
		//DragonComp.bUseStrafeMovement = false;
		Player.StopCameraShakeByInstigator(this, false);

		UAdultDragonAcidBeamEventHandler::Trigger_BeamStopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		BeamTimer += DeltaTime;

		bool bPreviousBeamStarted = bBeamStarted;
		if (!bBeamStarted && BeamTimer > AdultDragonAcidBeam::BeamAnticipationDelay)
		{
			bBeamStarted = true;
		}

		if (bBeamStarted)
		{
			DragonComp.AlterAcidAlpha(-AdultDragonAcidBeam::AcidReductionAmount * DeltaTime);

			FTransform TargetSocket = DragonComp.DragonMesh.GetSocketTransform(AdultDragonAcidBeam::ShootSocket);
			FVector BeamStart = TargetSocket.TransformPosition(AdultDragonAcidBeam::ShootSocketOffset);

			FAimingResult AimTarget = AimComp.GetAimingTarget(DragonComp);

			FHazeTraceSettings Trace;
			Trace.UseLine();
			Trace.TraceWithChannel(ECollisionChannel::WeaponTraceMio);
			Trace.IgnorePlayers();
			Trace.IgnoreActor(Owner);

			// Trace the aim line so we know what we're pointing at
			FVector AimCursorPoint = AimTarget.AimOrigin + AimTarget.AimDirection * AdultDragonAcidBeam::BeamLength * 2.0;
			FHitResult AimHit = Trace.QueryTraceSingle(AimTarget.AimOrigin, AimCursorPoint);

			FVector BeamDirection;
			if (AimHit.bBlockingHit)
			{
				BeamDirection = (AimHit.Location - BeamStart).GetSafeNormal();
			}
			else
			{
				FVector AimBeamStart = Math::ClosestPointOnLine(
					AimTarget.AimOrigin,
					AimCursorPoint,
					BeamStart
				);

				float DistanceToBeam = AimBeamStart.Distance(BeamStart);
				float DistanceToAimOrigin = AimBeamStart.Distance(AimTarget.AimOrigin);

				float AimLength = DistanceToAimOrigin;
				AimLength += Math::Sqrt(Math::Square(AdultDragonAcidBeam::BeamLength) + Math::Square(DistanceToBeam));

				FVector AimBeamEnd = AimTarget.AimOrigin + AimTarget.AimDirection * AimLength;
				BeamDirection = (AimBeamEnd - BeamStart).GetSafeNormal();
			}

			// Trace the beam line to see what we're actually hitting
			FVector BeamEnd = BeamStart + BeamDirection * AdultDragonAcidBeam::BeamLength;
			FHitResult BeamHit = Trace.QueryTraceSingle(BeamStart, BeamEnd);

			if (BeamHit.bBlockingHit)
				BeamEnd = BeamHit.Location;

			// Place puddles at a specific interval if we're hitting something
			PuddleTimer += DeltaTime;
			if (PuddleTimer >= AdultDragonAcidBeam::PuddlePlacementInterval)
			{
				PuddleTimer -= AdultDragonAcidBeam::PuddlePlacementInterval;
				if (BeamHit.bBlockingHit && DragonComp.PuddleClass.IsValid())
				{
					FAcidPuddleParams PuddleParams;
					PuddleParams.PuddleClass = DragonComp.PuddleClass;
					PuddleParams.Location = BeamHit.Location;
					PuddleParams.PuddleNormal = BeamHit.Normal;
					PuddleParams.Radius = AdultDragonAcidBeam::PuddleRadius;
					PuddleParams.Duration = AdultDragonAcidBeam::PuddleDuration;

					Acid::PlaceAcidPuddle(PuddleParams);
				}
			}

			// Generate hits in the response component when we hit something with the beam
			if (BeamHit.bBlockingHit && BeamHit.Actor != nullptr)
			{
				auto ResponseComp = UAcidResponseComponent::Get(BeamHit.Actor);
				if (ResponseComp != nullptr)
				{
					PreviousHitComponent = ResponseComp;
					PreviousHitParams.ImpactLocation = BeamHit.ImpactPoint;
					PreviousHitParams.ImpactNormal = BeamHit.Normal;
					PreviousHitParams.PlayerInstigator = Player;
				}
			}

			HitTimer -= DeltaTime;
			if (HitTimer < 0.0 && PreviousHitComponent != nullptr)
			{
				if(HasControl())
					PreviousHitComponent.CrumbActivateAcidHit(PreviousHitParams);
				PreviousHitComponent = nullptr;
				HitTimer = AdultDragonAcidBeam::AcidHitInterval;
			}

			// Update the effects for the beam
			FAdultDragonAcidBeamParams BeamParams;
			BeamParams.BeamStartLocation = BeamStart;
			BeamParams.BeamEndLocation = BeamEnd;
			BeamParams.bBeamHitSomething = BeamHit.bBlockingHit;

			if (!bPreviousBeamStarted)
				UAdultDragonAcidBeamEventHandler::Trigger_BeamStartedFiring(Player, BeamParams);
			else
				UAdultDragonAcidBeamEventHandler::Trigger_BeamLocationChanged(Player, BeamParams);
		}
	}
}
class UTazerBotTelescopeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);

	// Gotta update spline after PerchSpline capability has ticked,
	// player overshoots and hovers otherwise
	default TickGroup = EHazeTickGroup::Gameplay;

	ATazerBot TazerBot;

	UCameraSettings CameraSettings;

	float AcceleratedExtensionTarget;

	bool bPerchSplineEnabled;
	bool bNetExtending;
	bool bFullyExtended;

	// Original bone locations
	FVector BaseRelativeLocation;
	float ShaftOffset;
	float TipOffset;

	bool bTutorialCompleted = false;

	bool bCollisionInterruption = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);

		BaseRelativeLocation = TazerBot.MeshComponent.GetBoneLocationByName(n"Tazer1", EBoneSpaces::ComponentSpace) - TazerBot.MeshComponent.GetBoneLocationByName(n"Head", EBoneSpaces::ComponentSpace);
		ShaftOffset = (TazerBot.MeshComponent.GetBoneLocationByName(n"Tazer2", EBoneSpaces::ComponentSpace).X - BaseRelativeLocation.X);
		TipOffset = (TazerBot.MeshComponent.GetBoneLocationByName(n"Tazer3", EBoneSpaces::ComponentSpace).X - BaseRelativeLocation.X - ShaftOffset);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TazerBot.IsHacked())
			return false;

		if (!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return false;

		if (TazerBot.IsAirborne())
			return false;

		if (TazerBot.bDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility) && Math::IsNearlyZero(TazerBot.RodExtensionFraction, KINDA_SMALL_NUMBER))
			return true;

		if (TazerBot.bDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CameraSettings = UCameraSettings::GetSettings(TazerBot.HackingPlayer);

		bPerchSplineEnabled = true;
		bCollisionInterruption = false;
		TazerBot.SetPerchSplineEnabled(true);

		// TazerBot.ExtendTelescope();
		TazerBot.bExtended = true;

		TazerBot.HackingPlayer.BlockCapabilities(CameraTags::CameraControl, this);
		TazerBot.HackingPlayer.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TazerBot.SetPerchSplineEnabled(false);

		TazerBot.HackingPlayer.ClearCameraSettingsByInstigator(this, 1.0);
		CameraSettings = nullptr;

		// TazerBot.RetractTelescope();
		TazerBot.bExtended = false;

		TazerBot.HackingPlayer.UnblockCapabilities(CameraTags::CameraControl, this);
		TazerBot.HackingPlayer.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (ShouldExtend() && !bNetExtending)
				CrumbSetExtending(true);
			else if (!ShouldExtend() && bNetExtending)
				CrumbSetExtending(false);
		}

		if (bNetExtending)
		{
			TazerBot.SetPerchSplineEnabled(true);
		}
		else
		{
			TazerBot.SetPerchSplineEnabled(false);
		}

		float InterruptionMultiplier = WasInterrupted() ? TazerBot.Settings.CollisionInterruptionRetractionMultiplier : 1.0;

		float AccelerationTarget = bNetExtending ? 1.0 : 0.0;
		AcceleratedExtensionTarget = Math::FInterpTo(AcceleratedExtensionTarget, AccelerationTarget, DeltaTime, 6.0 * InterruptionMultiplier);
		float Speed = bNetExtending ? TazerBot.Settings.ExtendSpeed : TazerBot.Settings.RetractSpeed;
		TazerBot.RodExtensionFraction = Math::FInterpTo(TazerBot.RodExtensionFraction, AcceleratedExtensionTarget, DeltaTime, Speed * InterruptionMultiplier);

		const float Offset = TazerBot.Settings.ShaftLength / 3.0;

		FTransform TurretTransform = TazerBot.MeshComponent.GetBoneTransformByName(n"Head", EBoneSpaces::WorldSpace);
		const FVector BaseWorldLocation = TurretTransform.TransformPosition(BaseRelativeLocation);

		// We don't want tazer rod to pitch or roll
		FRotator TurretRotation = TurretTransform.Rotator();
		TurretRotation.Pitch = TurretRotation.Roll = 0;
		FVector TazerForwardVector = TurretRotation.Vector();

		// Base - inherit head bone transform
		float BaseExtensionMultiplier = Math::Saturate(TazerBot.RodExtensionFraction / 0.3);
		FVector BaseBoneLocation = BaseWorldLocation + TazerForwardVector * Offset * BaseExtensionMultiplier;
		TazerBot.MeshComponent.SetBoneLocationByName(n"Tazer1", BaseBoneLocation, EBoneSpaces::WorldSpace);

		// Shaft (giggity)
		float ShaftExtensionMultiplier = Math::Saturate(Math::Max(0.0, TazerBot.RodExtensionFraction - 0.33) / 0.3); // -0.4
		FVector ShaftBoneLocation = BaseBoneLocation + TazerForwardVector * (Offset * ShaftExtensionMultiplier + ShaftOffset);
		TazerBot.MeshComponent.SetBoneLocationByName(n"Tazer2", ShaftBoneLocation, EBoneSpaces::WorldSpace);

		// // (Just the) Tip
		float TipExtensionMultiplier = Math::Saturate(Math::Max(0.0, TazerBot.RodExtensionFraction - 0.66) / 0.2); // -0.8
		FVector TipBoneLocation = ShaftBoneLocation + TazerForwardVector * (Offset * TipExtensionMultiplier + TipOffset);
		TazerBot.MeshComponent.SetBoneLocationByName(n"Tazer3", TipBoneLocation, EBoneSpaces::WorldSpace);

		// Update rotation speed (used by movement capability)
		float TurretRotationSpeed = Math::Lerp(TazerBot.Settings.MaxTurretRotationSpeed, TazerBot.Settings.DeployedTurretRotationSpeed, Math::Pow(TazerBot.RodExtensionFraction, 1));
		UTazerBotSettings::SetCurrentTurretRotationSpeed(TazerBot, TurretRotationSpeed, this);

		// Compensate for rod radius and update spline
		FVector UpOffset = TazerBot.MovementWorldUp * 12.0;
		TazerBot.UpdateWorldSplinePoints(BaseWorldLocation + TazerForwardVector * 50.0 + UpOffset, TipBoneLocation - TazerForwardVector * 15.0 + UpOffset);

		// Check for fully extended fx event
		const float Tolerance = 0.133;
		if (bFullyExtended)
		{
			if (!Math::IsNearlyEqual(TazerBot.RodExtensionFraction, 1.0, Tolerance))
			{
				bFullyExtended = false;
			}
		}
		else
		{
			if (Math::IsNearlyEqual(TazerBot.RodExtensionFraction, 1.0, Tolerance))
			{
				bFullyExtended = true;
				UTazerBotEventHandler::Trigger_OnFullyExtended(TazerBot);
			}
		}

		UpdateTelescopeCollision(BaseWorldLocation, TipBoneLocation, TazerForwardVector, DeltaTime);
	}

	bool ShouldExtend() const
	{
		if (!TazerBot.IsHacked())
			return false;

		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		// Aberrations can occur, only take into account prolonged air
		if (TazerBot.IsAirborne() && TazerBot.MovementComponent.WasInAir())
			return false;

		if (WasInterrupted())
			return false;

		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetExtending(bool bValue)
	{
		bNetExtending = bValue;

		// Fire fx event
		if (bValue)
		{
			UTazerBotEventHandler::Trigger_OnExtending(TazerBot);
			if (!bTutorialCompleted)
			{
				bTutorialCompleted = true;
				TazerBot.HackingPlayer.RemoveTutorialPromptByInstigator(TazerBot);
				TazerBot.bTelescopeTutorialCompleted = true;
			}
		}
		else
			UTazerBotEventHandler::Trigger_OnRetracting(TazerBot);
	}

	void UpdateTelescopeCollision(FVector BaseLocation, FVector TipLocation, FVector TazerForwardVector, float DeltaTime)
	{
		UCapsuleComponent TelescopeCollision = TazerBot.PlayerTelescopeCollision;

		FVector ShaftMiddlePoint = (BaseLocation + TipLocation) * 0.5;
		TelescopeCollision.SetWorldLocation(ShaftMiddlePoint);

		float CapsuleHeight = BaseLocation.Distance(TipLocation) * 0.5;
		TelescopeCollision.SetCapsuleHalfHeight(CapsuleHeight);

		// Negate any pitch that comes from the transform parent
		FQuat RelativeRotation =  FQuat::MakeFromZ(TazerForwardVector);
		TelescopeCollision.SetWorldRotation(RelativeRotation);

		// Debug::DrawDebugCapsule(TelescopeCollision.WorldLocation, TelescopeCollision.CapsuleHalfHeight, TelescopeCollision.CapsuleRadius, TelescopeCollision.WorldRotation, FLinearColor::DPink, 5);

		// Now test for overlaps
		if (!bCollisionInterruption)
		{
			FHazeTraceSettings Trace = Trace::InitProfile(CollisionProfile::PlayerCharacter);
			Trace.UseCapsuleShape(TelescopeCollision.CapsuleRadius, TelescopeCollision.CapsuleHalfHeight, TelescopeCollision.ComponentQuat);
			Trace.IgnoreActor(TazerBot);
			Trace.IgnorePlayers();

			auto HitResults = Trace.QueryTraceMulti(TelescopeCollision.WorldLocation, TelescopeCollision.WorldLocation + TazerForwardVector * DeltaTime);
			for (auto HitResult : HitResults)
			{
				if (!HitResult.bBlockingHit)
					continue;

				if (HitResult.Component.HasTag(n"TazerBotAmicable"))
					continue;

				// Hard blocking collision yo!
				CollisionInterruption(HitResult);
				break;
			}
		}
	}

	void CollisionInterruption(const FHitResult& HitResult)
	{
		bCollisionInterruption = true;

		// Spawn thingy at collision location
		ForceFeedback::PlayWorldForceFeedback(TazerBot.TelescopeCollisionData.ForceFeedbackEffect, HitResult.ImpactPoint, false, this, TazerBot.Settings.ShaftLength);

		TazerBot.HackingPlayer.PlayCameraShake(TazerBot.TelescopeCollisionData.CameraShakeClass, this);

		// Only play camera shake if player is on telescope
		if (TazerBot.IsPlayePerchingOnTelescope(TazerBot.HackingPlayer.OtherPlayer))
			TazerBot.HackingPlayer.OtherPlayer.PlayCameraShake(TazerBot.TelescopeCollisionData.CameraShakeClass, this);

		// VFX!
		UTazerBotEventHandler::Trigger_OnTelescopeCollision(TazerBot, HitResult.ImpactPoint + FVector::UpVector * 20);
	}

	bool WasInterrupted() const
	{
		if (bCollisionInterruption)
			return true;
		
		if (TazerBot.bLaunched)
			return true;

		if (TazerBot.bDestroyed)
			return true;

		return false;
	}
}
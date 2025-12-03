class UIslandDroidZiplinePlayerHangCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"DroidZipline");

	default BlockExclusionTags.Add(n"DroidZipline");

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandDroidZiplinePlayerComponent DroidZiplineComp;
	UIslandDroidZiplineZiplineDestroyComponent DestroyComp;
	UIslandDroidZiplinePlayerSettings Settings;
	UIslandDroidZiplineSettings DroidSettings;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUser;

	float StartingDistanceToDestroyComponent;
	float TimeAttached;
	FHazeAcceleratedFloat AcceleratedDestroyCompAlpha;

	UCameraShakeBase CameraShakeInstance;
	FHazeAcceleratedFloat AcceleratedRightScale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroidZiplineComp = UIslandDroidZiplinePlayerComponent::Get(Player);
		Settings = UIslandDroidZiplinePlayerSettings::GetSettings(Player);
		DroidSettings = UIslandDroidZiplineSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DroidZiplineComp.bAttached)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DroidZiplineComp.bAttached)
			return true;

		if(DroidZiplineComp.CurrentDroidZipline.IsActorDisabled())
			return true;

		//if(WasActionStarted(ActionNames::Cancel))
		//	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Droid.Internal_OnPlayerAttach(Player);
		DestroyComp = UIslandDroidZiplineZiplineDestroyComponent::Get(Droid.ZiplineSpline);

		if(DestroyComp != nullptr)
		{
			StartingDistanceToDestroyComponent = DistanceToDestroyComp;
			AcceleratedDestroyCompAlpha.SnapTo(0.0);
		}

		FTransform ClosestTransform = Droid.ZiplineSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(Droid.ActorLocation);
		AcceleratedRightScale.SnapTo(ClosestTransform.Scale3D.Y);

		//Player.ShowCancelPrompt(this);
		Player.UnblockCapabilities(CapabilityTags::Death, DroidZiplineComp);
		Player.ShowTutorialPromptWorldSpace(DroidZiplineComp.TutorialPrompt, this, Droid.RootComponent, FVector(0, 0, -375));
		Player.AttachToActor(Droid, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Player.MeshOffsetComponent.AttachToComponent(Droid.Mesh, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepRelative, EAttachmentRule::KeepWorld, false);
		Player.SetActorVelocity(FVector::ZeroVector);
		MoveComp.AddMovementIgnoresActor(this, Droid);
		Player.ApplyCameraSettings(Droid.CameraSettings, 0.0, this, EHazeCameraPriority::VeryHigh);
		CameraShakeInstance = Player.PlayCameraShake(Droid.CameraShake, this, 1.0);
		TimeAttached = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DroidZiplineComp.CurrentTargetable.Enable(DroidZiplineComp);
		DroidZiplineComp.CurrentTargetable = nullptr;
		
		//Player.RemoveCancelPromptByInstigator(this);
		Player.RemoveTutorialPromptByInstigator(this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.MeshOffsetComponent.AttachToComponent(Player.RootOffsetComponent);
		MoveComp.RemoveMovementIgnoresActor(this);

		DroidZiplineComp.CurrentDroidZipline.bOccupied = false;
		DroidZiplineComp.CurrentDroidZipline.AttachedPlayer = nullptr;
		DroidZiplineComp.CurrentDroidZipline.Internal_OnPlayerDetach(Player);
		DroidZiplineComp.CurrentDroidZipline.UnblockCapabilities(CapabilityTags::Movement, DroidZiplineComp);
		Player.SetActorVelocity(DroidZiplineComp.CurrentDroidZipline.ActorVelocity);
		DroidZiplineComp.CurrentDroidZipline = nullptr;
		DroidZiplineComp.bAttached = false;
		DroidZiplineComp.AnimData.SidewaysTiltInput = 0.0;
		Player.UnblockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, DroidZiplineComp);
		Player.UnblockCapabilities(IslandRedBlueWeapon::IslandTargeting, DroidZiplineComp);
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, DroidZiplineComp);
		Player.UnblockCapabilities(n"Knockdown", DroidZiplineComp);
		Player.UnblockCapabilities(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade, DroidZiplineComp);
		Player.ClearCameraSettingsByInstigator(this, 0.5);
		// Player.StopCameraShakeByInstigator(this);
		Player.StopCameraShakeInstance(CameraShakeInstance);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector DroidSpaceInput = Droid.ActorTransform.InverseTransformVectorNoScale(MoveComp.MovementInput);
			Droid.CurrentTiltValue.Value = Math::FInterpTo(Droid.CurrentTiltValue.Value, DroidSpaceInput.Y, DeltaTime, Settings.ZiplineSidewaysInterpSpeed);
		}

		DroidZiplineComp.AnimData.SidewaysTiltInput = Droid.CurrentTiltValue.Value;

		FVector Delta;
		GetDroidSplineDelta(Delta, DeltaTime);
		HandleDroidRotation(Delta.GetSafeNormal(), DeltaTime);
		GetDroidSidewaysDelta(Delta, DeltaTime);

		if(DestroyComp != nullptr)
		{
			float TargetAlpha = Math::GetMappedRangeValueClamped(FVector2D(StartingDistanceToDestroyComponent, 0.0), FVector2D(0.0, 1.0), DistanceToDestroyComp);
			AcceleratedDestroyCompAlpha.AccelerateTo(TargetAlpha, 0.5, DeltaTime);
			Player.ApplyManualFractionToCameraSettings(AcceleratedDestroyCompAlpha.Value, this);

			if(CameraShakeInstance != nullptr)
				CameraShakeInstance.ShakeScale = AcceleratedDestroyCompAlpha.Value;
		}

		// When hitting wall
		if(HasControl() && (Droid.MoveWillResultInFatalImpact(Delta)))
		{
			Player.ApplyKnockdown(-Droid.ActorForwardVector * 200);
		}
		
		// When falling off at end or hitting wall
		if(HasControl() && (Droid.MoveWillResultInFatalImpact(Delta) || HasPassedDestroyComp()))
		{
			Player.PlayCameraShake(DroidZiplineComp.CrashCamShake, this);
			Player.PlayForceFeedback(DroidZiplineComp.CrashFF, false, false, this);
			Player.SetMovementFacingDirection(Droid.ActorForwardVector);
			Droid.KillDroid();
		}

		Droid.ActorLocation += Delta;
		Droid.SetActorVelocity(Delta / DeltaTime);

		float FFStrength = 0.4;
		float GameTime = Time::GetGameTimeSeconds();

		float LeftFFAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, -1), FVector2D(0, 1), Droid.CurrentTiltValue.Value);
		float LeftFF = Math::Sin(GameTime * 55.0) * FFStrength * LeftFFAlpha;
		float RightFFAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(0.1, 1), Droid.CurrentTiltValue.Value);
		float RightFF = Math::Sin(-GameTime * 55.0) * FFStrength * 4 * RightFFAlpha;

		Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);

		if(Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"DroneHang", this);

		if(Time::GetGameTimeSince(TimeAttached) > 3.5)
		{
			Player.RemoveTutorialPromptByInstigator(this);
		}
	}

	AIslandDroidZipline GetDroid() const property
	{
		return DroidZiplineComp.CurrentDroidZipline;
	}

	void GetDroidSplineDelta(FVector& Delta, float DeltaTime)
	{
		Droid.CurrentSplineSpeed += DroidSettings.PatrolToZiplineAcceleration * DeltaTime;
		Droid.CurrentSplineSpeed = Math::Min(Droid.CurrentSplineSpeed, DroidSettings.ZiplineSpeed);

		Droid.CurrentSplineDistance += Droid.CurrentSplineSpeed * DeltaTime;
		FTransform TargetTransform = Droid.ZiplineSpline.Spline.GetWorldTransformAtSplineDistance(Droid.CurrentSplineDistance);
		FVector TargetLocation = TargetTransform.Location;

		if(Droid.CurrentSplineDistance > Droid.ZiplineSpline.Spline.SplineLength)
		{
			float RemainingDistance = Droid.CurrentSplineDistance - Droid.ZiplineSpline.Spline.SplineLength;
			TargetLocation += TargetTransform.Rotation.ForwardVector * RemainingDistance;
		}

		FVector DroidLocationMinusSidewaysMovement = Droid.ActorLocation - Droid.PreviousSidewaysWorldOffset;
		
		FVector NextLocation = Math::VInterpConstantTo(DroidLocationMinusSidewaysMovement, TargetLocation, DeltaTime, Droid.CurrentSplineSpeed);

		Delta = (NextLocation - DroidLocationMinusSidewaysMovement);
	}

	void HandleDroidRotation(FVector TargetForward, float DeltaTime)
	{
		FQuat CurrentTargetRotation = FQuat::MakeFromZX(FVector::UpVector.RotateAngleAxis(DroidSettings.ZiplineSidewaysRollDegrees * -Droid.CurrentTiltValue.Value, TargetForward), TargetForward);
		Droid.ActorRotation = Math::RInterpShortestPathTo(Droid.ActorRotation, CurrentTargetRotation.Rotator(), DeltaTime, DroidSettings.SplineRotationInterpSpeed);
	}

	void GetDroidSidewaysDelta(FVector& Delta, float DeltaTime)
	{
		// Reset previous sideways world offset, easier this way to make everything correct for instance when spline turns etc.
		Delta -= Droid.PreviousSidewaysWorldOffset;

		FTransform ClosestTransform = Droid.ZiplineSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(Droid.ActorLocation);
		AcceleratedRightScale.AccelerateTo(ClosestTransform.Scale3D.Y, 0.5, DeltaTime);
		const float CurrentSidewaysAlpha = Math::Abs(Droid.SidewaysDistance.Value) / (Droid.ZiplineSpline.MaxSidewaysDistance * AcceleratedRightScale.Value);
		const float CurrentSpeedMultiplier = Droid.ZiplineSpline.SidewaysSpeedCurve.GetFloatValue(CurrentSidewaysAlpha);
		float CurrentSidewaysSpeed = DroidSettings.ZiplineSidewaysSpeed * CurrentSpeedMultiplier;

		// If trying to steer back towards the center we should use max speed.
		if(Math::Sign(Droid.CurrentTiltValue.Value) != Math::Sign(Droid.SidewaysDistance.Value))
			CurrentSidewaysSpeed = DroidSettings.ZiplineSidewaysSpeed;
		
		FVector RightNoHeight = Droid.ActorRightVector.GetSafeNormal2D();
		if(HasControl())
		{
			Droid.SidewaysDistance.Value += CurrentSidewaysSpeed * Droid.CurrentTiltValue.Value * DeltaTime;
			Droid.SidewaysDistance.Value = Math::Clamp(Droid.SidewaysDistance.Value, -Droid.ZiplineSpline.MaxSidewaysDistance * AcceleratedRightScale.Value, Droid.ZiplineSpline.MaxSidewaysDistance * AcceleratedRightScale.Value);
		}
		FVector SidewaysWorldOffset = RightNoHeight * Droid.SidewaysDistance.Value;

		Delta += SidewaysWorldOffset;
		Droid.PreviousSidewaysWorldOffset = SidewaysWorldOffset;
	}

	float GetDistanceToDestroyComp() const property
	{
		if(DestroyComp == nullptr)
			return -1.0;

		float Dist = Droid.ZiplineSpline.Spline.GetClosestSplineDistanceToWorldLocation(Droid.ActorLocation);
		return DestroyComp.DistanceOnSpline - Dist;
	}

	bool HasPassedDestroyComp()
	{
		if(DestroyComp == nullptr)
			return false;

		float Dist = Droid.ZiplineSpline.Spline.GetClosestSplineDistanceToWorldLocation(Droid.ActorLocation);
		if(Dist < DestroyComp.DistanceOnSpline)
			return false;

		return true;
	}
}
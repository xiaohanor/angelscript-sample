class USlingshotKitePlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(KiteTags::Kite);
	default CapabilityTags.Add(KiteTags::ZipKite);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	UPlayerMovementComponent MoveComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerGrappleComponent GrappleComp;

	USlingshotKitePlayerComponent SlingshotKitePlayerComp;
	ASlingshotKite Kite;
	USlingshotKiteGrapplePointComponent SlingshotGrappleComp;

	bool bJumped = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlingshotKitePlayerComp = USlingshotKitePlayerComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bEnterFinished || GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::KiteTown_SlingshotPoint)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SlingshotKitePlayerComp.CurrentKite == nullptr)
			return true;

		if (bJumped)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bJumped = false;

		SlingshotGrappleComp = Cast<USlingshotKiteGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		Kite = Cast<ASlingshotKite>(SlingshotGrappleComp.Owner);
		SlingshotKitePlayerComp.CurrentKite = Kite;

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(n"ContextualMoves", this);

		SpeedEffect::RequestSpeedEffect(Player, 1.0, this, EInstigatePriority::High);

		Player.PlayCameraShake(SlingshotKitePlayerComp.ConstantCamShake, this);

		/*Player.PlaySlotAnimation(Animation = SlingshotKitePlayerComp.EnterAnim, BlendTime = 0.1);
		Timer::SetTimer(this, n"ActivateBlendSpace", 0.3);

		UHazeCameraSpringArmSettingsDataAsset CamSettings = Kite.CamSettingsOverride == nullptr ? SlingshotKitePlayerComp.CamSettings : Kite.CamSettingsOverride;
		Player.ApplyCameraSettings(CamSettings, 0.5, this);

		Kite.OnPlayerAttached.Broadcast(Player);*/

		Player.AttachToComponent(Kite.RotorRoot, NAME_None, EAttachmentRule::KeepWorld);

		Player.ActivateCamera(Kite.CameraComp, 1.0, this, EHazeCameraPriority::High);
		Player.PlayBlendSpace(SlingshotKitePlayerComp.BlendSpace, 0.2, EHazeBlendType::BlendType_Crossfade, StartPosition = -0.75);

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::MovementJump;
		TutorialPrompt.Text = Kite.TutorialText;
		Player.ShowTutorialPrompt(TutorialPrompt, this);
	}

	UFUNCTION()
	void ActivateBlendSpace()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(n"ContextualMoves", this);
		
		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.StopCameraShakeByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);

		Player.StopBlendSpace();
		Player.StopSlotAnimation();

		Player.ClearCameraSettingsByInstigator(this, 1.0);

		Player.ResetMovement(true);

		// Kite.OnPlayerDetached.Broadcast(Player);

		FVector DirToPlayer = (Player.ActorLocation - Kite.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FVector LaunchDir = -DirToPlayer.CrossProduct(Kite.ActorUpVector);
		if (Kite.bAlwaysLaunchForward)
			LaunchDir = Kite.ActorForwardVector.ConstrainToPlane(Kite.ActorUpVector).GetSafeNormal();
		Player.AddMovementImpulse(LaunchDir * Kite.LaunchForce);

		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.5);
		Player.SetMovementFacingDirection(LaunchDir);

		Player.DeactivateCamera(Kite.CameraComp);

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpTo(Player.ActorRelativeLocation, FVector(500.0, 0.0, -500.0), DeltaTime, 8.0);
		Player.SetActorRelativeLocation(Loc);

		float BSValue = (Math::Sin(Time::GameTimeSeconds * 4.0));
		Player.SetBlendSpaceValues(0.0, BSValue);

		FVector RopeAttachLoc = Kite.GrapplePointComp.WorldLocation;
		DebugDrawTether(RopeAttachLoc);

		FVector DirToPlayer = (Player.ActorLocation - Kite.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);

		FRotator MeshRot;
		MeshRot = DirToPlayer.Rotation();
		MeshRot.Yaw += 90.0;
		MeshRot.Roll = 90.0;
		Player.MeshOffsetComponent.SnapToRotation(this, MeshRot.Quaternion());

		if (WasActionStarted(ActionNames::MovementJump))
			bJumped = true;
	}

	void DebugDrawTether(FVector AttachLoc)
	{
		FLinearColor TetherColor = FLinearColor(0.15, 0.10, 0.10);
		Debug::DrawDebugLine(AttachLoc, Player.Mesh.GetSocketLocation(n"LeftAttach"), TetherColor, 3.0);		
		Debug::DrawDebugLine(Player.Mesh.GetSocketLocation(n"LeftAttach"), Player.Mesh.GetSocketLocation(n"RightAttach"), TetherColor, 3.0);		
		Debug::DrawDebugLine(Player.Mesh.GetSocketLocation(n"RightAttach"), Player.Mesh.GetSocketLocation(n"Hips"), TetherColor, 3.0);	
	}
}
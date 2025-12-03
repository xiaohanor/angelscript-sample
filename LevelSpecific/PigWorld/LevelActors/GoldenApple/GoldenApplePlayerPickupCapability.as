class UGoldenApplePlayerPickupCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// Gotta tick after air movement
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 201;

	default DebugCategory = PigTags::Pig;

	UGoldenApplePlayerComponent GoldenApplePlayerComp;
	UPlayerPigComponent PigComp;
	UPlayerMovementComponent PlayerMovementComp;
	USimpleMovementData MoveData;

	bool bIsLerpingTowardsApple = false;
	bool bStartedAnimation = false;
	float AttachAppleTimestamp = BIG_NUMBER;
	FVector PickupStartLocation;
	FVector PickupTargetLocation;
	FVector StartAppleLocation;
	FVector GroundedAppleLocation;
	FQuat PickupStartRotation;
	FQuat PickupTargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GoldenApplePlayerComp = UGoldenApplePlayerComponent::Get(Player);
		PlayerMovementComp = UPlayerMovementComponent::Get(Player);
		MoveData = PlayerMovementComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GoldenApplePlayerComp.CurrentApple == nullptr)
			return false;

		if (GoldenApplePlayerComp.bIsCarryingApple)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GoldenApplePlayerComp.CurrentApple == nullptr)
			return true;

		if (ActiveDuration > Pig::GoldenApple::PickupAnimationDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (PigComp == nullptr) // PigComp gets added post Setup?
			PigComp = UPlayerPigComponent::Get(Player);
		
		AHazeActor CurrentApple = GoldenApplePlayerComp.CurrentApple;

		bIsLerpingTowardsApple = true;
		bStartedAnimation = false;
		AttachAppleTimestamp = BIG_NUMBER;

		PickupStartLocation = Player.GetActorLocation();
		PickupStartRotation = Player.GetActorQuat();

		StartAppleLocation = CurrentApple.GetActorLocation();
		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
		Trace.IgnorePlayers();
		Trace.SetTraceComplex(true);
		FVector Start = StartAppleLocation;
		FVector End = StartAppleLocation + Player.GetMovementWorldUp() * -1.0 * 100.0; 
		FHitResult HitResult = Trace.QueryTraceSingle(Start, End);

 		// make sure apple is on ground, so pig doesn't interpolate into air and falls
		GroundedAppleLocation = HitResult.ImpactPoint + HitResult.ImpactNormal * 0.01;

		FVector SocketAlignLocation = Player.Mesh.GetSocketLocation(GoldenApplePlayerComp.AttachNodeName);
		if (Player.Mesh.DoesSocketExist(GoldenApplePlayerComp.AlignmentNodeName))
			SocketAlignLocation = Player.Mesh.GetSocketLocation(GoldenApplePlayerComp.AlignmentNodeName);

		FVector SocketOffset = PickupStartLocation - SocketAlignLocation;
		FVector CurrentToTarget = GroundedAppleLocation - PickupStartLocation;
		PickupTargetLocation = GroundedAppleLocation - CurrentToTarget.GetSafeNormal() * SocketOffset.Size();
		CurrentToTarget.Z = 0;
		PickupTargetRotation = FQuat::MakeFromXZ( CurrentToTarget.GetSafeNormal(), Player.GetActorUpVector());

		Player.ResetMovement();

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TListedActors<AHungryDoor> HungryDoors;
		for (AHungryDoor Door : HungryDoors)
		{
			Door.DisableInteractionForPlayer(Player);
		}

		bIsLerpingTowardsApple = false;
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		GoldenApplePlayerComp.bIsCarryingApple = true;

		// Feels so nastay 😭 but no other thing will request shiet until next frame
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"Movement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) 
	{
		if (ActiveDuration < Pig::GoldenApple::PickupAlignDuration)
		{
			PrepareAlignmentForAnimation();
		}

		if (!bStartedAnimation)
		{
			StartPickupAnimation();
		}
		else if (AttachAppleTimestamp < Time::GameTimeSeconds)
		{
			AttachAppleTimestamp = BIG_NUMBER;
			if (GoldenApplePlayerComp.CurrentApple != nullptr)
				GoldenApplePlayerComp.CurrentApple.AttachToComponent(Player.Mesh, GoldenApplePlayerComp.AttachNodeName, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		}

		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"Movement", this);
	}

	private void PrepareAlignmentForAnimation()
	{
		const float InterpolationDuration = Pig::GoldenApple::PickupAlignDuration;
		const float Interpolation = Math::EaseInOut(0, 1, Math::Clamp(ActiveDuration / InterpolationDuration, 0, 1), 2);

		if (PlayerMovementComp.PrepareMove(MoveData))
		{
			if (HasControl())
			{

				FVector InterpolatedLocation = Math::Lerp(PickupStartLocation, PickupTargetLocation, Interpolation);			
				FQuat InterpolatedRotation = FQuat::Slerp(PickupStartRotation, PickupTargetRotation, Interpolation);

				FVector Delta = InterpolatedLocation - Owner.ActorLocation;
				MoveData.AddDelta(Delta);
				MoveData.SetRotation(InterpolatedRotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			PlayerMovementComp.ApplyMove(MoveData);
		}

		UpdateAppleScale(Interpolation);
	}

	private void StartPickupAnimation()
	{
		bStartedAnimation = true;
		UAnimSequence PickUpAnimation = GoldenApplePlayerComp.AnimationData[Player].PickupAnimation;
		if (PickUpAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams Params;
			Params.Animation = PickUpAnimation;
			Params.BlendTime = 0.2;
			Params.BlendOutTime = 0.0;
			Player.PlaySlotAnimation(Params);
			AttachAppleTimestamp = Time::GameTimeSeconds + 0.2;
		}

		// Immediately start playing override
		FHazePlayOverrideAnimationParams OverrideAnimationParams;
		OverrideAnimationParams.bLoop = true;
		OverrideAnimationParams.BoneFilterAsset = GoldenApplePlayerComp.AnimationData[Player].CarryJawFilter;
		OverrideAnimationParams.Animation = GoldenApplePlayerComp.AnimationData[Player].CarryJawOverrideAnimation;
		OverrideAnimationParams.BlendTime = 0.;
		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), OverrideAnimationParams);

		// Play same animation in spring mesh
		UPlayerPigStretchyLegsComponent StretchyPigComponent = UPlayerPigStretchyLegsComponent::Get(Player);
		if (StretchyPigComponent != nullptr)
			if (StretchyPigComponent.SpringyMeshComponent != nullptr)
				StretchyPigComponent.SpringyMeshComponent.PlayOverrideAnimation(FHazeAnimationDelegate(), OverrideAnimationParams);

		GoldenApplePlayerComp.bPlayingCarryingAnimation = true;
	}

	private void UpdateAppleScale(const float Interpolation)
	{
		float AppleScale = Math::Lerp(1.0, 0.5, Math::Square(Interpolation));
		FVector AppleInterpolatedLocation = Math::Lerp(StartAppleLocation, GroundedAppleLocation, Interpolation);
		GoldenApplePlayerComp.CurrentApple.SetActorLocation(AppleInterpolatedLocation);
		GoldenApplePlayerComp.CurrentApple.SetActorScale3D(FVector::OneVector * AppleScale);
	}
}
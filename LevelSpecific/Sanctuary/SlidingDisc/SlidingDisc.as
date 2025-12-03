asset SlidingDiscSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USlidingDiscPlayerInputCapability);
	Components.Add(USlidingDiscPlayerComponent);
}

asset SlidingDiscActorSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USlidingDiscMovementSlidingCapability);
	Capabilities.Add(USlidingDiscMovementBoatCapability);
	Capabilities.Add(USlidingDiscAmbientMovementCapability);
	Capabilities.Add(USlidingDiscEffectsCapability);
	Capabilities.Add(USlidingDiscEatenDeathCapability);
	Capabilities.Add(USlidingDiscAutoDeathCapability);
	Capabilities.Add(USlidingDiscGrindOnHydraCapability);
	Capabilities.Add(USlidingDiscDestroyCapability);
	
	// Capabilities.Add(USlidingDiscLerpToGrindOnHydraCapability);
}

event void FSanctuarySlideEvent();

UCLASS(HideCategories = "InternalHiddenObjects")
class ASlidingDisc : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	default MovementComponent.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent DebugTransformComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(SlidingDiscActorSheet);

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent WorldCollision;

	UPROPERTY(DefaultComponent, Attach = WorldCollision)
	UDynamicWaterEffectDecalComponent DynamicWaterEffectDecalComp;
	default DynamicWaterEffectDecalComp.Strength = 5.0;
	default DynamicWaterEffectDecalComp.RelativeScale3D = FVector::OneVector * 3.0;
	default DynamicWaterEffectDecalComp.bCircle = true;
	default DynamicWaterEffectDecalComp.Contrast = 512;
	default DynamicWaterEffectDecalComp.bEnabled = false;

	UPROPERTY(DefaultComponent, Attach = WorldCollision)
	USceneComponent BasePivot;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	UNiagaraComponent WaterRim;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	UPlayerInheritMovementComponent InheritMovementComp;
	default InheritMovementComp.Shape.Type = EHazeShapeType::Sphere;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	UNiagaraComponent TrailVFX;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USceneComponent CameraFocusTarget;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USpringArmCamera Camera;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USpringArmCamera EatenCamera;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent DiscMesh;

	UPROPERTY(DefaultComponent, Attach = DiscMesh)
	UStaticMeshComponent WalkOffBlocker;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UDarkPortalForceAnchorComponent ForceAnchorComp;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USanctuaryFloatingSceneComponent FloatComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DestroyedVFX;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem WaterSplashVFX;
	bool bSplashOnce = true;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent, Attach = DiscMesh)
	USceneComponent PlayerAttachementRoot;
	UPROPERTY(DefaultComponent, Attach = PlayerAttachementRoot)
	USceneComponent PlayerAttachementMio;

	UPROPERTY(DefaultComponent, Attach = PlayerAttachementRoot)
	USceneComponent PlayerAttachementZoe;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;
	default DarkPortalResponseComp.bAllowMultiComponentGrab = true;
	default DarkPortalResponseComp.PullForce = 1000.0;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent BecomeBoatActionComp;
	FVector StartMeshRelativeOffset;
	FVector StartPivotRelativeOffset;
	FQuat StartPivotRotation;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.0;

	// -- end of comps

	// SLIDING DISC THINGS
	UPROPERTY(EditAnywhere, Category = "Camera")
	TSubclassOf<UCameraShakeBase> LightCollisionCameraShake;
	TArray<USlidingDiscPlayerComponent> PlayerComponents;
	FHazeAcceleratedQuat AccPivotRot;
	FHazeAcceleratedFloat AccRollRot;

	ADiscSlideHydra GrindingOnHydra = nullptr;
	float GrindHopOffDistance = 0.0;
	bool bHasHoppedOnGrinding = false;

	bool bIsSliding = false;
	bool bLanded = false;
	bool bDisintegrated = false;

	FVector SlidingGravity = FVector::UpVector * -980.0;
	float Lean = 0.0;
	float SlidingDrag = 0.2;
	FVector BoostForce = FVector::ZeroVector;

	float SlidingDiscMaxLeanDegrees = 30.0;
	float InAirDuration = 0.0;
	FTransform InitialTransform;

	// BOAT THINGS
	bool bIsBoating = false;

	ADarkPortalActor DarkPortal;
	FVector Velocity;
	FVector AngularVelocity;
	float AngularDrag = 2.0;
	float BoatDrag = 1.0;
	
	FVector AccumulatedImpulse;
	FVector AccumulatedAngularImpulse;

	FSanctuarySlideEvent OnBecomeVisualBoatThanks;

	FVector BoatGravity = -FVector::UpVector * 980.0 * 3.0;
	UPROPERTY(EditAnywhere, Category = "Boat")
	float BoatRadius = 225.0;
	UPROPERTY(EditAnywhere, Category = "Boat")
	float GrabDistance = 2000.0;
	UPROPERTY(EditAnywhere, Category = "Boat")
	int GrabTargets = 5;
	UPROPERTY(EditAnywhere, Category = "Boat")
	float GrabTargetsSpreadAngle = 10.0;
	UPROPERTY(EditAnywhere, Category = "Boat")
	float GrabTargetsInset = 30.0;
	UPROPERTY(EditAnywhere, Category = "Boat")
	float PlayerWeight = 200.0;
	UPROPERTY(EditAnywhere, Category = "Boat")
	float PlayerTorqueScale = 2.0;
	UPROPERTY(EditAnywhere, Category = "Boat")
	float PlayerImpulseScale = 0.1;
	UPROPERTY(EditAnywhere, Category = "Boat")
	float BuoyantScale = 1.0;
	UPROPERTY(EditAnywhere, Category = "Boat")
	ASlidingDiscBecomeBoatVolume WaterHeightRef = nullptr;

	TArray<AHazePlayerCharacter> ImpactingPlayers;
	ASanctuaryBoat IgnoreCollisionBoat = nullptr;

	float CameraBlendDuration = 0.0;
	bool bLongPOIUsed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		SetActorControlSide(Game::Zoe);
		InitialTransform = ActorTransform;
	
		DiscMesh.AddComponentCollisionBlocker(this);
		// Setup the resolver
		{	
			UMovementResolverSettings::SetMaxRedirectIterations(this, 4, this, EHazeSettingsPriority::Defaults);
			UMovementResolverSettings::SetMaxDepenetrationIterations(this, 2, this, EHazeSettingsPriority::Defaults);
		}

		// Override the gravity settings
		{
			UMovementGravitySettings::SetGravityScale(this, 3, this, EHazeSettingsPriority::Defaults);
		}

		// Everything is sliding
		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 70.0, this, EHazeSettingsPriority::Defaults);
		}

		if (WaterHeightRef != nullptr)
			WaterHeightRef.OnActorBeginOverlap.AddUFunction(this, n"EnterWaterCallback");

		WaterRim.Deactivate();
		CreateGrabTargets();
		SlidingDiscDevToggles::SlidingDiscCategory.MakeVisible();
	}

	UFUNCTION(BlueprintCallable)
	void RemoveStartDisabled()
	{
		this.RemoveActorDisable(FInstigator(n"StartDisabled"));
	}

	UFUNCTION()
	private void EnterWaterCallback(AActor OverlappedActor, AActor OtherActor)
	{
		TempDoWaterSplashed();
		EnableDiscCollision();
		//CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		WaterHeightRef.OnActorBeginOverlap.Unbind(this, n"EnterWaterCallback");
		StarBoatyThings();
		bIsSliding = false;
		StartMeshRelativeOffset = DiscMesh.RelativeLocation;
		StartPivotRelativeOffset = BasePivot.RelativeLocation;
		StartPivotRotation = BasePivot.WorldRotation.Quaternion();
		BecomeBoatActionComp.Duration(4.0, this, n"LerpMeshUpwards");
		BecomeBoatActionComp.Event(this, n"StopSlidyThings");
		
	}

	UFUNCTION(BlueprintEvent)
	void TempDoWaterSplashed()
	{	
	}

	void HandleCameraShakeAndForceFeedback()
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION(BlueprintCallable)
	void EnableDiscCollision()
	{
		DiscMesh.RemoveComponentCollisionBlocker(this);
	}


	UFUNCTION()
	private void LerpMeshUpwards(float Alpha)
	{
		BasePivot.SetRelativeLocation(Math::Lerp(StartPivotRelativeOffset, FVector(), Alpha));
		FRotator TheRot = FRotator::MakeFromEuler(FVector(0.0, 0.0, StartPivotRotation.Rotator().Yaw));
		BasePivot.SetWorldRotation(FQuat::Slerp(StartPivotRotation, TheRot.Quaternion(), Alpha));
		DiscMesh.SetRelativeLocation(Math::Lerp(StartMeshRelativeOffset, FVector(), Alpha));
	}

	private void StarBoatyThings()
	{
		bIsBoating = true;
		WaterRim.Activate();
		TrailVFX.Deactivate();
		DynamicWaterEffectDecalComp.bEnabled = true;
		
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");		
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");		
		DarkPortalResponseComp.OnAttached.AddUFunction(this, n"HandlePortalAttached");
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpactBegin");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandlePlayerImpactEnd");
		OnBecomeVisualBoatThanks.Broadcast();

		TArray<UPrimitiveComponent> Primitives;
		GetComponentsByClass(Primitives);

		for (auto Primitive : Primitives)
			Primitive.SetShadowPriorityRuntime(EShadowPriority::GameplayElement);
	}

	UFUNCTION()
	private void StopSlidyThings()
	{
		BecomeBoatActionComp.SetPaused(true);

		bIsSliding = false;

		// Disable fullscreen and slide camera
		//Game::Mio.ClearViewSizeOverride(this);
		Game::Mio.DeactivateCamera(Camera, 2.0);
		//Game::Mio.ClearPointOfInterestByInstigator(this);

		// // Disable collision on sphere
		// WorldCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		for (auto Player : Game::Players)
		{
			Player.DetachFromActor(EDetachmentRule::KeepWorld);
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			Player.UnblockCapabilities(n"Respawn", this);

			Outline::ClearOutlineOnActor(Player, Player.OtherPlayer, this);

			USlidingDiscPlayerComponent SlidingDiscPlayerComponent = USlidingDiscPlayerComponent::Get(Player);
			SlidingDiscPlayerComponent.bIsSliding = bIsSliding;
			RequestComponent.StopInitialSheetsAndCapabilities(Player, this);
		}
	}

	void DisintegrateHahahaha()
	{
		bDisintegrated = true;
		Game::Mio.KillPlayer();
		Game::Zoe.KillPlayer();
		if (DestroyedVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DestroyedVFX, ActorLocation);
	}

	UFUNCTION(BlueprintEvent)
	void BP_TurnOffTorches(){}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float MaxBlend = 5.0;
		CameraBlendDuration = Math::Clamp(CameraBlendDuration + DeltaSeconds, 0.0, MaxBlend);
		if (bIsSliding && !bLongPOIUsed && CameraBlendDuration >= MaxBlend - KINDA_SMALL_NUMBER)
			LateSlidingPOI();

		if (bIsBoating)
			UpdateBoatyThings(DeltaSeconds);
		else if (bIsSliding)
			UpdateSlidyThings(DeltaSeconds);

		if (SlidingDiscDevToggles::DrawBoat.IsEnabled())
			DrawDebugBoat();
		if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
			DrawDebugDisc();
	}

	private void DrawDebugDisc()
	{
		for (auto Player : Game::Players)
		{
			Debug::DrawDebugCoordinateSystem(Player.ActorLocation, Player.ActorRotation, 100.0, 4.0, 0.0, true);
		}
		
		ColorDebug::DrawForward(PlayerAttachementMio.WorldLocation, PlayerAttachementMio.WorldRotation, ColorDebug::Magenta, 150.0);
		ColorDebug::DrawForward(PlayerAttachementZoe.WorldLocation, PlayerAttachementZoe.WorldRotation, ColorDebug::Magenta, 150.0);
		ColorDebug::DrawForward(DiscMesh.WorldLocation, DiscMesh.WorldRotation, ColorDebug::Yellow, 160.0);
		ColorDebug::DrawForward(Pivot.WorldLocation, Pivot.WorldRotation, ColorDebug::Cyan, 170.0);
		ColorDebug::DrawForward(BasePivot.WorldLocation, BasePivot.WorldRotation, ColorDebug::Lavender, 180.0);
		ColorDebug::DrawForward(RootComponent.WorldLocation, RootComponent.WorldRotation, ColorDebug::Rose, 190.0);
	}

	private void UpdateBoatyThings(float DeltaSeconds)
	{
		UpdateGrabTargetLocation();
		
		float HeightAboveWater = Math::Saturate((ActorLocation.Z - GetWaterHeight() - 50) / 50);
		HeightAboveWater += Math::Sin(Time::GameTimeSeconds * 5.0) * 0.1;

		DynamicWaterEffectDecalComp.Strength = Math::Lerp(3.0, 8.0, HeightAboveWater);
		DynamicWaterEffectDecalComp.RelativeScale3D  = FVector::OneVector * Math::Lerp(2.0, 4.0, HeightAboveWater);

		// DrawDebug();
	}

	private void UpdateSlidyThings(float DeltaSeconds)
	{
		Lean = 0.0;
		for (auto PlayerComponent : PlayerComponents)
		{
			Lean += PlayerComponent.Lean.Value * 0.5;
#if EDITOR
			if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
			{
				FString PlayerLeanName = PlayerComponent.Owner.GetName() + " Lean";
				TEMPORAL_LOG(this, "Sliding").Value(PlayerLeanName, PlayerComponent.Lean);
			}
#endif
		}

		/* DEV SOLO STEERING */
		if (SlidingDiscDevToggles::SoloSteering.IsEnabled())
		{
			PrintToScreenScaled("Dev Solo Steering Enabled", 0.0, FLinearColor::Red, 3.0);
			Lean = 0.0;
			for (auto PlayerComponent : PlayerComponents)
				Lean += PlayerComponent.Lean.Value * 1.0;
		}

		Lean *= Math::Abs(Lean);
		Pivot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(Pivot.RelativeRotation.Roll, Lean * SlidingDiscMaxLeanDegrees, 3.0 * DeltaSeconds)));

		if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
		{
			PrintToScreen("Lean:" + Lean, 0.0, FLinearColor::Green);
#if EDITOR
			TEMPORAL_LOG(this, "Sliding").Value("Disc Lean", Lean);
#endif
		}

		UpdateLandingVariables(DeltaSeconds);
	}

	private void UpdateLandingVariables(float DeltaSeconds)
	{
		if (bLanded)
		{
			bLanded = false;
			for (auto PlayerComponent : PlayerComponents)
			{
				PlayerComponent.bIsLanding = bLanded;
			}
		}

		for (auto PlayerComponent : PlayerComponents)
		{
			PlayerComponent.LandedImpactStrength -= DeltaSeconds * 0.8;
			if (PlayerComponent.LandedImpactStrength < 0.0)
				PlayerComponent.LandedImpactStrength = 0.0;

			PlayerComponent.HorizontalLandedImpactStrength -= DeltaSeconds * 0.8;
			if (PlayerComponent.HorizontalLandedImpactStrength < 0.0)
				PlayerComponent.HorizontalLandedImpactStrength = 0.0;

			if (MovementComponent.IsInAir())
				InAirDuration += DeltaSeconds;
			else
				InAirDuration = 0.0;

			if (InAirDuration > 0.1)
				PlayerComponent.VerticalAirVelocity = MovementComponent.VerticalVelocity.Z;
			else
				PlayerComponent.VerticalAirVelocity = 0.0;
		}

		if (!MovementComponent.IsInAir() && MovementComponent.WasInAir())
		{
			float VelocityGroundDot = MovementComponent.PreviousVelocity.GetSafeNormal().DotProduct(MovementComponent.GroundContact.Normal);

			if (VelocityGroundDot < -0.2 && MovementComponent.PreviousVelocity.Size() > 2000.0)
			{
				bLanded = true;
				for (auto PlayerComponent : PlayerComponents)
				{
					PlayerComponent.bIsLanding = bLanded;
					PlayerComponent.LandedImpactStrength = Math::Clamp(Math::NormalizeToRange(Math::Abs(VelocityGroundDot) * MovementComponent.PreviousVelocity.Size(), 0.0, 4000.0), 0.0, 1.0);

					FVector LandedHorizontalVector = ActorRightVector.CrossProduct(MovementComponent.GroundContact.Normal).GetSafeNormal();
					// Debug::DrawDebugLine(ActorLocation, ActorLocation + LandedHorizontalVector * 1000.0, FLinearColor::LucBlue, 5.0, 3.0);
					float VelocityForwardDot = MovementComponent.PreviousVelocity.GetSafeNormal().DotProduct(LandedHorizontalVector);
					PlayerComponent.HorizontalLandedImpactStrength = Math::Clamp(Math::NormalizeToRange(Math::Abs(VelocityForwardDot) * MovementComponent.PreviousVelocity.Size(), 0.0, 4000.0), 0.0, 1.0);
				}

				if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
				{
					PrintToScreen("LandedImpact: " + PlayerComponents[0].LandedImpactStrength, 2.0, FLinearColor::Green);
#if EDITOR
					TEMPORAL_LOG(this, "Sliding").Value("LandedImpact", PlayerComponents[0].LandedImpactStrength);
#endif
				}
			}
		}
	}

	UFUNCTION(DevFunction)
	void StartSlidingDiscWithoutPlayers()
	{
		bIsSliding = true;
	}

	UFUNCTION()
	void TeleportToTargetActor(AActor TargetActor)
	{
		SetActorLocationAndRotation(TargetActor.ActorLocation, TargetActor.ActorRotation, true);
		Game::Mio.Mesh.HazeForceClothTeleportMode(EHazeClothTeleportMode::TeleportAndReset);
		Game::Zoe.Mesh.HazeForceClothTeleportMode(EHazeClothTeleportMode::TeleportAndReset);

		if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
			Debug::DrawDebugCoordinateSystem(TargetActor.ActorLocation, TargetActor.ActorRotation, 1000, 6.0, 10.0);
		ActorVelocity = FVector::ZeroVector;
	}
	
	UFUNCTION(DevFunction)
	void StartSlidingDisc(bool bSnapPlayers = true)
	{
		if (bIsSliding)
			return;

		{
			auto Player = Game::Mio;

			// Enable fullscreen and slide camera
			//Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			Player.ActivateCamera(Camera, CameraBlendDuration, this);

			auto POI = Player.CreatePointOfInterest();
			POI.FocusTarget.SetFocusToComponent(CameraFocusTarget);
			POI.Apply(this, 0);
			
		}

		bIsSliding = true;

		for (auto Player : Game::Players)
		{
			if (!bSnapPlayers)
				Player.MeshOffsetComponent.FreezeTransformAndLerpBackToParent(this, 0.5);

			Player.AttachToComponent(Player.IsMio() ? PlayerAttachementMio : PlayerAttachementZoe, AttachmentRule = EAttachmentRule::SnapToTarget);
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			Player.BlockCapabilities(n"Respawn", this);
			Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

			Outline::ApplyNoOutlineOnActor(Player, Player.OtherPlayer, this, EInstigatePriority::High);

			USlidingDiscPlayerComponent SlidingDiscPlayerComponent = USlidingDiscPlayerComponent::Get(Player);

			PlayerComponents.Add(SlidingDiscPlayerComponent);

			SlidingDiscPlayerComponent.bIsSliding = bIsSliding;
			RequestComponent.StartInitialSheetsAndCapabilities(Player, this);
		}
	}

	UFUNCTION()
	void LateSlidingPOI()
	{
		Game::Mio.ClearPointOfInterestByInstigator(this);
		AHazePlayerCharacter Player = Game::Mio;
		auto POI = Player.CreatePointOfInterest();
		POI.FocusTarget.SetFocusToComponent(CameraFocusTarget);
		POI.Apply(this, 5);
		bLongPOIUsed = true;
	}

	UFUNCTION(DevFunction)
	void StopSlidingDisc()
	{
		// Disable fullscreen and slide camera
		//Game::Mio.ClearViewSizeOverride(this);
		//Game::Mio.DeactivateCamera(Camera, 1.0);

		Game::Mio.ClearPointOfInterestByInstigator(this);

		// Disable collision on sphere
		WorldCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		bIsSliding = false;

		for (auto Player : Game::Players)
		{
			Player.DetachFromActor(EDetachmentRule::KeepWorld);
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			Player.UnblockCapabilities(n"Respawn", this);
			Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

			Outline::ClearOutlineOnActor(Player, Player.OtherPlayer, this);

			USlidingDiscPlayerComponent SlidingDiscPlayerComponent = USlidingDiscPlayerComponent::Get(Player);
			SlidingDiscPlayerComponent.bIsSliding = bIsSliding;
			RequestComponent.StopInitialSheetsAndCapabilities(Player, this);
		}
	}

	// -----------------------------------------------------------------------------
	// Boaty thingz
	
	UFUNCTION()
	private void HandlePlayerImpactBegin(AHazePlayerCharacter Player)
	{
		if (ImpactingPlayers.AddUnique(Player))
		{
			auto PlayerMoveComp = UHazeMovementComponent::Get(Player);
			AddImpulse(Player.ActorLocation, PlayerMoveComp.PreviousVelocity * PlayerImpulseScale);
		}
	}

	UFUNCTION()
	private void HandlePlayerImpactEnd(AHazePlayerCharacter Player)
	{
		ImpactingPlayers.Remove(Player);
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		USanctuaryBoatEventHandler::Trigger_Grabbed(this);
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		USanctuaryBoatEventHandler::Trigger_Released(this);
	}

	UFUNCTION()
	private void HandlePortalAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
	}

	UFUNCTION()
	void SetGrabDistance(float Distance)
	{
		TArray<UDarkPortalTargetComponent> DarkPortalTargetComps;
		GetComponentsByClass(DarkPortalTargetComps);
		for (auto DarkPortalTargetComp : DarkPortalTargetComps)
			DarkPortalTargetComp.MaximumDistance = Distance;
	}

	void CreateGrabTargets()
	{
		float AngleOffset = (GrabTargets - 1) * GrabTargetsSpreadAngle * 0.5;
		for (int i = 0; i < GrabTargets; i++)
		{
			FName GrabTargetName = FName(GetName() + "_UDarkPortalTargetComponent_" + i);
			UDarkPortalTargetComponent GrabTarget = UDarkPortalTargetComponent::Create(this, GrabTargetName);
			GrabTarget.MaximumDistance = GrabDistance;
			GrabTarget.bLimitAngle = true;
			GrabTarget.LimitedAngle = 90.0;
			
			GrabTarget.AttachToComponent(ForceAnchorComp);

			FVector Location = FVector(Math::Cos(Math::DegreesToRadians(i * GrabTargetsSpreadAngle - AngleOffset)) * (BoatRadius - GrabTargetsInset), Math::Sin(Math::DegreesToRadians(i * GrabTargetsSpreadAngle - AngleOffset)) * (BoatRadius - GrabTargetsInset), 0.0);
			GrabTarget.RelativeLocation = Location -FVector::ForwardVector * BoatRadius;
			GrabTarget.RelativeRotation = FRotator::MakeFromZ(Location);
		}
	}

	void UpdateGrabTargetLocation()
	{
		if (DarkPortal == nullptr)
		{
			for (auto Player : Game::Players)
			{
				UDarkPortalUserComponent DarkPortalUserComp = UDarkPortalUserComponent::Get(Player);
				if (DarkPortalUserComp != nullptr)
					DarkPortal = DarkPortalUserComp.Portal;
			}

			if (DarkPortal == nullptr)
				return;
		}

		if (DarkPortal.IsGrabbingAny())
			return;

		FVector ToDarkPortal = (DarkPortal.ActorLocation - Pivot.WorldLocation).VectorPlaneProject(Pivot.UpVector).SafeNormal * BoatRadius;
		FVector Location = Pivot.WorldLocation + ToDarkPortal;
		ForceAnchorComp.SetWorldLocationAndRotation(Location, FQuat::MakeFromZX(Pivot.UpVector, ToDarkPortal));
	}

	FVector GetGrabForce() property
	{
		FVector Force = FVector::ZeroVector;
		for (auto& Grab : DarkPortalResponseComp.Grabs)
			Force += Grab.ConsumeForce();

		for (auto& Attach : DarkPortalResponseComp.Attaches)
			Force += Attach.ConsumeForce();

		return Force;
	}

	FVector GetBuoyantForce() property
	{
		float Force = Math::Min(0.0, (ActorLocation.Z - BoatRadius) - GetWaterHeight()) * -20.0 * BuoyantScale;
//		PrintToScreen("" + Force, 0.0, FLinearColor::Green);
		return -BoatGravity.SafeNormal * Force;
	}

	FVector GetDragForce() property
	{
		return Velocity * BoatDrag;
	}

	FVector GetAngularDragTorque() property
	{
		return AngularVelocity * AngularDrag;
	}

	FVector GetPlayerImpactTorque() property
	{
		FVector ImpactTorque = FVector::ZeroVector;
		for (auto ImpactingPlayer : ImpactingPlayers)
		{
			if (ImpactingPlayer.IsPlayerDead())
				continue;

			ImpactTorque += LinearToTorque(ImpactingPlayer.ActorLocation, -FVector::UpVector * PlayerWeight * PlayerTorqueScale);
		}

		return ImpactTorque;
	}

	FVector GetFloatingTorque() property
	{
		FVector Torque = Pivot.WorldTransform.InverseTransformVectorNoScale(-(Pivot.UpVector).CrossProduct(BoatGravity.SafeNormal) * 30.0);

		return Torque;
//		return -(Pivot.UpVector).CrossProduct(Gravity.SafeNormal) * 30.0;
	}

	FVector GetPlayerImpactForce() property
	{
		FVector ImpactForce = FVector::ZeroVector;
		for (auto ImpactingPlayer : ImpactingPlayers)
		{
			if (ImpactingPlayer.IsPlayerDead())
				continue;

			ImpactForce += BoatGravity.SafeNormal * PlayerWeight;
		}

		return ImpactForce;
	}

	FVector GetStreamForce() property
	{
		int ActiveStreamForces = 0;
		FVector Force;
		
		TListedActors<ASanctuaryBoatStreamVolume> StreamVolumes;
		for (auto StreamVolume : StreamVolumes)
		{
			if (Shape::IsPointInside(StreamVolume.Shape.CollisionShape, StreamVolume.ActorTransform, ActorLocation))
			{
				FVector ToTarget = StreamVolume.StreamTargetLocation - ActorLocation;
				FVector Direction = ToTarget.SafeNormal;
				float Strength = Math::Min(StreamVolume.Force, ToTarget.Size());
				Force += Direction * Strength;
				ActiveStreamForces++;
			}
		}

		TListedActors<ASanctuaryBoatStreamSpline> StreamSplines;
		for (auto StreamSpline : StreamSplines)
		{
			if (Shape::IsPointInside(StreamSpline.Volume.CollisionShape, StreamSpline.Volume.WorldTransform, ActorLocation))
			{
				FTransform TransformOnSpline = StreamSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
				FVector ToSpline = TransformOnSpline.Location - ActorLocation;

				if (ToSpline.Size() > TransformOnSpline.Scale3D.Y * StreamSpline.BaseWidth)
					continue;

				Force += ToSpline.ConstrainToPlane(TransformOnSpline.Rotation.ForwardVector);
				Force += TransformOnSpline.Rotation.ForwardVector * StreamSpline.Force;
				ActiveStreamForces++;
			}
		}

		if (ActiveStreamForces > 0)
			Force /= ActiveStreamForces;

		return Force.ConstrainToPlane(FVector::UpVector);
	}	

	void AddImpulse(FVector Origin, FVector Impulse)
	{
		AccumulatedImpulse += Impulse.ConstrainToDirection(Pivot.UpVector);
		AccumulatedAngularImpulse += LinearToTorque(Origin, Impulse);
	}

	FVector ConsumeImpulse()
	{
		FVector ReturnImpulse = AccumulatedImpulse;
		AccumulatedImpulse = FVector::ZeroVector;

		return ReturnImpulse;
	}

	FVector ConsumeAngularImpulse()
	{
		FVector ReturnAngularImpulse = AccumulatedAngularImpulse;
		AccumulatedAngularImpulse = FVector::ZeroVector;

		return ReturnAngularImpulse;
	}	

	void DrawDebugBoat()
	{
	//	Debug::DrawDebugLine(ForceAnchorComp.WorldLocation, ForceAnchorComp.WorldLocation + Force, FLinearColor::Green, 10.0, 0.0);
		for (auto ImpactingPlayer : ImpactingPlayers)
			PrintToScreen("Player " + ImpactingPlayer.Name + " on boat.", 0.0, FLinearColor::Green);	

		Debug::DrawDebugCoordinateSystem(BasePivot.WorldLocation, BasePivot.WorldRotation, 200.0, 4.0, 0.0, true);
		Debug::DrawDebugCoordinateSystem(ActorLocation, ActorRotation, 200.0, 4.0, 0.0, true);

		TArray<UDarkPortalTargetComponent> Targets;
		GetComponentsByClass(Targets);
	
		for (auto Target : Targets)
		{
			Debug::DrawDebugPoint(Target.WorldLocation, 20.0, FLinearColor::Red, 0.0);
			Debug::DrawDebugLine(Target.WorldLocation, Target.WorldLocation + Target.UpVector * 200.0, FLinearColor::Blue, 10.0, 0.0);
		}
	}

	float GetWaterHeight()
	{
		if (WaterHeightRef != nullptr)
			return WaterHeightRef.GetWaterHeightLocation().Z;
		return -1000.0;
	}

	FVector LinearToTorque(FVector Origin, FVector LinearForce)
	{
		FVector Offset = Origin - Pivot.WorldLocation;

		FVector Torque = Offset.CrossProduct(LinearForce) / (BoatRadius * BoatRadius);

		Torque = Pivot.WorldTransform.InverseTransformVectorNoScale(Torque);

		return Torque;
	}

	UFUNCTION(BlueprintPure)
	float GetAngularSpeed() property
	{
		return AngularVelocity.Size();
	}

	UFUNCTION(BlueprintPure)
	void HasContact(bool&out ValidContact, UPhysicalMaterial&out PhysMaterial)
	{
		FMovementHitResult AnyValidContact;
		if(!MovementComponent.GetAnyValidContact(AnyValidContact))
		{
			ValidContact = false;
			PhysMaterial = nullptr;
			return;
		}
		
		FHitResult HitResult = AnyValidContact.ConvertToHitResult();
		ValidContact = HitResult.IsValidBlockingHit();
		PhysMaterial = HitResult.PhysMaterial;
		return;
	}
}
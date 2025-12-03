event void FBounceKiteBounceEvent(AHazePlayerCharacter Player);

class ABounceKite : AZipKite
{
	UPROPERTY(DefaultComponent, Attach = KiteHoverRoot)
	USceneComponent BounceRoot;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComp;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchEnterByZoneComp;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UBounceKiteComponent BounceKiteComp;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent BounceMeshRoot;

	UPROPERTY(DefaultComponent, Attach = BounceMeshRoot)
	UStaticMeshComponent BounceMesh;

	UPROPERTY(EditAnywhere)
	float BounceHeight = 1200.0;

	UPROPERTY(EditAnywhere)
	float ZipBounceForwardsSpeed = 0.0;

	UPROPERTY(EditAnywhere)
	float MaximumHorizontalVelocity = 4000.0;

	UPROPERTY(EditAnywhere)
	UStaticMesh MeshOverride;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect BounceFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> BounceCamShake;

	UPROPERTY()
	FBounceKiteBounceEvent OnPlayerBounced;

	default HoverValues.HoverOffsetRange = FVector(20.0, 50.0, 50.0);

	FHazeConstrainedPhysicsValue ScalePhysValue;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		bUseSpiralRope = !bAllowZip;

		Super::ConstructionScript();
		
		if (MeshOverride != nullptr)
		{
			BounceMesh.SetStaticMesh(MeshOverride);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		PlayerTriggerComp.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		OnPlayerLanded.AddUFunction(this, n"PlayerLanded");

		ScalePhysValue.SnapTo(1.0, true);
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		BouncePlayer(Player, ZipBounceForwardsSpeed);
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (Player.IsAnyCapabilityActive(KiteTags::ZipKite))
			return;

		BouncePlayer(Player);
	}

	void BouncePlayer(AHazePlayerCharacter Player, float ForwardSpeed = 0.0)
	{
		// It had to be done
		Player.BlockCapabilities(PlayerSwingTags::SwingJump, this);
		Player.UnblockCapabilities(PlayerSwingTags::SwingJump, this);

		Player.BlockCapabilities(n"FallingDeath", this);
		Player.UnblockCapabilities(n"FallingDeath", this);

		Player.BlockCapabilities(KiteTags::LaunchKite, this);
		Player.UnblockCapabilities(KiteTags::LaunchKite, this);

		Player.AddMovementImpulseToReachHeight(BounceHeight);
		if (!Math::IsNearlyEqual(ForwardSpeed, 0.0))
			Player.AddMovementImpulse(ActorForwardVector * ForwardSpeed);
		FVector HorizontalDirection = Player.ActorHorizontalVelocity.GetSafeNormal();
		FVector HorizontalVelocity = HorizontalDirection * (Math::Clamp(Player.ActorHorizontalVelocity.Size(), 0.0, MaximumHorizontalVelocity));
		Player.SetActorHorizontalVelocity(HorizontalVelocity);

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		if (Player.ActorHorizontalVelocity.Size() < 100.0 && Math::IsNearlyEqual(MoveComp.MovementInput.Size(), 0.0))
			Player.SetActorHorizontalVelocity(FVector::ZeroVector);

		Player.FlagForLaunchAnimations(FVector::UpVector * BounceHeight);

		FauxPhysics::ApplyFauxImpulseToActorAt(this, Player.ActorLocation, -FVector::UpVector * 400.0);

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		Player.KeepLaunchVelocityDuringAirJumpUntilLanded();

		Player.PlayForceFeedback(BounceFF, false, true, this);
		Player.PlayCameraShake(BounceCamShake, this);

		OnPlayerBounced.Broadcast(Player);

		ScalePhysValue.AddImpulse(-1.0);

		UBounceKiteEffectEventHandler::Trigger_Bounce(this);
		UKiteTownVOEffectEventHandler::Trigger_Bounce(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		ScalePhysValue.SpringTowards(1.0, 100.0);
		ScalePhysValue.Update(DeltaTime);
		BounceMeshRoot.SetRelativeScale3D(FVector(1.0, 1.0, ScalePhysValue.Value));
	}
}
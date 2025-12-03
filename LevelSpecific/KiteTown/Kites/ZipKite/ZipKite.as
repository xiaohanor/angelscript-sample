event void FZipKitePlayerAttachEvent(AHazePlayerCharacter Player);
event void FZipKitePlayerDetachEvent(AHazePlayerCharacter Player);
event void FZipKitePlayerLanded(AHazePlayerCharacter Player);

class AZipKite : AKiteBase
{
	default bUseRope = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ZipPointRoot;

	UPROPERTY(DefaultComponent, Attach = ZipPointRoot)
	UZipKitePointComponent ZipPointComp;

	UPROPERTY(DefaultComponent, Attach = KiteHoverRoot)
	USceneComponent PlayerLandingPointComp;

	UPROPERTY(DefaultComponent, Attach = KiteHoverRoot)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Zip")
	bool bAllowZip = true;

	UPROPERTY(EditAnywhere, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	float ZipSpeed = 1200.0;

	UPROPERTY(EditInstanceOnly, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	float ZipExitDistance = 1600.0;

	//Constrain the rope length during swing up gradually to a fraction of the horizontal delta between player and landing point
	UPROPERTY(EditInstanceOnly, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	bool bAllowRopeShorteningOnSwingUp = false;

	UPROPERTY(EditAnywhere, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	float ZipMashMaxSpeed = 3200.0;

	UPROPERTY(EditAnywhere, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	float ZipPointHeight = 800.0;

	UPROPERTY(EditAnywhere, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	FVector ZipOffset = FVector(-20.0, -60.0, -600);

	UPROPERTY(EditAnywhere, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	float ZipInterpLocSpeed = 5.0;

	UPROPERTY(EditAnywhere, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	float ZipInterpRotSpeed = 4.0;

	UPROPERTY(EditAnywhere, Category = "Zip", Meta = (EditCondition = "bAllowZip", EditConditionHides))
	FRotator RotationOffset = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere, Category = "Camera")
	bool bApplyPointOfInterest = true;

	UPROPERTY(EditAnywhere, Category = "Camera")
	FVector PoiOffset = FVector(800.0, 0.0, 200.0);

	UPROPERTY(EditAnywhere, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CamSettingsOverride;

	UPROPERTY(EditAnywhere)
	bool bTopRespawnPoint = true;
	ARespawnPoint TopRespawnPoint;

	UPROPERTY(EditAnywhere)
	bool bZipRespawnPoint = true;
	ARespawnPoint ZipRespawnPoint;

	UPROPERTY()
	FZipKitePlayerAttachEvent OnPlayerAttached;

	UPROPERTY()
	FZipKitePlayerDetachEvent OnPlayerDetached;

	UPROPERTY()
	FZipKitePlayerLanded OnPlayerLanded;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		bUseSpiralRope = !bAllowZip;

		Super::ConstructionScript();

		UpdateZipPointLocation();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bUseSpiralRope = !bAllowZip;

		Super::BeginPlay();
		
		if (bTopRespawnPoint)
		{
			TopRespawnPoint = SpawnActor(ARespawnPoint, bDeferredSpawn = true);
			TopRespawnPoint.MakeNetworked(this, n"TopRespawn");
			FinishSpawningActor(TopRespawnPoint);
			TopRespawnPoint.AttachToComponent(PlayerLandingPointComp);
		}

		if (bZipRespawnPoint)
		{
			ZipRespawnPoint = SpawnActor(ARespawnPoint, bDeferredSpawn = true);
			ZipRespawnPoint.MakeNetworked(this, this, n"ZipRespawn");
			FinishSpawningActor(ZipRespawnPoint);
			ZipRespawnPoint.AttachToComponent(ZipPointComp);
			ZipRespawnPoint.OnRespawnAtRespawnPoint.AddUFunction(this, n"PlayerZipRespawned");
		}

		OnPlayerLanded.AddUFunction(this, n"PlayerLandedAfterZip");
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerGroundImpact");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerJumped");

		OnPlayerAttached.AddUFunction(this, n"PlayerAttached");

		ZipPointComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"GrappleStarted");
		ZipPointComp.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"GrappleConnected");
	}

	UFUNCTION()
	private void GrappleStarted(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePoint)
	{
		UZipKitePlayerEffectEventHandler::Trigger_GrappleStarted(Player);
		UKiteTownVOEffectEventHandler::Trigger_ZipGrappleStarted(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION()
	private void GrappleConnected(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePoint)
	{
		UZipKitePlayerEffectEventHandler::Trigger_GrappleConnected(Player);
		UKiteTownVOEffectEventHandler::Trigger_ZipGrappleConnected(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION()
	private void PlayerAttached(AHazePlayerCharacter Player)
	{
		if (bZipRespawnPoint)
		{
			Player.SetStickyRespawnPoint(ZipRespawnPoint);
		}
	}
	
	UFUNCTION()
	private void PlayerZipRespawned(AHazePlayerCharacter RespawningPlayer)
	{
		UZipKitePlayerComponent ZipKitePlayerComp = UZipKitePlayerComponent::Get(RespawningPlayer);
		ZipKitePlayerComp.ZipKiteToForceActivate = ZipPointComp;
	}

	UFUNCTION()
	private void PlayerJumped(AHazePlayerCharacter Player)
	{
		if (Player.IsAnyCapabilityActive(PlayerMovementTags::GroundJump))
		{
			Player.AddMovementImpulse(FVector(0.0, 0.0, 400.0));
			FauxPhysics::ApplyFauxImpulseToActorAt(this, Player.ActorLocation - (FVector::UpVector * 100.0), FVector::UpVector * 200.0);
		}
	}

	UFUNCTION()
	private void PlayerLandedAfterZip(AHazePlayerCharacter Player)
	{
		if (bTopRespawnPoint)
			Player.SetStickyRespawnPoint(TopRespawnPoint);

		FauxPhysics::ApplyFauxImpulseToActorAt(this, Player.ActorLocation, -FVector::UpVector * 200.0);
	}

	UFUNCTION()
	private void PlayerGroundImpact(AHazePlayerCharacter Player)
	{
		if (bTopRespawnPoint)
			Player.SetStickyRespawnPoint(TopRespawnPoint);

		FauxPhysics::ApplyFauxImpulseToActorAt(this, Player.ActorLocation, -FVector::UpVector * 200.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		UpdateZipPointLocation();
		
		/*FHazeRuntimeSpline SwingUpSpline;
		SwingUpSpline.AddPoint(KiteRoot.WorldLocation - (FVector::UpVector * 600.0));
		SwingUpSpline.AddPoint(KiteRoot.WorldLocation + (KiteRoot.ForwardVector * 350.0) - (FVector::UpVector * 400.0));
		SwingUpSpline.AddPoint(KiteRoot.WorldLocation + (KiteRoot.ForwardVector * 500.0));
		SwingUpSpline.AddPoint(PlayerLandingPointComp.WorldLocation + (KiteRoot.ForwardVector * 400.0) + (FVector::UpVector * 300.0));
		SwingUpSpline.AddPoint(PlayerLandingPointComp.WorldLocation + (KiteRoot.ForwardVector * 75.0) + (FVector::UpVector * 300.0));
		SwingUpSpline.AddPoint(PlayerLandingPointComp.WorldLocation);*/

		if (!bAllowZip)
			ZipPointComp.Disable(this);
	}

	void UpdateZipPointLocation()
	{
		FVector ZipLoc = RuntimeSplineRope.GetLocationAtDistance(ZipPointHeight);
		FRotator ZipRot = RuntimeSplineRope.GetRotationAtDistance(ZipPointHeight);
		ZipRot.Roll = 0.0;
		ZipRot.Pitch = 0.0;

		ZipPointRoot.SetWorldLocationAndRotation(ZipLoc, ZipRot);
	}
}
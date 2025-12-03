struct FSplitTraversalControllableTurretArrowParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	float TimeToImpact = 0.0;

	FSplitTraversalControllableTurretArrowParams(FVector _ImpactLocation, float _TimeToImpact)
	{
		ImpactLocation = _ImpactLocation;
		TimeToImpact = _TimeToImpact;
	}
}

UCLASS(Abstract)
class USplitTraversalControllableTurretEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFire() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnArrowHit(FSplitTraversalControllableTurretArrowParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractionStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractionStopped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnZoeRespawnAfterKilledByCannon() {}
}

class ASplitTraversalControllableTurret : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UFauxPhysicsAxisRotateComponent TurretYawRoot;

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	UFauxPhysicsForceComponent YawForceComp;

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	UFauxPhysicsAxisRotateComponent TurretPitchRoot;

	UPROPERTY(DefaultComponent, Attach = TurretPitchRoot)
	UFauxPhysicsForceComponent PitchForceComp;

	UPROPERTY(DefaultComponent, Attach = TurretPitchRoot)
	UStaticMeshComponent LaserMeshComp;

	UPROPERTY(DefaultComponent, Attach = LaserMeshComp)
	UHazeDecalComponent DecalComp;

	UPROPERTY(DefaultComponent, Attach = TurretPitchRoot)
	USceneComponent RecoilRoot;

	UPROPERTY(DefaultComponent, Attach = RecoilRoot)
	UNiagaraComponent MuzzleVFXComp;

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	UThreeShotInteractionComponent InteractComp;
	default InteractComp.InteractionCapability = n"SplitTraversalControllableTurretCapability";

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent TurretYawRootFantasy;

	UPROPERTY(DefaultComponent, Attach = TurretYawRootFantasy)
	USceneComponent TurretPitchRootFantasy;

	UPROPERTY(DefaultComponent, Attach = TurretPitchRootFantasy)
	USceneComponent RecoilRootFantasy;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;

	UPROPERTY()
	UBlendSpace AimBlendSpace;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraActor;

	UPROPERTY(EditDefaultsOnly, Category = "CS / FF")
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "CS / FF")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	FHazeTimeLike RecoilTimeLike;
	default RecoilTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	TSubclassOf<ASplitTraversalControllableTurretRocket> RocketClass;

	UPROPERTY()
	TSubclassOf<ASplitTraversalControllableTurretArrow> ArrowClass;

	UPROPERTY(EditAnywhere)
	float RecoilForce = 100.0;

	bool bCoolDown = false;
	bool bIsInteracting = false;

	UPROPERTY()
	float YawForce = 100.0;

	UPROPERTY()
	float PitchForce = 50.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		RecoilTimeLike.BindUpdate(this, n"RecoilTimeLikeUpdate");
		RecoilTimeLike.BindFinished(this, n"RecoilTimeLikeFinished");

		InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		InteractComp.OnCancelPressed.AddUFunction(this, n"HandleInteractionCanceled");

		SetActorControlSide(Game::Mio);
	}

	UFUNCTION()
	private void HandleInteractionCanceled(AHazePlayerCharacter Player,
	                                       UThreeShotInteractionComponent Interaction)
	{
		bIsInteracting = false;
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		bIsInteracting = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CameraRoot.SetRelativeRotation(TurretPitchRoot.RelativeRotation * 0.5);
		ReplicateMovement();

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.IgnoreActor(this);
		auto HitResult = Trace.QueryTraceSingle(MuzzleVFXComp.WorldLocation,
			MuzzleVFXComp.WorldLocation + TurretPitchRoot.ForwardVector * -20000.0);

		if (HitResult.bBlockingHit)
			DecalComp.SetWorldLocation(HitResult.ImpactPoint);
		else
			DecalComp.SetWorldLocation(HitResult.TraceEnd);
	}

	UFUNCTION(CrumbFunction)
	void CrumbShoot()
	{
		USplitTraversalControllableTurretEventHandler::Trigger_OnFire(this);

		MuzzleVFXComp.Activate(true);
		RecoilTimeLike.PlayFromStart();
		LaserMeshComp.SetHiddenInGame(true, true);
		TurretPitchRoot.ApplyImpulse(PitchForceComp.WorldLocation, FVector::UpVector * RecoilForce);
		bCoolDown = true;
		BP_Shot();

		auto Rocket = Cast<ASplitTraversalControllableTurretRocket>
							(SpawnActor(RocketClass, MuzzleVFXComp.WorldLocation, MuzzleVFXComp.WorldRotation, bDeferredSpawn = true));
		Rocket.IgnoredActor = this;
		FinishSpawningActor(Rocket);

		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, ScifiRoot.GetWorldLocation(), false, this, 1400, 1600, 1.0, 1, EHazeSelectPlayer::Mio);
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, FantasyRoot.GetWorldLocation(), false, this, 1400, 1600, 1.0, 1, EHazeSelectPlayer::Zoe);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, FantasyRoot.GetWorldLocation(), 500, 700, 1.0, 1.0, false, EHazeWorldCameraShakeSamplePosition::Player);
		Game::Mio.PlayWorldCameraShake(CameraShake, this, ScifiRoot.GetWorldLocation(), 500, 700, 1.0, 1.0, false, EHazeWorldCameraShakeSamplePosition::Player);

		if (HasControl())
			PredictShootArrow();
	}

	private FVector GetPredictedLocationForArrow(FVector ArrowOrigin, ASplitTraversalWaterPot Pot)
	{
		FVector LocalOrigin;
		FVector LocalExtent;
		Pot.GetActorLocalBounds(true, LocalOrigin, LocalExtent);

		FVector CurrentLocation = Pot.ActorTransform.TransformPosition(LocalOrigin);

		float TimeToReach = CurrentLocation.Distance(ArrowOrigin) / SplitTraversalControllableTurretArrowConstants::Speed;
		return Pot.SplineComp.GetWorldLocationAtSplineDistance(
			Pot.ProgressAlongSpline + TimeToReach * Pot.MovementSpeed
		) + Pot.ActorRotation.RotateVector(LocalOrigin);
	}

	private void PredictShootArrow()
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		// Do auto-aiming towards pots for the arrow. Nobody will notice it doesn't actually match up
		FVector ArrowOrigin = Manager.Position_ScifiToFantasy(MuzzleVFXComp.WorldLocation);
		FVector ArrowDirection = MuzzleVFXComp.WorldRotation.ForwardVector;
		TListedActors<ASplitTraversalWaterPot> PotsList;

		float AutoAimMaxDistance = 400.0;
		float AutoAimBestDistance = BIG_NUMBER;

		ASplitTraversalWaterPot AutoAimPot;
		FVector AutoAimTarget;

		for (ASplitTraversalWaterPot Pot : PotsList)
		{
			FVector PredictedLocation = GetPredictedLocationForArrow(ArrowOrigin, Pot);
			FVector HitPoint = Math::ClosestPointOnInfiniteLine(
				ArrowOrigin, ArrowOrigin + ArrowDirection, PredictedLocation
			);

			float Distance = HitPoint.Distance(PredictedLocation);
			if (Distance > AutoAimMaxDistance)
				continue;

			// Prioritize filled pots over non-filled pots
			if (Pot.bFilled)
				Distance *= 0.5;

			if (Distance > AutoAimBestDistance)
				continue;

			AutoAimBestDistance = Distance;
			AutoAimPot = Pot;
			AutoAimTarget = PredictedLocation;
		}

		

		if (AutoAimPot != nullptr)
		{
			ArrowDirection = (AutoAimTarget - ArrowOrigin).GetSafeNormal();

			// Debug::DrawDebugSphere(AutoAimTarget);
			// Debug::DrawDebugLine(ArrowOrigin, AutoAimTarget);
		}

		// Try to aim towards the other player if we're not aiming towards a pot
		FVector PlayerLocation = Game::Zoe.ActorCenterLocation;
		FVector HitPoint = Math::ClosestPointOnInfiniteLine(
			ArrowOrigin, ArrowOrigin + ArrowDirection, PlayerLocation
		);

		float Distance = HitPoint.Distance(PlayerLocation);
		if (Distance < AutoAimMaxDistance)
		{
			ArrowDirection = (PlayerLocation - ArrowOrigin).GetSafeNormal();
			AutoAimPot = nullptr;
		}

		CrumbShootArrow(ArrowOrigin, AutoAimPot, FRotator::MakeFromX(ArrowDirection));
	}

	UFUNCTION(CrumbFunction)
	private void CrumbShootArrow(FVector ArrowLocation, ASplitTraversalWaterPot AutoAimPot, FRotator ArrowRotation)
	{
		// Spawn fantasy projectile
		auto Arrow = SpawnActor(ArrowClass, ArrowLocation, FRotator(), bDeferredSpawn = true);	
		Arrow.ControllableTurretOwner = this;
		FinishSpawningActor(Arrow);

		if (AutoAimPot != nullptr)
		{
			auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
			FVector ArrowOrigin = Manager.Position_ScifiToFantasy(MuzzleVFXComp.WorldLocation);
			FVector PredictedLocation = GetPredictedLocationForArrow(ArrowOrigin, AutoAimPot);

			Arrow.SetActorRotation(FRotator::MakeFromX(PredictedLocation - ArrowOrigin));
		}
		else
		{
			Arrow.SetActorRotation(ArrowRotation);
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Shot() {}

	UFUNCTION()
	private void RecoilTimeLikeUpdate(float CurrentValue)
	{
		RecoilRoot.SetRelativeLocation(FVector::ForwardVector * 200.0 * CurrentValue);
		CameraRoot.SetRelativeLocation(FVector(50.0 * CurrentValue, 0.0, 300.0));
	}

	UFUNCTION()
	private void RecoilTimeLikeFinished()
	{
		bCoolDown = false;
	}

	private void ReplicateMovement()
	{
		TurretYawRootFantasy.SetRelativeRotation(TurretYawRoot.RelativeRotation);
		TurretPitchRootFantasy.SetRelativeRotation(TurretPitchRoot.RelativeRotation);
		RecoilRootFantasy.SetRelativeLocation(RecoilRoot.RelativeLocation);
	}

	UFUNCTION()
	void HandlePlayerRespawned()
	{
		auto HealthComp = UPlayerHealthComponent::Get(Game::Zoe);
		HealthComp.OnReviveTriggered.UnbindObject(this);

		USplitTraversalControllableTurretEventHandler::Trigger_OnZoeRespawnAfterKilledByCannon(this);

		PrintToScreenScaled("Resspawn", 2.0);
	}
};
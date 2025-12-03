event void FOnHayRollShennanigans(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ARollingHay : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerAttachComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HayRoot;

	UPROPERTY(EditInstanceOnly)
	AHazeActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> LaunchCamShake;

	UPROPERTY(EditAnywhere)
	float RollSpeed = 800.0;

	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float SplineStartFraction = 0.0;

	UPROPERTY(EditAnywhere)
	bool bPreviewPosition = false;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 75.0;

	UPROPERTY(EditAnywhere)
	bool bRollForward = true;

	UPROPERTY()
	FOnHayRollShennanigans OnHayRollShennanigansCaught;

	UPROPERTY()
	FOnHayRollShennanigans OnHayRollShennanigansReleased;

	bool bMioCaught = false;
	bool bZoeCaught = false;

	float TrappedDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewPosition && SplineActor != nullptr)
		{
			UHazeSplineComponent Spline = UHazeSplineComponent::Get(SplineActor);
			if (Spline == nullptr)
				return;

			FTransform PreviewTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength * SplineStartFraction);
			FRotator Rot = FRotator(PreviewTransform.Rotation);
			Rot.Pitch = Math::Clamp(Rot.Pitch, -8.0, 8.0);
			SetActorLocationAndRotation(PreviewTransform.Location, Rot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(SplineActor);

		SetActorLocation(SplineComp.GetWorldLocationAtSplineFraction(SplineStartFraction));

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
			CrumbPlayerEnter(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerEnter(AHazePlayerCharacter Player)
	{
		if (Player.IsMio() && !bMioCaught)
		{
			bMioCaught = true;
			CatchPlayer(Player);

			Timer::SetTimer(this, n"ReleaseMio", TrappedDuration);
		}
		else if (Player.IsZoe() && !bZoeCaught)
		{
			bZoeCaught = true;
			CatchPlayer(Player);

			Timer::SetTimer(this, n"ReleaseZoe", TrappedDuration);
		}
		OnHayRollShennanigansCaught.Broadcast(Player);
	}

	private void CatchPlayer(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(n"Stretch", this);
		Player.BlockCapabilities(n"Fart", this);

		Player.ResetMovement();

		Player.AttachToComponent(PlayerAttachComp, NAME_None, EAttachmentRule::KeepWorld);

		Player.SmoothTeleportActor(PlayerAttachComp.WorldLocation, PlayerAttachComp.WorldRotation, this, 0.1);

		Player.PlayForceFeedback(LaunchFF, false, true, this);

		URollingHayEffectEventHandler::Trigger_PlayerCaught(this);
	}

	UFUNCTION()
	void ReleaseMio()
	{
		bMioCaught = false;
		ReleasePlayer(Game::Mio);
	}

	UFUNCTION()
	void ReleaseZoe()
	{
		bZoeCaught = false;
		ReleasePlayer(Game::Zoe);
	}

	void ReleasePlayer(AHazePlayerCharacter Player)
	{
		Player.SmoothTeleportActor(PlayerAttachComp.WorldLocation + (FVector(0.0, 0.0, 250.0)), Player.ActorRotation, this, 0.2);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"Stretch", this);
		Player.UnblockCapabilities(n"Fart", this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		const FTransform SplineTransform = GetSplineTransform();
		FVector LaunchImpulse = (-SplineTransform.Rotation.ForwardVector * 200.0) + (FVector::UpVector * 1000.0);
		Player.AddMovementImpulse(LaunchImpulse);

		Player.PlayForceFeedback(LaunchFF, false, true, this);
		Player.PlayCameraShake(LaunchCamShake, this);

		URollingHayEffectEventHandler::Trigger_PlayerReleased(this);
		OnHayRollShennanigansReleased.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const FTransform SplineTransform = GetSplineTransform();
		SetActorLocationAndRotation(SplineTransform.Location, SplineTransform.Rotation);

		HayRoot.AddLocalRotation(FRotator(-RotationSpeed * DeltaTime, 0.0, 0.0));
	}

	FTransform GetSplineTransform() const
	{
		float SplineDist = SplineComp.SplineLength * SplineStartFraction;

		if(bRollForward)
			SplineDist += RollSpeed * Time::PredictedGlobalCrumbTrailTime;
		else
			SplineDist -= RollSpeed * Time::PredictedGlobalCrumbTrailTime;

		SplineDist = Math::Wrap(SplineDist, 0, SplineComp.SplineLength);
		return SplineComp.GetSplinePositionAtSplineDistance(SplineDist, bRollForward).WorldTransform;
	}
}
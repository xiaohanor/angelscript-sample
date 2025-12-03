class ACoastTrainTwistingGrappleSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UGrapplePointComponent GrappleCompMio;
	default GrappleCompMio.UsableByPlayers = EHazeSelectPlayer::Mio;
	default GrappleCompMio.bTestCollision = false;
	default GrappleCompMio.ActivationRange = 2500;
	default GrappleCompMio.bRestrictToForwardVector = true;
	default GrappleCompMio.AdditionalVisibleRange = 2000;

	UPROPERTY(DefaultComponent)
	UGrapplePointComponent GrappleCompZoe;
	default GrappleCompZoe.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default GrappleCompZoe.bTestCollision = false;
	default GrappleCompZoe.ActivationRange = 2500;
	default GrappleCompZoe.bRestrictToForwardVector = true;
	default GrappleCompZoe.AdditionalVisibleRange = 2000;

	UPROPERTY(DefaultComponent)
	UCoastTrainCartBasedDisableComponent CartDisableComp;
	default CartDisableComp.bAutoDisable = true;
	default CartDisableComp.AutoDisableRange = 15000.0;
	
	UPROPERTY(EditAnywhere)
	float MaximumUpAngleLimit = 180.0;
	UPROPERTY(EditAnywhere)
	float ClosestPointHeight = 0.0;
	UPROPERTY(EditAnywhere)
	float RotationLeadAmount = 1.0;

	UPROPERTY(EditAnywhere, Category = "Adaptive Range")
	bool bChangeRangeWithNextCartDistance = true;
	UPROPERTY(EditAnywhere, Category = "Adaptive Range")
	float MinimumRange = 1500.0;
	UPROPERTY(EditAnywhere, Category = "Adaptive Range")
	float MaximumRange = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Adaptive Range")
	float BaseDistance = 5500.0;

	UPROPERTY(EditAnywhere)
	bool bIsLaunchSplineGrapple = false;

	ACoastTrainCart AttachedCart;

	TPerPlayer<bool> bWasLaunched;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bIsLaunchSplineGrapple)
		{
			GrappleCompMio.Disable(this);
			GrappleCompZoe.Disable(this);
		}

		// Find the cart we're attached to
		AActor Actor = AttachParentActor;
		while (Actor != nullptr)
		{
			AttachedCart = Cast<ACoastTrainCart>(Actor);
			if (AttachedCart != nullptr)
				break;
			Actor = Actor.AttachParentActor;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CalculateForPlayer(Game::GetZoe(), GrappleCompZoe, DeltaSeconds, true);
		CalculateForPlayer(Game::GetMio(), GrappleCompMio, DeltaSeconds, true);

		if (bChangeRangeWithNextCartDistance)
		{
			float WantedRange = MinimumRange;
			if (AttachedCart != nullptr && AttachedCart.NextCart != nullptr)
			{
				float Distance = AttachedCart.NextCart.ActorLocation.Distance(AttachedCart.ActorLocation) - BaseDistance;
				WantedRange = Math::Clamp(Distance + MinimumRange, MinimumRange, MaximumRange);

				// PrintToScreen(f"{Distance=}");
				// PrintToScreen(f"{WantedRange=}");
			}

			// Debug::DrawDebugSphere(GrappleCompMio.WorldLocation, WantedRange);

			GrappleCompMio.ActivationRange = WantedRange;
			GrappleCompZoe.ActivationRange = WantedRange;
		}
	}

	void CalculateForPlayer(AHazePlayerCharacter Player, UGrapplePointComponent GrappleComp, float Delta, bool Interpolate)
	{		
		if (bIsLaunchSplineGrapple)
		{
			if (ShouldEnableGrapple(Player))
			{
				GrappleComp.EnableForPlayer(Player, this);
				
				if (Player.IsAnyCapabilityActive(n"TrainLaunch"))
				{
					bWasLaunched[Player] = true;
				}
			}
			else
			{
				GrappleComp.DisableForPlayer(Player, this);
				bWasLaunched[Player] = false;
			}
		}
				
		if (!Player.IsAnyCapabilityActive(n"GrappleMovement"))
		{
			FSphere Bounds = Spline.GetSplineBounds();
			FVector CheckPoint = Bounds.Center;

			FVector Offset;
			Offset.Z += Bounds.W;
			Offset.Z += ClosestPointHeight;
			if (AttachedCart != nullptr)
				Offset = Offset.RotateAngleAxis(-AttachedCart.CurrentSpinSpeed * RotationLeadAmount, AttachedCart.ActorForwardVector);

			CheckPoint += Offset;

			FVector TargetLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(CheckPoint);

			if (Interpolate)
				TargetLocation = Math::VInterpTo(GrappleComp.WorldLocation, TargetLocation, Delta, 6.0);
			GrappleComp.SetWorldLocationAndRotation(TargetLocation, ActorRotation);
		}
	}

	bool ShouldEnableGrapple(AHazePlayerCharacter Player)
	{
		if (Player.IsPlayerDead())
			return false;

		if (Player.IsAnyCapabilityActive(n"TrainLaunch"))
			return true;
		
		if (bWasLaunched[Player] && Player.IsInAir())
			return true;
		
		return false;
	}
// #if EDITOR
// 	UFUNCTION(BlueprintOverride)
// 	void OnVisualizeInEditor() const
// 	{
		
// 	}
// #endif


};
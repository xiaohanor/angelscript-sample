UCLASS(Abstract)
class APigLaunchBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent BoardRootComp;

	UPROPERTY(DefaultComponent, Attach = BoardRootComp)
	UBoxComponent ImpactTrigger;

	UPROPERTY(DefaultComponent, Attach = BoardRootComp)
	UBoxComponent LaunchTrigger;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> LaunchCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchFF;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat LaunchForceCurve;

	int NumFailedJumps = 0;
	bool bSuccessfulJump = false;

	float MaxVerticalForce = 2750.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		// todo(ylva) if we want snapper networking on landing / launching, we need to predict the landing in order to get a visual compromise between lander and launched
		// or we could predict the launching and fake move other player. However then if launched didnt get launched on their side, it can get awkward
		// pinball network all over again lol

		if (ImpactTrigger.IsOverlappingActor(Player))
		{
			UHazeMovementComponent MovementComponent = UHazeMovementComponent::Get(Player);
			float FauxPhysImpulse = Math::GetMappedRangeValueClamped(FVector2D(900.0, 1600.0), FVector2D(1.5, 3.0), Math::Abs(MovementComponent.PreviousVelocity.Z));
			BoardRootComp.ApplyAngularImpulse(FauxPhysImpulse);
			
			if (LaunchTrigger.IsOverlappingActor(Player.OtherPlayer) && Player.HasControl())
			{
				NetLaunchNow(Player.OtherPlayer, MovementComponent.PreviousVelocity.Z);
			}

			BP_SpawnEffect();

			float LaunchForceAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, -1600.0), FVector2D(0.0, 1.0), MovementComponent.PreviousVelocity.Z);
			if (LaunchForceAlpha > 0.9)
				UPigLaunchBoardEventHandler::Trigger_BigLaunch(this);
			else
				UPigLaunchBoardEventHandler::Trigger_SmallLaunch(this);
		}
		else if (LaunchTrigger.IsOverlappingActor(Player))
		{
			UHazeMovementComponent MovementComponent = UHazeMovementComponent::Get(Player);
			if (Math::Abs(MovementComponent.PreviousVelocity.Z) >= 2200.0)
				UPigLaunchBoardEventHandler::Trigger_BigLandingOnLaunchSide(this);
		}
	}

	UFUNCTION(NetFunction)
	void NetLaunchNow(AHazePlayerCharacter LaunchedPlayer, float LandingDownForce)
	{
		if (!LaunchedPlayer.HasControl())
			return;
		if (!LaunchTrigger.IsOverlappingActor(LaunchedPlayer))
			return;

		float LaunchForceAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, -1600.0), FVector2D(0.0, 1.0), LandingDownForce);
		float LaunchForce = LaunchForceCurve.GetFloatValue(LaunchForceAlpha) * MaxVerticalForce;
		FVector LaunchVelocity = LaunchedPlayer.ActorForwardVector + (FVector::UpVector * LaunchForce);
		LaunchedPlayer.SetActorVelocity(LaunchVelocity);
		float ArbitraryPercent = 0.9;
		CrumbFeedback(LaunchedPlayer, LaunchForceAlpha > ArbitraryPercent);

		// Increase amount of vertical impulse pig can inherit when farting
		if (LaunchedPlayer.IsMio())
		{
			// Let player inherit more vertical velocity this launch
			URainbowFartPigSettings::SetMaxVerticalForce(LaunchedPlayer, 1600 * LaunchForceAlpha, this);

			// Revert after a bit
			float FartBlockDuration = Math::Lerp(0.1, 0.6, LaunchForceAlpha);
			Timer::SetTimer(this, n"UnblockFart", FartBlockDuration);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnEffect() {}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnMioLaunchEffect() {}

	UFUNCTION()
	private void UnblockFart()
	{
		URainbowFartPigSettings::ClearMaxVerticalForce(Game::Mio, this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbFeedback(AHazePlayerCharacter LaunchedPlayer, bool bSuccess)
	{
		if (bSuccess)
		{
			BP_SpawnMioLaunchEffect();

			LaunchedPlayer.PlayCameraShake(LaunchCamShake, this);
			LaunchedPlayer.PlayForceFeedback(LaunchFF, false, true, this);
		}

		if (!bSuccessfulJump && !bSuccess)
		{
			FPigLaunchBoardFailedJumpEventHandlerParams EventParams;
			EventParams.Player = LaunchedPlayer;
			++NumFailedJumps;
			EventParams.NumFailedJumps = NumFailedJumps;
			UPigLaunchBoardEventHandler::Trigger_FailedJump(this, EventParams);
		}

		bSuccessfulJump = bSuccessfulJump || bSuccess;
	}
}
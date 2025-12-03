event void FMeltdownFlyingUmbrellaTakeOffSignature();

UCLASS(Abstract)
class USplitTraversalFlyingUmbrellaEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFlying() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopFlying() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlyAway() {}
}

class ASplitTraversalFlyingUmbrella : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsTranslateComponent FantasyTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FantasyTranslateComp)
	UFauxPhysicsConeRotateComponent FantasyRotateComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	UFauxPhysicsWeightComponent FantasyWeightComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	USceneComponent FantasySpinRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent SciFiTranslateRoot;

	UPROPERTY(DefaultComponent, Attach = SciFiTranslateRoot)
	USceneComponent ScifiSpinRoot;

	UPROPERTY(DefaultComponent)
	USplitTraversalTransferFauxWeightComponent TransferWeightComp;
	default TransferWeightComp.TransferToActor = this;

	UPROPERTY(EditInstanceOnly)
	AActor CableActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	FHazeTimeLike SpinSpeedTimeLike;
	default SpinSpeedTimeLike.UseSmoothCurveZeroToOne();
	default SpinSpeedTimeLike.Duration = 2.0;

	UPROPERTY()
	float TargetSpeed = 1000.0;
	float Speed;
	float SplineProgression = 0.0;
	float HeightOffset = 0.0;


	UPROPERTY()
	float BaseSpeed = 400.0;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	FHazeAcceleratedVector AcceleratedLocation;

	TArray<APoleClimbActor> AttachedPoles;

	bool bBothPlayersAttached = false;
	bool bEndOfSpline = false;
	bool bFlyAway = false;
	bool bActivated = false;
	bool bAppearing = false;

	float StartFraction = 0.5;

	float FFProgress;

	TPerPlayer<bool> bPlayerAttached;
	TPerPlayer<bool> bPlayerCancelBlocked;

	UPROPERTY()
	FMeltdownFlyingUmbrellaTakeOffSignature OnTakeOff;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SplineComp = Spline::GetGameplaySpline(CableActor, this);

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto AttachedActor : AttachedActors)
		{
			auto PoleActor = Cast<APoleClimbActor>(AttachedActor);
			
			if (PoleActor != nullptr)
			{
				AttachedPoles.Add(PoleActor);
				PoleActor.OnStartPoleClimb.AddUFunction(this, n"HandlePlayerAttached");
				PoleActor.OnEnterFinished.AddUFunction(this, n"HandlePlayerFinishedPoleEnter");
				PoleActor.OnStopPoleClimb.AddUFunction(this, n"HandlePlayerDetached");
			}
		}

		Speed = BaseSpeed;

		SpinSpeedTimeLike.BindUpdate(this, n"SpinSpeedTimeLikeUpdate");

		AddActorDisable(this);
	}



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActivated)
			return;

		FVector TargetLocation = SplineComp.GetWorldLocationAtSplineFraction(0.0);

		if (bAppearing)
		{
			SplineProgression -= Speed * DeltaSeconds;

			if (SplineProgression <= 0.0)
			{
				Arrived();
				SplineProgression = 0.0;
			}
				
			TargetLocation = SplineComp.GetWorldLocationAtSplineDistance(SplineProgression);
		}

		if (bBothPlayersAttached)
		{
			if (bFlyAway)
			{
				HeightOffset += Speed * DeltaSeconds;
				TargetLocation = SplineComp.GetWorldLocationAtSplineDistance(SplineComp.SplineLength) + FVector::UpVector * HeightOffset;
			}
			else if (!bEndOfSpline)
			{
				SplineProgression += Speed * DeltaSeconds;

				if (SplineProgression >= SplineComp.SplineLength)
				{
					bEndOfSpline = true;
					SplineProgression = SplineComp.SplineLength;
					SpinSpeedTimeLike.Reverse();
					Timer::SetTimer(this, n"Deactivate", 1.0);
				}
				
				TargetLocation = SplineComp.GetWorldLocationAtSplineDistance(SplineProgression);
			}

			else
			{
				TargetLocation = SplineComp.GetWorldLocationAtSplineDistance(SplineComp.SplineLength);
			}
		}
		
		AcceleratedLocation.AccelerateTo(TargetLocation, 4.0, DeltaSeconds);

		FantasyRoot.SetWorldLocation(AcceleratedLocation.Value);
		ScifiRoot.SetWorldLocation(AcceleratedLocation.Value + FVector::ForwardVector * 500000.0);
		
		SciFiTranslateRoot.SetRelativeLocation(FantasyTranslateComp.RelativeLocation);
		SciFiTranslateRoot.SetRelativeRotation(FantasyRotateComp.RelativeRotation);	

		auto DeltaRotation = FRotator(0.0, Speed * DeltaSeconds * 0.5, 0.0);

		ScifiSpinRoot.AddRelativeRotation(DeltaRotation);
		FantasySpinRoot.AddRelativeRotation(DeltaRotation);

		if (bPlayerAttached[Game::Mio] || bPlayerAttached[Game::Zoe])
		{
			float IntensityAlpha = Math::GetMappedRangeValueUnclamped(
				FVector2D(BaseSpeed, TargetSpeed), 
				FVector2D(0.0, 1.0),
				Speed);	
				
			float FFFrequency = Math::Lerp(10.0, 30.0, IntensityAlpha);
			float FFIntensity = Math::Lerp(0.1, 0.5, IntensityAlpha);

			FFProgress += FFFrequency * DeltaSeconds;

			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(FFProgress) * FFIntensity;
			FF.RightMotor = Math::Sin(-FFProgress) * FFIntensity;

			for (auto Player : Game::Players)
			{
				if (bPlayerAttached[Player])
					Player.SetFrameForceFeedback(FF);
			}
		}
	}

	UFUNCTION()
	void Appear()
	{
		RemoveActorDisable(this);
		
		AcceleratedLocation.SnapTo(SplineComp.GetWorldLocationAtSplineFraction(StartFraction));

		FantasyRoot.SetWorldLocation(AcceleratedLocation.Value);
		ScifiRoot.SetWorldLocation(AcceleratedLocation.Value + FVector::ForwardVector * 500000.0);
		
		SciFiTranslateRoot.SetRelativeLocation(FantasyTranslateComp.RelativeLocation);
		SciFiTranslateRoot.SetRelativeRotation(FantasyRotateComp.RelativeRotation);	

		SplineProgression = SplineComp.SplineLength * StartFraction;
		SpinSpeedTimeLike.Play();

		bAppearing = true;
		bActivated = true;
	}

	private void Arrived()
	{
		bAppearing = false;
		SpinSpeedTimeLike.Reverse();
	}

	UFUNCTION()
	private void HandlePlayerAttached(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		TEMPORAL_LOG(this).Event(f"{Player.Player :n} Attached");

		bPlayerCancelBlocked[Player] = true;
		Player.BlockCapabilities(n"PoleClimbExit", this);
		Player.BlockCapabilities(PlayerPoleClimbTags::PoleClimbCancel, this);
		Player.BlockCapabilities(PlayerPoleClimbTags::PoleClimbJumpOut, this);
	}

	UFUNCTION()
	private void HandlePlayerFinishedPoleEnter(AHazePlayerCharacter Player,
	                                           APoleClimbActor PoleClimbActor)
	{
		bPlayerAttached[Player] = true;

		TEMPORAL_LOG(this).Event(f"{Player.Player :n} Finished Enter");

		// Don't allow the player to exit the pole until the handshake has confirmed that we shouldn't be activating
		if (!Player.HasControl() || !Network::IsGameNetworked())
		{
			if (bPlayerAttached[Player.OtherPlayer])
			{
				TEMPORAL_LOG(this).Event(f"{Player.Player :n} Transmit Activate");
				NetHandshakeActivate(Player);
			}
			else
			{
				TEMPORAL_LOG(this).Event(f"{Player.Player :n} Transmit Allow Cancel");
				NetHandshakeAllowCancel(Player);
			}
		}

		Player.ApplyCameraSettings(CameraSettings, 4.0, this);
	}

	UFUNCTION(NetFunction)
	private void NetHandshakeAllowCancel(AHazePlayerCharacter Player)
	{
		if (bBothPlayersAttached)
			return;

		TEMPORAL_LOG(this).Event(f"{Player.Player :n} Receive Allow Cancel");

		if (bPlayerCancelBlocked[Player])
		{
			Player.UnblockCapabilities(n"PoleClimbExit", this);
			Player.UnblockCapabilities(PlayerPoleClimbTags::PoleClimbCancel, this);
			Player.UnblockCapabilities(PlayerPoleClimbTags::PoleClimbJumpOut, this);
			bPlayerCancelBlocked[Player] = false;
		}
	}

	UFUNCTION(NetFunction)
	private void NetHandshakeActivate(AHazePlayerCharacter Player)
	{
		TEMPORAL_LOG(this).Event(f"{Player.Player :n} Receive Activate");

		if (!bBothPlayersAttached)
			Activate();
	}

	private void Activate()
	{
		if (bBothPlayersAttached)
			return;

		for (auto Player : Game::Players)
		{
			if (!bPlayerCancelBlocked[Player])
			{
				bPlayerCancelBlocked[Player] = true;
				Player.BlockCapabilities(n"PoleClimbExit", this);
				Player.BlockCapabilities(PlayerPoleClimbTags::PoleClimbCancel, this);
				Player.BlockCapabilities(PlayerPoleClimbTags::PoleClimbJumpOut, this);
			}
		}

		AcceleratedLocation.SnapTo(SplineComp.GetWorldLocationAtSplineDistance(0.0));
		bBothPlayersAttached = true;
		bAppearing = false;
		SpinSpeedTimeLike.Play();

		OnTakeOff.Broadcast();

		USplitTraversalFlyingUmbrellaEventHandler::Trigger_OnStartFlying(this);
	}

	UFUNCTION()
	private void SpinSpeedTimeLikeUpdate(float CurrentValue)
	{
		Speed = Math::Lerp(BaseSpeed, TargetSpeed, CurrentValue);
	}

	UFUNCTION()
	private void Deactivate()
	{
		for (auto Player : Game::Players)
		{
			if (bPlayerCancelBlocked[Player])
			{
				Player.UnblockCapabilities(n"PoleClimbExit", this);
				Player.UnblockCapabilities(PlayerPoleClimbTags::PoleClimbCancel, this);
				Player.UnblockCapabilities(PlayerPoleClimbTags::PoleClimbJumpOut, this);
				bPlayerCancelBlocked[Player] = false;
			}
		}

		for (auto Pole : AttachedPoles)
		{
			Pole.bAllowSlidingOff = true;
		}	

		USplitTraversalFlyingUmbrellaEventHandler::Trigger_OnStopFlying(this);

		Timer::SetTimer(this, n"FlyAway", 6.0);
	}

	UFUNCTION()
	private void FlyAway()
	{
		bFlyAway = true;

		SpinSpeedTimeLike.Play();

		for (auto Pole : AttachedPoles)
		{
			Pole.DisablePoleActor();
		}

		Timer::SetTimer(this, n"DelayedDisable", 10.0);

		USplitTraversalFlyingUmbrellaEventHandler::Trigger_OnFlyAway(this);
	}

	UFUNCTION()
	private void HandlePlayerDetached(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		TEMPORAL_LOG(this).Event(f"{Player.Player :n} Detached");

		if (bPlayerCancelBlocked[Player])
		{
			Player.UnblockCapabilities(n"PoleClimbExit", this);
			Player.UnblockCapabilities(PlayerPoleClimbTags::PoleClimbCancel, this);
			Player.UnblockCapabilities(PlayerPoleClimbTags::PoleClimbJumpOut, this);
			bPlayerCancelBlocked[Player] = false;
		}

		if (bPlayerAttached[Player])
		{
			bPlayerAttached[Player] = false;
			Player.ClearCameraSettingsByInstigator(this);

			TEMPORAL_LOG(this).Event(f"{Player.Player :n} Detached");

			if (bBothPlayersAttached)
				FlyAway();
		}
	}

	UFUNCTION()
	private void DelayedDisable()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintPure)
	float GetSplineProgressionAlpha()
	{
		return SplineProgression / SplineComp.SplineLength;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentSpeed() const
	{
		return Speed;
	}

};
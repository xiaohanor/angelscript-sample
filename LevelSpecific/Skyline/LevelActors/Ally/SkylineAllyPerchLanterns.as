class ASkylineAllyPerchLanterns : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	USceneComponent LanternPivotRotationComp;

	UPROPERTY(DefaultComponent, Attach = LanternPivotRotationComp)
	USceneComponent LanternPivotPitchComp;

	UPROPERTY(DefaultComponent, Attach = LanternPivotPitchComp, ShowOnActor)
	UPerchPointComponent PerchPointUpComp;
	default PerchPointUpComp.bAllowGrappleToPoint = false;
	default PerchPointUpComp.AdditionalGrappleRange = 0.0;

	UPROPERTY(DefaultComponent, Attach = PerchPointUpComp)
	UPerchEnterByZoneComponent EnterZoneUp;

	UPROPERTY(DefaultComponent, Attach = LanternPivotPitchComp, ShowOnActor)
	UPerchPointComponent PerchPointDownComp;
	default PerchPointUpComp.bAllowGrappleToPoint = false;
	default PerchPointUpComp.AdditionalGrappleRange = 0.0;

	UPROPERTY(DefaultComponent, Attach = PerchPointDownComp)
	UPerchEnterByZoneComponent EnterZoneDown;

	UPROPERTY(Category = Settings)
	UAnimSequence UnstablePerchAnim;

	UPROPERTY(Category = Settings)
	float PlayerForce = 50.0;

	UPROPERTY(Category = Settings)
	FHazeTimeLike UnstableTimeLike;
	default UnstableTimeLike.UseLinearCurveZeroToOne();
	default UnstableTimeLike.Duration = 4.0;

	FHazeTimeLike HoverTimeLike;
	default HoverTimeLike.UseSmoothCurveZeroToOne();
	default HoverTimeLike.bFlipFlop = true;
	default HoverTimeLike.Duration = 2.0;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = PerchPointUpComp)
	UPerchPointDrawComponent DrawUpComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointDownComp)
	UPerchPointDrawComponent DrawDownComp;
#endif

	bool bTopPerched = false;
	bool bBottomPerched = false;
	bool bStable = false;

	float RotationSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointUpComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandleBeginPerchUp");
		PerchPointUpComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"HandleEndPerchUp");
		PerchPointDownComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandleBeginPerchDown");
		PerchPointDownComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"HandleEndPerchDown");
		UnstableTimeLike.BindUpdate(this, n"UnstableTimeLikeUpdate");
		UnstableTimeLike.BindFinished(this, n"UnstableTimeLikeFinished");
		HoverTimeLike.BindUpdate(this, n"HoverTimeLikeUpdate");
		HoverTimeLike.SetNewTime(Math::RandRange(0.0, 2.0));
		HoverTimeLike.Play();
	}

	UFUNCTION()
	private void HoverTimeLikeUpdate(float CurrentValue)
	{
		LanternPivotRotationComp.SetRelativeLocation(FVector::UpVector * CurrentValue * 40.0);
	}

	UFUNCTION()
	private void UnstableTimeLikeFinished()
	{
		if (!UnstableTimeLike.IsReversed())
		{
			PerchPointUpComp.Disable(this);
			PerchPointDownComp.Disable(this);

			if (bTopPerched)
				BlockPlayerJumpOff(Game::Zoe, false);
			else if (bBottomPerched)
				BlockPlayerJumpOff(Game::Mio, false);
			else
				PrintToScreen("Completed unstable timelike without any player on the lantern", 5.0, FLinearColor::Red);

			Timer::SetTimer(this, n"EnablePerchPoints", 1.0);
		}
	}

	UFUNCTION()
	private void UnstableTimeLikeUpdate(float CurrentValue)
	{
		PlayerForce = CurrentValue * 500.0;
		LanternPivotPitchComp.SetRelativeRotation(FRotator(CurrentValue * 50.0, 0.0, 0.0));
		RotationSpeed = CurrentValue * 200.0;
	}

	UFUNCTION()
	private void EnablePerchPoints()
	{
		PerchPointUpComp.Enable(this);
		PerchPointDownComp.Enable(this);
	}

	UFUNCTION()
	private void HandleBeginPerchDown(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		bBottomPerched = true;
		UpdateStability(Player);
	}

	UFUNCTION()
	private void HandleBeginPerchUp(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		bTopPerched = true;
		UpdateStability(Player); 
	}

	UFUNCTION()
	private void HandleEndPerchDown(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		bBottomPerched = false;
		UpdateStability(Player);
	}

	UFUNCTION()
	private void HandleEndPerchUp(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		bTopPerched = false;
		UpdateStability(Player);
	}

	UFUNCTION()
	private void UpdateStability(AHazePlayerCharacter Player)
	{
		if ((bTopPerched && bBottomPerched) || (!bTopPerched && !bBottomPerched))
		{
			FauxPhysicsTranslateComponent.SpringStrength = 10.0;
			UnstableTimeLike.SetPlayRate(3.0);
			UnstableTimeLike.Reverse();

			if (bTopPerched && bBottomPerched)	//Makes the lantern stable if both players perches at the same time
			{
				bStable = true;
				//Enables jumping for the players
				BlockPlayerJumpOff(Game::Mio, false);
				BlockPlayerJumpOff(Game::Zoe, false);
			}
			else	//Removes stability if both players have left the lantern
			{
				bStable = false;
				Player.StopSlotAnimationByAsset(UnstablePerchAnim);

				float ForceMultiplier = 1.0;
				if (Player == Game::Zoe)
					ForceMultiplier = -1.0;
				FauxPhysicsTranslateComponent.ApplyImpulse(Player.ActorLocation, FVector::UpVector * ForceMultiplier * 1000.0);
				PrintToScreenScaled("Impulse applied", 3.0);

				BlockPlayerJumpOff(Player, false);
			}
		}
		else if (!bStable) //Makes lantern wobble and player unable to jump if it is unstable
		{
			FauxPhysicsTranslateComponent.SpringStrength = 0.0;
			UnstableTimeLike.SetPlayRate(1.0);
			UnstableTimeLike.Play();

			if (bTopPerched)
			{
				BlockPlayerJumpOff(Game::Zoe, true);
			}
			else
			{
				BlockPlayerJumpOff(Game::Mio, true);
			}
		}
	}

	UFUNCTION()
	private void BlockPlayerJumpOff(AHazePlayerCharacter Player, bool bBlock)
	{
		if (bBlock && !Player.IsCapabilityTagBlocked(PlayerPerchPointTags::PerchPointJumpTo))
		{
			Player.BlockCapabilities(PlayerPerchPointTags::PerchPointJumpTo, this);

			UPlayerJumpSettings::SetPerchImpulse(Player, 75, this);

			FHazeSlotAnimSettings SlotSettings;
			Player.PlaySlotAnimation(UnstablePerchAnim, SlotSettings);
		}
		else if (!bBlock && Player.IsCapabilityTagBlocked(PlayerPerchPointTags::PerchPointJumpTo))
		{
			Player.UnblockCapabilities(PlayerPerchPointTags::PerchPointJumpTo, this);

			UPlayerJumpSettings::ClearPerchImpulse(Player, this);

			Player.StopSlotAnimationByAsset(UnstablePerchAnim);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTopPerched)
		{
			FauxPhysicsTranslateComponent.ApplyForce(PerchPointUpComp.WorldLocation, ActorUpVector * -1.0 * PlayerForce);
		}

		if (bBottomPerched)
		{
			FauxPhysicsTranslateComponent.ApplyForce(PerchPointDownComp.WorldLocation, ActorUpVector * PlayerForce);
		}

		LanternPivotRotationComp.AddRelativeRotation(FRotator(0.0, RotationSpeed * DeltaSeconds, 0.0));
	}
};
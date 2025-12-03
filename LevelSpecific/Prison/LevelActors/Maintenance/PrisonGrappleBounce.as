event void FPrisonGrappleBounceEvent(AHazePlayerCharacter Player);
delegate bool FPrisonGrappleBounceEnabledDelegate();

UCLASS(Abstract)
class APrisonGrappleBounce : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;

	/**
	 * This component is absolute to prevent the perch code to follow
	 */
	UPROPERTY(DefaultComponent)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchEnterByZoneComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000;

	UPROPERTY(EditInstanceOnly, Category = "Grapple Bounce")
	bool bDisable = false;

	UPROPERTY(EditInstanceOnly, Category = "Grapple Bounce")
	float LaunchVelocity = 1500;

	UPROPERTY(EditInstanceOnly, Category = "Grapple Bounce")
	float VerticalLaunchVelocity = 0;

	UPROPERTY(EditInstanceOnly, Category = "Grapple Bounce")
	float PlayerDirectionVelocity = 500;

	UPROPERTY(EditDefaultsOnly, Category = "Grapple Bounce")
	FVector PerchPointRelativeLocation = FVector(0, 0, -10);

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter CurrentBouncePlayer;

	UPROPERTY(Category = "Grapple Bounce")
	FPrisonGrappleBounceEvent OnPlayerBounced;

	UPROPERTY(Category = "Grapple Bounce")
	FPrisonGrappleBounceEnabledDelegate ConditionDelegate;
	private bool bIsDisabledByCondition = false;

	UPROPERTY(EditInstanceOnly, Category = "Grapple Bounce")
	bool bAbsolutePerchPoint = false;
	private bool bInitializedGrapplePointLocation = false;

	TPerPlayer<bool> bBlockedDash;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bDisable)
			Disable(this);

		InitializeGrapplePointLocation();
		
		PerchPointComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		PerchPointComp.OnGrappleHookReachedGrapplePointEvent.AddUFunction(this, n"OnGrappleHookReachedGrapplePoint");
		PerchPointComp.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrapplingToPoint");
		PerchPointComp.OnPlayerInterruptedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerInterruptedGrapplingToPoint");

		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnStartedPerching");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ConditionDelegate.IsBound())
		{
			if(ConditionDelegate.Execute())
			{
				if(bIsDisabledByCondition)
				{
					Enable(FInstigator(n"ConditionDelegate"));
					bIsDisabledByCondition = false;
				}
			}
			else
			{
				if(!bIsDisabledByCondition)
				{
					Disable(FInstigator(n"ConditionDelegate"));
					bIsDisabledByCondition = true;
				}
			}
		}
		else if(CurrentBouncePlayer != nullptr)
		{
			if(!PerchPointComp.bIsPlayerGrapplingToPoint[CurrentBouncePlayer] && !PerchPointComp.IsPlayerOnPerchPoint[CurrentBouncePlayer])
			{
				// The grapple or perch failed
				BP_OnGrappleHookInterrupted();
				CurrentBouncePlayer = nullptr;
			}
		}
		else
		{
			SetActorTickEnabled(false);
		}
	}

	/**
	 * Place the perch point component where it should be.
	 * Required since some perch points are absolute.
	 */
	void InitializeGrapplePointLocation()
	{
		if(bInitializedGrapplePointLocation)
			return;

		if(bAbsolutePerchPoint)
		{
			PerchPointComp.SetAbsolute(true, true, true);
			PerchPointComp.SetWorldLocationAndRotation(
				Root.WorldTransform.TransformPosition(PerchPointRelativeLocation),
				Root.WorldRotation
			);
		}
		else
		{
			PerchPointComp.SetAbsolute(false, false, false);
			PerchPointComp.SetRelativeLocation(PerchPointRelativeLocation);
		}

		bInitializedGrapplePointLocation = true;
	}

	UFUNCTION()
	private void OnPlayerInitiatedGrappleToPoint(
		AHazePlayerCharacter Player,
	    UGrapplePointBaseComponent GrapplePoint)
	{
		if(CurrentBouncePlayer != nullptr)
			return;

		CurrentBouncePlayer = Player;

		// We just started interacting with the grapple bounce, the other player may not use it now.
		DisableForPlayer(Player.OtherPlayer, FInstigator(this, n"Grapple"));


	}

	UFUNCTION()
	private void OnGrappleHookReachedGrapplePoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePoint)
	{
		if(Player != CurrentBouncePlayer)
			return;

		if(!bBlockedDash[Player])
		{
			Player.BlockCapabilities(PlayerMovementTags::Dash, this);
			bBlockedDash[Player] = true;
		}

		BP_OnGrappleHookReachedGrapplePoint();
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnGrappleHookReachedGrapplePoint() {}

	UFUNCTION()
	private void OnPlayerFinishedGrapplingToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePoint)
	{
		if(Player != CurrentBouncePlayer)
			return;

		// Remove the block caused by Grapple
		EnableForPlayer(CurrentBouncePlayer.OtherPlayer, FInstigator(this, n"Grapple"));
	}

	UFUNCTION()
	private void OnPlayerInterruptedGrapplingToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent InterruptedGrapplePoint)
	{
		if(CurrentBouncePlayer != Player)
			return;

		// Remove the block caused by Grapple
		EnableForPlayer(CurrentBouncePlayer.OtherPlayer, FInstigator(this, n"Grapple"));

		if(bBlockedDash[Player])
		{
			Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
			bBlockedDash[Player] = false;
		}

		BP_OnGrappleHookInterrupted();

		CurrentBouncePlayer = nullptr;
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnGrappleHookInterrupted() {}

	UFUNCTION(BlueprintEvent)
	void OnStartedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		// If we have a current bounce player, only allow that player to start perching
		if(CurrentBouncePlayer != nullptr && Player != CurrentBouncePlayer)
			return;

		CurrentBouncePlayer = Player;

		DisableForPlayer(Player.OtherPlayer, FInstigator(this, n"Perch"));

		// Immediately stop perching, since we want to launch!
		Player.BlockCapabilities(PlayerMovementTags::Perch, this);
		Player.UnblockCapabilities(PlayerMovementTags::Perch, this);

		if(bBlockedDash[Player])
		{
			Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
			bBlockedDash[Player] = false;
		}

		BP_OnStartedPerching();
		BouncePlayer(Player);
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnStartedPerching() {}

	void BouncePlayer(AHazePlayerCharacter Player)
	{
		if(!ensure(Player == CurrentBouncePlayer))
			return;

		Player.SetActorVelocity(FVector::ZeroVector);
		Player.AddPlayerLaunchMovementImpulse(GetLaunchImpulse(Player));
		Player.KeepLaunchVelocityDuringAirJumpUntilLanded();
		BP_OnLaunchPlayer(Player);
		OnPlayerBounced.Broadcast(Player);

		EnableForPlayer(CurrentBouncePlayer.OtherPlayer, FInstigator(this, n"Perch"));
		CurrentBouncePlayer = nullptr;
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnLaunchPlayer(AHazePlayerCharacter Player) {}

	private FVector GetLaunchImpulse(AHazePlayerCharacter Player) const
	{
		const FVector PlayerDirectionImpulse = Player.ActorForwardVector * PlayerDirectionVelocity;
		const FVector VerticalImpulse = FVector(0, 0, VerticalLaunchVelocity);
		const FVector LaunchImpulse = ArrowComp.ForwardVector * LaunchVelocity;

		return PlayerDirectionImpulse + VerticalImpulse + LaunchImpulse;
	}

	UFUNCTION(BlueprintCallable)
	void Enable(FInstigator Instigator)
	{
		PerchEnterByZoneComp.EnableTrigger(Instigator);
		PerchPointComp.Enable(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void Disable(FInstigator Instigator)
	{
		PerchEnterByZoneComp.DisableTrigger(Instigator);
		PerchPointComp.Disable(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		PerchEnterByZoneComp.EnableTriggerForPlayer(Player, Instigator);
		PerchPointComp.EnableForPlayer(Player, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		PerchEnterByZoneComp.DisableTriggerForPlayer(Player, Instigator);
		PerchPointComp.DisableForPlayer(Player, Instigator);
	}
};
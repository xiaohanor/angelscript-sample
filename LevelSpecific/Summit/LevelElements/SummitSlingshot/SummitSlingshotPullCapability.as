
class USummitSlingshotPullCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;

	ASummitSlingshot Slingshot;

	UPlayerTailTeenDragonComponent DragonComp;
	//ATeenDragon TeenDragon;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	FVector PullSpeed;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Slingshot = Cast<ASummitSlingshot>(Params.Interaction.Owner);
		Slingshot.StartPulling();

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		//TeenDragon = DragonComp.TeenDragon;

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		if (Slingshot.Camera != nullptr)
			Player.ActivateCamera(Slingshot.Camera, 2.0, this);

		Player.SmoothTeleportActor(Params.Interaction.WorldLocation, Params.Interaction.WorldRotation, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		
		if (Slingshot.Camera != nullptr)
			Player.DeactivateCamera(Slingshot.Camera, 2.0);

		DragonComp.AnimationState.Clear(this);
		Player.SetActorVelocity(FVector::ZeroVector);
		Slingshot.StopPulling();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector WantedSpeed = MoveComp.MovementInput * Slingshot.BasketMovementSpeed;
				
				if (WantedSpeed.Size() <= 0.0)
					PullSpeed = FVector::ZeroVector;
				else
					PullSpeed = Math::VInterpConstantTo(PullSpeed, WantedSpeed, DeltaTime, Slingshot.BasketAcceleration);

				Slingshot.MovePullDelta(PullSpeed * DeltaTime);

				FVector TargetPos = Slingshot.PullInteraction.WorldLocation;

				Movement.AddDelta(TargetPos - Player.ActorLocation);
				Movement.SetRotation(Slingshot.PullInteraction.WorldRotation);
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(n"SummitSlingshotPull");
		}
	}
};
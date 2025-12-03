class UForgePipeTravelCapability : UInteractionCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;


	AForgePipeInteraction ForgePipe;
	//ATeenDragon TeenDragon;


	float MoveSpeed = 8000.0;
	float CurrentDistance;
	float TargetDistance;
	float CurrentMoveSpeed;

	UHazeSplineComponent SplineComp;

	UForgePipePlayerLaunchComponent PipeComp;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		
		Super::OnActivated(Params);

		ForgePipe = Cast<AForgePipeInteraction>(Params.Interaction.Owner);
		//TeenDragon = UPlayerTailTeenDragonComponent::Get(Player).TeenDragon;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);

		PipeComp = UForgePipePlayerLaunchComponent::Get(Player);
		SplineComp = ForgePipe.SplineComp;


		if(ForgePipe.bAtStart)
		{
			CurrentDistance = 0.0;
			TargetDistance = SplineComp.GetSplineLength();
			CurrentMoveSpeed = MoveSpeed;
		}
		else
		{
			CurrentDistance = SplineComp.GetSplineLength();
			TargetDistance = 0.0;
			CurrentMoveSpeed = -MoveSpeed;

		}
				
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);

		if(PipeComp.bCanLaunch && PipeComp.bIsAtStart != ForgePipe.bAtStart)
		{
			Player.AddMovementImpulse(PipeComp.LaunchVelocity, n"PipeLaunch");
			PipeComp.bCanLaunch = false;
		}
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.ActorLocation = ForgePipe.SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);
		CurrentDistance += DeltaTime * CurrentMoveSpeed;
		float DistanceFromTarget = Math::Abs(TargetDistance - CurrentDistance);
		CurrentDistance = Math::Clamp(CurrentDistance, 0.0, SplineComp.GetSplineLength());

		if(CurrentDistance == TargetDistance)
		{
			PlayerInteractionsComp.KickPlayerOutOfInteraction(ForgePipe.InteractComp);
			
		}
	}

}
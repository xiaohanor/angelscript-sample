/**
 * Sit around, unless the player is close, then start rotating towards the player
 */
class UCongaLineMonkeyIdleCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	
	ACongaLineMonkey Monkey;
	UCongaLineDancerComponent DancerComp;

	UHazeMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ACongaLineMonkey>(Owner);
		DancerComp = UCongaLineDancerComponent::Get(Owner);

		MoveComp = UHazeMovementComponent::Get(Monkey);
		MoveData = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DancerComp.CurrentState = ECongaLineDancerState::Idle;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			AHazePlayerCharacter ClosestPlayer = Monkey.GetClosestPlayerWithinReactionRange();
			if(ClosestPlayer != nullptr)
			{
				if(ClosestPlayer.IsMio() == (Monkey.ColorCode == EMonkeyColorCode::Mio))
				{
					const FVector DirectionToMonkey = ClosestPlayer.GetActorLocation() - Monkey.ActorLocation;
					const FQuat RotationToMonkey = FQuat::MakeFromX(DirectionToMonkey);
					MoveData.InterpRotationTo(RotationToMonkey, 2, false);
				}
			}
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
};
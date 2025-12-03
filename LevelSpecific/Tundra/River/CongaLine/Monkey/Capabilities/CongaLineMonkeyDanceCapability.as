/**
 * Handle moving along the conga line spline
 */
class UCongaLineMonkeyDanceCapability : UHazeChildCapability
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

		if(!DancerComp.IsInCongaLine())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!DancerComp.IsInCongaLine())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(DancerComp.IsEnteringCongaLine())
		{
			DancerComp.EnterCongaLine();
			UCongaLineMonkeyEventHandler::Trigger_OnEntered(Monkey);
		}

		DancerComp.CurrentState = ECongaLineDancerState::Dancing;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!CongaLine::IsCongaLineActive())
			return;
		
		if(DancerComp.IsInCongaLine())
			DancerComp.ExitCongaLine(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			FTransform SplineTransform = DancerComp.GetDanceTransform();

			FVector Location = Owner.ActorLocation;
			float InterpSpeed = (CongaLine::DefaultMoveSpeed + DancerComp.CurrentLeader.GetSpeedBonus()) * 1.5;
			Location = Math::VInterpConstantTo(Location, SplineTransform.Location, DeltaTime, InterpSpeed);

			FVector Delta = Location - Owner.ActorLocation;
			
			// for(int i = 0; i < DancerComp.CurrentLeader.SplineHitWallLocations.Num(); i++)
			// {
			// 	FVector HitWallLocation = DancerComp.CurrentLeader.SplineHitWallLocations[i];

			// 	//Continue if point has already been passed
			// 	if((HitWallLocation - Owner.ActorLocation).DotProduct(Delta.GetSafeNormal()) < 0)
			// 		continue;

			// 	//Continue if point will not be passed this frame
			// 	if((HitWallLocation - Location).DotProduct(Delta.GetSafeNormal()) > 0)
			// 		continue;
					
			// 	DancerComp.TimeSinceWallHit = 0;
			// }


			MoveData.AddDelta(Delta);

			FVector RotationTarget = (SplineTransform.Location + SplineTransform.Rotation.ForwardVector * 50) - Owner.ActorLocation;

			MoveData.InterpRotationTo(FQuat::MakeFromX(RotationTarget), 10);
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
};
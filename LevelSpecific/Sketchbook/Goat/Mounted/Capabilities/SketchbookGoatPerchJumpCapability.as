struct FSketchbookGoatPerchJumpActivatedParams
{
	ASketchbookGoatPerchJumpZone JumpZone;
	bool bWasForced;
}

class USketchbookGoatPerchJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(Sketchbook::Goat::Tags::SketchbookGoat);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 0;

	const float JumpBufferTime = 0.2;

	ASketchbookGoat Goat;
	USketchbookGoatSplineMovementComponent SplineComp;

	UHazeMovementComponent MoveComp;
	USimpleMovementData MoveData;

	bool bFinished = false;
	float JumpDuration = 0;
	FTraversalTrajectory JumpTrajectory;
	FSplinePosition SplinePosition;

	TArray<ASketchbookGoatPerchPoint> JumpPoints;
	bool bReachedEnd = false;

	bool bIsBackwards = false;
	int JumpIncrement = 1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Goat = Cast<ASketchbookGoat>(Owner);
		SplineComp = USketchbookGoatSplineMovementComponent::Get(Goat);
		
		MoveComp = UHazeMovementComponent::Get(Goat);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookGoatPerchJumpActivatedParams& Params) const
	{
		if(Goat.JumpZone == nullptr)
			return false;

		if(Goat.bPerchJumping)
		{
			Params.JumpZone = Goat.JumpZone;
			Params.bWasForced = Goat.bPerchWasForced;
			return true;
		}

		if(SplineComp.IsInAir())
			return false;

		if(!IsActioning(ActionNames::MovementJump))
			return false;

		if(Goat.RootOffsetComp.ForwardVector.DotProduct(Goat.JumpZone.ActorForwardVector) < 0.5)
			return false;

		Params.JumpZone = Goat.JumpZone;
		Params.bWasForced = Goat.bPerchWasForced;
 		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bFinished)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookGoatPerchJumpActivatedParams Params)
	{
		JumpIncrement = 1;
		Goat.bPerchJumping = true;
		Goat.JumpZone = Params.JumpZone;
		bIsBackwards = Params.JumpZone.bIsBackwards;
		JumpPoints = Goat.JumpZone.JumpPoints;
		bFinished = false;

 		if(Params.bWasForced)
		{
			Goat.SetAnimBoolParam(n"LandedOnPerch", true);
			Goat.bPerchWasForced = false;
			bReachedEnd = true;
		}
		else
		{
			Goat.PerchPointIndex = 1;
			CalculateTrajectory();
			bReachedEnd = false;
		}

		Goat.PreviousJumpZone = Goat.JumpZone;
		Goat.JumpZone = nullptr;

		//Goat.MountedPlayer.OtherPlayer.BlockCapabilities(CapabilityTags::Respawn, this);
		Goat.GetGoatSplineMoveComp().bCanExitAir = false;
		Goat.SetAnimTrigger(n"Jump");

		if(HasControl())
			CrumbSetPerchPointIndex(Goat.PerchPointIndex);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Goat.bPerchJumping = false;
		Goat.PreviousJumpZone = nullptr;
		Goat.GetGoatSplineMoveComp().bCanExitAir = true;
		Goat.SetAnimBoolParam(n"LandedOnPerch", false);
		//Goat.MountedPlayer.OtherPlayer.UnblockCapabilities(CapabilityTags::Respawn, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//idk why i have to do this
		Goat.bPerchJumping = true;

		if(!MoveComp.PrepareMove(MoveData, FVector::UpVector))
			return;

		if(HasControl())
		{
			if(bReachedEnd)
			{
				float HorizontalInput = GetAttributeFloat(AttributeNames::LeftStickRawX);
				if(!Math::IsNearlyZero(HorizontalInput))
				{
					FRotator Rotation = FRotator::MakeFromXZ(FVector::RightVector * HorizontalInput, FVector::UpVector);
					//Debug::DrawDebugArrow(Goat.ActorLocation, Goat.ActorLocation + Rotation.ForwardVector * 100);
					MoveData.SetRotation(Rotation);

					JumpIncrement = HorizontalInput < 0 ? -1 : 1;
					if(bIsBackwards)
						JumpIncrement *= -1;
				}
				if(Goat.PerchPointIndex+1 >= JumpPoints.Num() || Goat.PerchPointIndex == 0)
				{
					bFinished = true;
				}
				else
				{
					if(WasActionStartedDuringTime(ActionNames::MovementJump, JumpBufferTime))
					{
  						CrumbSetLandedOnPerch(false);
						Goat.PerchPointIndex += JumpIncrement;
						CrumbSetPerchPointIndex(Goat.PerchPointIndex);
						CrumbSetAnimationTriggers(Goat.PerchPointIndex);
						CalculateTrajectory();
						bReachedEnd = false;
					}
				}
			}
			else
			{
				FRotator Rotation = FRotator::MakeFromXZ(Goat.ActorForwardVector, FVector::UpVector);
				MoveData.SetRotation(Rotation);

				JumpDuration += Sketchbook::Goat::PerchJumpSpeed * DeltaTime;
				//JumpTrajectory.DrawDebug(FLinearColor::Black, 0);

				if(JumpDuration >= JumpTrajectory.GetTotalTime())
				{
					JumpDuration = JumpTrajectory.GetTotalTime();
					bReachedEnd = true;
					CrumbSetLandedOnPerch(true);
				}

				const FVector Location = JumpTrajectory.GetLocation(JumpDuration);
				const FVector Delta = Location - Owner.ActorLocation;
				MoveData.AddDelta(Delta);
			}
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetPerchPointIndex(int NewIndex)
	{
		Goat.PerchPointIndex = NewIndex;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetLandedOnPerch(bool bLanded)
	{
		Goat.SetAnimBoolParam(n"LandedOnPerch", bLanded);
		Goat.MountedPlayer.PlayForceFeedback(Goat.JumpForceFeedback,false,false,this,1);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetAnimationTriggers(int PerchIndex)
	{
		Goat.SetAnimIntParam(n"PerchPointIndex", PerchIndex);
		Goat.SetAnimTrigger(n"Jump");
	}

	void CalculateTrajectory()
	{
 		JumpDuration = 0;

		const float Gravity = 3;

		JumpTrajectory.LaunchLocation = Owner.ActorLocation;
		JumpTrajectory.LandLocation = JumpPoints[Goat.PerchPointIndex].ActorLocation;
		JumpTrajectory.Gravity = FVector::DownVector * Gravity;
		JumpTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(JumpTrajectory.LaunchLocation, JumpTrajectory.LandLocation, Gravity, Sketchbook::Goat::PerchJumpSpeed);
	}
};
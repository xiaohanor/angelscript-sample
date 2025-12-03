struct FCongaLineMonkeyEnterDeactivateParams
{
	bool bReachedCongaLine = false;
};

/**
 * Navigate towards the conga line spline
 */
class UCongaLineMonkeyEnterCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	ACongaLineMonkey Monkey;
	UCongaLineDancerComponent DancerComp;
	ACongaLineManager Manager;

	UHazeMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	FHazeRuntimeSpline NavigationSpline;
	float DistanceAlongSpline = 0;
	float LastUpdateSplineTime = 0;
	bool DevForceDance = false;
	bool bHasBeenCollected = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ACongaLineMonkey>(Owner);
		DancerComp = UCongaLineDancerComponent::Get(Owner);
		Manager = CongaLine::GetManager();

		MoveComp = UHazeMovementComponent::Get(Monkey);
		MoveData = MoveComp.SetupTeleportingMovementData();

	}

	UFUNCTION()
	private void DevAddToLine()
	{
		if(IsActive())
			return;
		
		DevForceDance = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DevForceDance)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!CongaLine::IsCongaLineActive())
			return false;

		if(DancerComp.IsInCongaLine())
			return false;

		// if(DancerComp.CurrentLeader == nullptr)
		// 	return false;

		AHazePlayerCharacter ClosestPlayer = Monkey.GetClosestPlayerWithinPickupRange();		
		if(ClosestPlayer == nullptr)
			return false;

		if(ClosestPlayer.IsMio() != (Monkey.ColorCode == EMonkeyColorCode::Mio))
			return false;

		//const bool bWithinRange = Monkey.IsWithinEnterRange();

		// #if EDITOR
		// if(CongaLine::bVisualizeStartEnteringRange)
		// {
		// 	const FLinearColor Color = bWithinRange ? FLinearColor::Green : FLinearColor::Red;
		// 	Debug::DrawDebugCircle(Owner.ActorLocation, CongaLine::StartEnteringCongaLineRange, 12, Color, 10, Duration = 2);
		// }
		// #endif

		// if(!bWithinRange)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FCongaLineMonkeyEnterDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(Monkey.ActorLocation.Distance(DancerComp.GetDanceTransform().Location) < CongaLine::EnterCongaLineRange)
		{
			Params.bReachedCongaLine = true;
			return true;
		}

		if(!DancerComp.IsEnteringCongaLine())
			return true;

		if(DancerComp.IsInCongaLine())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DevForceDance = false;

		DancerComp.StartEnteringCongaLine();
		DancerComp.CurrentState = ECongaLineDancerState::Entering;

		FTransform SplineTransform = DancerComp.GetDanceTransform();
		NavigationSpline = DancerComp.CalculateNavigationPath(Owner.ActorLocation, SplineTransform.Location);
		NavigationSpline.SetPoint(SplineTransform.Location, NavigationSpline.Points.Num() - 1);
		DistanceAlongSpline = 0;
		LastUpdateSplineTime = Time::GameTimeSeconds;

		UCongaLineMonkeyEventHandler::Trigger_OnStartEntering(Monkey);

		//if(!bHasBeenCollected)
		{
			//CongaLine::GetManager().CollectMonkey(Monkey.ColorCode);
			bHasBeenCollected = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCongaLineMonkeyEnterDeactivateParams Params)
	{
		if(Params.bReachedCongaLine)
		{
			DancerComp.EnterCongaLine();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			const bool bIsStrikingPose = ActiveDuration < CongaLine::EnteringStrikePoseDuration;

			if(bIsStrikingPose)
			{
				const FVector DirectionToMonkey = Owner.ActorLocation - Monkey.ActorLocation;
				const FQuat RotationToMonkey = FQuat::MakeFromX(DirectionToMonkey);
				MoveData.InterpRotationTo(RotationToMonkey, 2, false);
			}
			else
			{
				FTransform SplineTransform = DancerComp.GetDanceTransform();
				
				if(Time::GetGameTimeSince(LastUpdateSplineTime) > 0.5)
				{
					NavigationSpline = DancerComp.CalculateNavigationPath(Owner.ActorLocation, SplineTransform.Location);
					DistanceAlongSpline = 0;
					LastUpdateSplineTime = Time::GameTimeSeconds;
				}

				NavigationSpline.SetPoint(SplineTransform.Location, NavigationSpline.Points.Num() - 1);

				DistanceAlongSpline = Math::FInterpConstantTo(DistanceAlongSpline, NavigationSpline.Length, DeltaTime, CongaLine::DancerEnterSpeed + DancerComp.CurrentLeader.GetSpeedBonus());

				FVector Location = FVector::ZeroVector;
				if(DistanceAlongSpline > NavigationSpline.Length - 1)
				{
					Location = Math::VInterpConstantTo(Owner.ActorLocation, SplineTransform.Location, DeltaTime, CongaLine::DancerEnterSpeed + DancerComp.CurrentLeader.GetSpeedBonus());

					FVector Delta = Location - Owner.ActorLocation;

					MoveData.AddDelta(Delta);
					MoveData.InterpRotationTo(FQuat::MakeFromX(Delta), 5);
				}
				else
				{
					Location = NavigationSpline.GetLocationAtDistance(DistanceAlongSpline + 100);

					FVector Direction = (Location - Owner.ActorLocation).GetSafeNormal();
					FVector Delta = Direction * (CongaLine::DancerEnterSpeed + DancerComp.CurrentLeader.GetSpeedBonus()) * DeltaTime;

					MoveData.AddDelta(Delta);
					MoveData.InterpRotationTo(FQuat::MakeFromX(Delta), 5);
				}
			}
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
};
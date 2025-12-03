

struct FPlayerSplineLockBestSplinePickerInternalCollectData
{
	ASplineActor BestSpline = nullptr;
	APlayerSplineLockZone BestZone = nullptr;
}

class UPlayerSplineLockBestSplinePickerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SplineLock");

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UPlayerMovementComponent MoveComponent;
	UPlayerSplineLockComponent SplineLockComponent;

	FVector LastWorldUp = FVector::UpVector;
	ASplineActor CurrentSplineActor;
	float BiggestDistance = 0;
	float LastBiggestDistanceUpdate = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
		SplineLockComponent = UPlayerSplineLockComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if (Player.IsPlayerDead())
			return false;

		if(SplineLockComponent.ActiveSplineZones.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;

		if (Player.IsPlayerDead())
			return true;

		if(SplineLockComponent.ActiveSplineZones.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastWorldUp = Player.GetMovementWorldUp();

		if(HasControl())
		{
			TArray<APlayerSplineLockZone> AvailableSplineZones;
			GetAvailableZones(AvailableSplineZones);
			UpdateBiggestDistance(AvailableSplineZones, Player.GetActorLocation());

			FPlayerSplineLockBestSplinePickerInternalCollectData FoundData = GetBestSpline(AvailableSplineZones, Player.GetActorLocation());
			if(IsValid(FoundData.BestSpline))
			{
				CrumbLockSplineMovement(FoundData.BestSpline, FoundData.BestZone);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CrumbUnlockSplineMovement();
		SplineLockComponent.bForceUpdateSplineZoneWithPosition = false;
		SplineLockComponent.SplineZoneUpdatePosition = FVector::ZeroVector;
		CurrentSplineActor = nullptr;
		SplineLockComponent.CurrentSplineZone = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			bool bShouldUpdate = false;

			if(SplineLockComponent.CurrentSplineZone == nullptr
				|| CurrentSplineActor == nullptr
				|| SplineLockComponent.bForceUpdateSplineZoneWithPosition)
			{
				bShouldUpdate = true;
			}
			else if(SplineLockComponent.CurrentSplineZone.UpdateType == EPlayerSplineLockZoneUpdateType::Always)
			{
				bShouldUpdate = true;
			}
			else if(SplineLockComponent.CurrentSplineZone.UpdateType == EPlayerSplineLockZoneUpdateType::OnlyWhileGrounded)
			{
				if(MoveComponent.IsOnAnyGround())
				{
					bShouldUpdate = true;
				}
			}

			if(bShouldUpdate)
			{
				FVector LocationToUse = Player.GetActorLocation();
				if(SplineLockComponent.bForceUpdateSplineZoneWithPosition)
				{
					LocationToUse = SplineLockComponent.SplineZoneUpdatePosition;
					SplineLockComponent.bForceUpdateSplineZoneWithPosition = false;
					SplineLockComponent.SplineZoneUpdatePosition = FVector::ZeroVector;
				}

				TArray<APlayerSplineLockZone> AvailableSplineZones;
				GetAvailableZones(AvailableSplineZones);

				// This is kinda expensive so do it less often
				// this should probably be done one spline at the time instead of
				// a at once every now and then... TODO
				if(Time::GetGameTimeSince(LastBiggestDistanceUpdate) > 1.0)
				{
					UpdateBiggestDistance(AvailableSplineZones, LocationToUse);	
				}

				// Find the best spline
				const FPlayerSplineLockBestSplinePickerInternalCollectData FoundData = GetBestSpline(AvailableSplineZones, LocationToUse);

				if(SplineLockComponent.CurrentSplineZone != nullptr && FoundData.BestZone == nullptr)
				{
					CrumbUnlockSplineMovement();

				}
				else if(CurrentSplineActor != nullptr && FoundData.BestSpline == nullptr)
				{
					CrumbUnlockSplineMovement();
				}
				else if(FoundData.BestSpline != CurrentSplineActor || FoundData.BestZone != SplineLockComponent.CurrentSplineZone)
				{
					CrumbLockSplineMovement(FoundData.BestSpline, FoundData.BestZone);
				}
			}

			LastWorldUp = Player.MovementWorldUp;
		}
		
		// if(CurrentSplineActor != nullptr)
		// {
		// 	Debug::DrawDebugString(Player.GetActorLocation(), "" + CurrentSplineActor.GetName());
		// }
	}

	UFUNCTION(CrumbFunction)
	void CrumbUnlockSplineMovement()
	{
		Player.UnlockPlayerMovementFromSpline(this);
		CurrentSplineActor = nullptr;	
		SplineLockComponent.CurrentSplineZone = nullptr;
	}

	UFUNCTION(CrumbFunction)
	void CrumbLockSplineMovement(ASplineActor SplineActor, APlayerSplineLockZone SplineZone)
	{
		if (SplineActor == nullptr || SplineZone == nullptr) // can happen if in a streamed out level
			return;

		CurrentSplineActor = SplineActor;
		SplineLockComponent.CurrentSplineZone = SplineZone;
		Player.LockPlayerMovementToSpline(CurrentSplineActor, this, 
			EInstigatePriority::Low, 
			SplineLockComponent.CurrentSplineZone.LockProperties,
			SplineLockComponent.CurrentSplineZone.RubberBandSettings, 
			SplineLockComponent.CurrentSplineZone.EnterSettings);
	}

	FPlayerSplineLockBestSplinePickerInternalCollectData GetBestSpline(const TArray<APlayerSplineLockZone>& AvailableSplineZones, FVector PositionToGetSplineAt) const
	{
		const FVector CurrentWorldUp = Player.MovementWorldUp;
		FPlayerSplineLockBestSplinePickerInternalCollectData OutData;

		// We add a little safety if we are on the spline
		const FVector PlayerPosition = Player.GetActorLocation() + CurrentWorldUp;
		//const auto MoveComp = UPlayerMovementComponent::Get(Player);
		//const float PlayerVerticalSize = Math::Max(MoveComp.GetCollisionShape().GetExtent().Z, 1.0);
	
		const float HighestPossibleScore = Math::Max(BiggestDistance, 100.0);
		float BestScore = -1;
		for(auto Zone : AvailableSplineZones)
		{
			for(auto SplineActor : Zone.AvailableSplines)
			{
				auto Spine = SplineActor.Spline;
				const FSplinePosition ClosestPosition = Spine.GetClosestSplinePositionToWorldLocation(PositionToGetSplineAt);
				
				// Invalid plane
				{
					const FVector ConstrainedForward = ClosestPosition.WorldForwardVector.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
					if(ConstrainedForward.IsNearlyZero())
						continue;
				}

				// Invalid plane
				{
					const FVector ConstrainedRight = ClosestPosition.WorldRightVector.VectorPlaneProject(CurrentWorldUp);
					if(ConstrainedRight.IsNearlyZero())
						continue;
				}

				const FVector PlayerDeltaToSpline = ClosestPosition.WorldLocation - PlayerPosition;
				const FVector HorizontalPlayerDeltaToSpline = (ClosestPosition.WorldLocation - PlayerPosition).VectorPlaneProject(CurrentWorldUp);

				float Score = 0;

				// Closer splines have higher score
				float DistanceScore = Math::Lerp(HighestPossibleScore * 0.5, 0.0, Math::Min(PlayerDeltaToSpline.Size() / BiggestDistance, 1.0));
				Score += DistanceScore;

				// Bonus Score for close horizontal
				float HorizontalDistanceScore = Math::Lerp(HighestPossibleScore, 0.0, Math::Min(HorizontalPlayerDeltaToSpline.Size() / BiggestDistance, 1.0));
				Score += HorizontalDistanceScore;

				// Spline that align along the horizontal plane have higher score
				float HorizontalScoreAlpha = 1.0 - Math::Pow(Math::Abs(ClosestPosition.WorldForwardVector.DotProduct(CurrentWorldUp)), 2.0);
				Score *= Math::Lerp(1.0, 10.0, HorizontalScoreAlpha);

				if(Score <= BestScore)
					continue;

				BestScore = Score;
				OutData.BestSpline = SplineActor;
				OutData.BestZone = Zone;
			}
		}

		return OutData;
	}

	void UpdateBiggestDistance(const TArray<APlayerSplineLockZone>& AvailableSplineZones, FVector PositionToGetSplineAt)
	{
		LastBiggestDistanceUpdate = Time::GetGameTimeSeconds();
		BiggestDistance = 0;

		for(auto Zone : AvailableSplineZones)
		{
			for(auto SplineActor : Zone.AvailableSplines)
			{
				auto Spine = SplineActor.Spline;
				const FVector ClosestPosition = Spine.GetClosestSplineWorldLocationToWorldLocation(PositionToGetSplineAt);	
				const float DistSq = ClosestPosition.DistSquared(PositionToGetSplineAt);
				if(DistSq > BiggestDistance)
					BiggestDistance = DistSq;
			}
		}

		BiggestDistance = Math::Max(Math::Sqrt(BiggestDistance), 1.0);
	}

	void GetAvailableZones(TArray<APlayerSplineLockZone>& AvailableSplineZones) const
	{
		if(SplineLockComponent.CurrentSplineZone == nullptr)
		{
			AvailableSplineZones.Append(SplineLockComponent.ActiveSplineZones);
		}
		else
		{
			// Go trough the current one first
			AvailableSplineZones.Add(SplineLockComponent.CurrentSplineZone);

			for(auto Zone : SplineLockComponent.ActiveSplineZones)
			{
				if(Zone == SplineLockComponent.CurrentSplineZone)
					continue;

				AvailableSplineZones.Add(Zone);
			}
		}
	}
}
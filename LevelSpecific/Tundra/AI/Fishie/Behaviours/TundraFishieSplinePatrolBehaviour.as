class UTundraFishieSplinePatrolBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UTundraFishieComponent FishieComp;
	UHazeActorRespawnableComponent RespawnComp;
	UHazeSplineComponent Spline;
	UTundraFishiePatrolComponent PatrolComp;
	UTundraFishieSettings Settings;
	bool bFollowForwards = true;
	bool bReturningToSpline = false;
	FSplinePosition ReturnSplinePosition;
	bool bChasePause;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UTundraFishieSettings::GetSettings(Owner);
		FishieComp = UTundraFishieComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		OnRespawn();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bReturningToSpline = false; // This will teleport us to spline when spawning
		UHazeSplineComponent PrevSpline = Spline;
		
		Spline = nullptr;
		if (FishieComp.PatrolSpline != nullptr)
			Spline = FishieComp.PatrolSpline.Spline;
		if (RespawnComp.SpawnParameters.Spline != nullptr)
			Spline = RespawnComp.SpawnParameters.Spline;
		
		if (PrevSpline != Spline)
			FishieComp.DefaultPatrolPosition = -1.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Spline == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (Spline == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		UBasicAIMovementSettings::SetTurnDuration(Owner, Settings.SplinePatrolTurnDuration, this, EHazeSettingsPriority::Gameplay);
		FishieComp.LastPatrolPosition = Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
		ReturnSplinePosition = FSplinePosition();
		
		if (FishieComp.PatrolDirection == ETundraFishiePatrolDirection::Forward)
			bFollowForwards = true;
		else if (FishieComp.PatrolDirection == ETundraFishiePatrolDirection::Backward)
			bFollowForwards = false;
		else
			bFollowForwards = (FishieComp.LastPatrolPosition.WorldForwardVector.DotProduct(Owner.ActorForwardVector) > 0.0);

		// Keep track of fishies patrolling this spline through patrol comp on spline actor
		if (FishieComp.DefaultPatrolPosition < 0.0)
			FishieComp.DefaultPatrolPosition = FishieComp.LastPatrolPosition.CurrentSplineDistance;
		PatrolComp = UTundraFishiePatrolComponent::GetOrCreate(Spline.Owner);

		// Make sure you register to patrol after setting patrol positions and direction
		PatrolComp.Register(FishieComp, Spline);

		bChasePause = false;
		if (FishieComp.bIsChaseFish && (FishieComp.LastPatrolPosition.CurrentSplineDistance > Spline.SplineLength * 0.5))
		{
			bChasePause = true;
			UBasicAIMovementSettings::SetAirFriction(Owner, 4.0, this, EHazeSettingsPriority::Gameplay);
		}
			
		UAITundraFishieEventHandler::Trigger_OnStartPatrol(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
		
		// Assume we're no longer at spline when we've needed to leave it.
		if (!FishieComp.bIsChaseFish)
			bReturningToSpline = true; 
			
		FishieComp.bIgnoreMovementCollision = false;
		PatrolComp.Unregister(FishieComp);

		UAITundraFishieEventHandler::Trigger_OnStopPatrol(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bReturningToSpline)
		{
			ReturnToSpline(DeltaTime);
			return;
		}

		if (bChasePause && ActiveDuration < 2.0)
			return;

		// Swim, swim, swim along, gently down the spline. Merrily, merrily, merrily, merrily, life is sweet in brine. 
		PatrolComp.UpdatePatrolLoop(Settings.SplinePatrolMovementSpeed, DeltaTime);
		float Speed = Settings.SplinePatrolMovementSpeed;
		float BehindDist;
		if (!bChasePause && (DestinationComp.FollowSplinePosition.CurrentSpline == Spline))
		{
			BehindDist = PatrolComp.GetDistanceToIdeal(FishieComp.DefaultPatrolPosition, FishieComp.LastPatrolPosition.CurrentSplineDistance, Spline.SplineLength * 0.25);
			if (BehindDist > 0.0)
				Speed *= Math::GetMappedRangeValueClamped(FVector2D(50.0, 1000.0), FVector2D(1.0, 4.0), BehindDist);
			else
				Speed *= Math::GetMappedRangeValueClamped(FVector2D(-1000.0, 0.0), FVector2D(0.25, 1.0), BehindDist);
		}
		DestinationComp.MoveAlongSpline(Spline, Speed, bFollowForwards);

		if (DestinationComp.FollowSplinePosition.CurrentSpline != nullptr)
			FishieComp.LastPatrolPosition = DestinationComp.FollowSplinePosition; // Note that this is where we were this tick, not where we want to go.

		if (!Spline.IsClosedLoop() && DestinationComp.IsAtSplineEnd(Spline, Settings.SplinePatrolTurnRange))
		{
			// Turn back!
			bFollowForwards = !bFollowForwards;
		}

		FishieComp.UpdateEating(AnimComp);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector IdealLoc = Spline.GetWorldLocationAtSplineDistance(PatrolComp.GetIdealDistanceAlongSpline(FishieComp.DefaultPatrolPosition));	
			Debug::DrawDebugSphere(IdealLoc, 20, 4, FLinearColor::Yellow, 5.0);
			Debug::DrawDebugLine(IdealLoc, FishieComp.LastPatrolPosition.WorldLocation, FLinearColor::Yellow, 5.0);
		}
#endif 		
	}

	void ReturnToSpline(float DeltaTime)
	{
		// We've been off chasing a player or something, get back!
		ReturnSplinePosition = Spline.GetSplinePositionAtSplineDistance(PatrolComp.GetIdealDistanceAlongSpline(FishieComp.DefaultPatrolPosition));
		FishieComp.bIgnoreMovementCollision = true;

		float Speed = Settings.SplinePatrolMovementSpeed * Math::GetMappedRangeValueClamped(FVector2D(50.0, 1000.0), FVector2D(1.0, 4.0), Owner.ActorLocation.Distance(ReturnSplinePosition.WorldLocation));
		DestinationComp.MoveTowardsIgnorePathfinding(ReturnSplinePosition.WorldLocation, Speed);

		FVector ToReturnLoc = (ReturnSplinePosition.WorldLocation - Owner.ActorLocation);
		float FwdDot = ReturnSplinePosition.WorldForwardVector.DotProduct(ToReturnLoc);
		if ((Math::Abs(FwdDot) < 200.0) && 														// Near along spline?
			((ToReturnLoc - ReturnSplinePosition.WorldForwardVector * FwdDot).Size() < 20.0))	// Near laterally?
		{
			// Near enough, switch over to normal spline following
			bReturningToSpline = false;
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector IdealLoc = Spline.GetWorldLocationAtSplineDistance(PatrolComp.GetIdealDistanceAlongSpline(FishieComp.DefaultPatrolPosition));	
			Debug::DrawDebugSphere(ReturnSplinePosition.WorldLocation, 20, 4, FLinearColor::Purple, 5.0);
			Debug::DrawDebugLine(ReturnSplinePosition.WorldLocation, Owner.ActorLocation, FLinearColor::Purple, 5.0);
			Debug::DrawDebugSphere(IdealLoc, 20, 4, FLinearColor::Yellow, 5.0);
			Debug::DrawDebugLine(IdealLoc, ReturnSplinePosition.WorldLocation, FLinearColor::Yellow, 5.0);
		}
#endif 		
	}
}

class UTundraFishiePatrolComponent : UActorComponent
{
	private TArray<UTundraFishieComponent> Patrol;
	private int iSergeant = -1;
	private UHazeSplineComponent Spline;
	private float BaseDistanceAlongSpline;
	private	uint LastUpdateFrame = 0;

	void Register(UTundraFishieComponent Patroller, UHazeSplineComponent _Spline)
	{
		if (Spline == nullptr) 
			Spline = _Spline;
		check(Spline == _Spline);
		check(!Patrol.Contains(Patroller));

		// Insert sort on ascending patrol position
		int i = 0;
		for (; i < Patrol.Num(); i++)
		{
			if (Patroller.DefaultPatrolPosition < Patrol[i].DefaultPatrolPosition)
				break;
		}
		Patrol.Insert(Patroller, i);

		// Update patrol leader
		if (!Patrol.IsValidIndex(iSergeant))
			iSergeant = i;
		else if (iSergeant >= i)
			iSergeant++;
	}

	void Unregister(UTundraFishieComponent Patroller)
	{
		int iPatroller = Patrol.FindIndex(Patroller);
		if (!ensure(Patrol.IsValidIndex(iPatroller)))
			return;
		Patrol.RemoveAt(iPatroller);	
		if (!Patrol.IsValidIndex(iSergeant))
			iSergeant = Patrol.Num() - 1;
	}

	float GetPatrolSpacingSpeed(UTundraFishieComponent Patroller, float DefaultSpeed)
	{
		// Check position relative to patrol leader to see if we should speed up or slow down
		if (Patrol.Num() < 2)
			return DefaultSpeed;		

		// We currently only support looped splines
		if (!Spline.IsClosedLoop())
			return DefaultSpeed;
		if (Spline.SplineLength < 1.0)
			return 0.0;

		int iCur = Patrol.FindIndex(Patroller);
		if (!ensure(Patrol.IsValidIndex(iCur)))
			return 0.0; // We want to notice this!

		if (!ensure(Patrol.IsValidIndex(iSergeant)))
			return 0.0; // We want to notice this!

		if (iCur == iSergeant)
			return DefaultSpeed; // Leader is always right!	

		// Patrol members should be offset by the same amount as the patrol leader is.
		UTundraFishieComponent Sarge = Patrol[iSergeant];
		float SargeOffset = GetLoopedSplineDistance(Sarge.DefaultPatrolPosition, Sarge.LastPatrolPosition.CurrentSplineDistance);
		float IdealPatrolPos = (Patroller.DefaultPatrolPosition + SargeOffset) % Spline.SplineLength;
		float PatrolPos = Patroller.LastPatrolPosition.CurrentSplineDistance;
		float Delta = GetLoopedSplineDistance(PatrolPos, IdealPatrolPos);
		if (Delta > Spline.SplineLength * 0.5)
			Delta -= Spline.SplineLength; // Ideal position is behind
		FVector2D DeltaRange = FVector2D(0.25, 2.0) * DefaultSpeed;
		FVector2D FactorRange = FVector2D(1.0, 2.0);
		float SpeedFactor = Math::GetMappedRangeValueClamped(DeltaRange, FactorRange, Math::Abs(Delta));
		if (Delta < 0.0)
			return DefaultSpeed / SpeedFactor; // Ideal pos is behind, slow down
		else 	
			return DefaultSpeed * SpeedFactor; // Ideal pos is ahead, speed up
	}

	float GetLoopedSplineDistance(float Behind, float Ahead)
	{
		// TODO: Currently this will only work for looped spline
		float Delta = (Ahead - Behind);
		if (Delta < 0.0)
			return Delta + Spline.SplineLength;
		return Delta;	
	}

	float GetDistanceToIdeal(float IdealOffset, float Current, float AheadThreshold)
	{
		float IdealDistAlongSpline = Math::Wrap(BaseDistanceAlongSpline + IdealOffset, 0.0, Spline.SplineLength);
		float Delta = IdealDistAlongSpline - Current;
		if (Delta < -AheadThreshold) 
			return Delta + Spline.SplineLength;
		return Delta;
	}

	void UpdatePatrolLoop(float MoveSpeed, float DeltaTime)
	{	
		if (Time::FrameNumber == LastUpdateFrame)
			return;
		LastUpdateFrame = Time::FrameNumber;		

		BaseDistanceAlongSpline += MoveSpeed * DeltaTime;
		if (BaseDistanceAlongSpline > Spline.SplineLength)
			BaseDistanceAlongSpline -= Spline.SplineLength;
	} 

	float GetIdealDistanceAlongSpline(float IdealOffset)
	{
		return Math::Wrap(BaseDistanceAlongSpline + IdealOffset, 0.0, Spline.SplineLength);
	}
}

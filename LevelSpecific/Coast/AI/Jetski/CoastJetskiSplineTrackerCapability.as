class UCoastJetskiSplineTrackerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	UCoastJetskiComponent JetskiComp;
	UBasicAIHealthComponent HealthComp;
	float Cooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetskiComp = UCoastJetskiComponent::GetOrCreate(Owner); 		
		HealthComp = UBasicAIHealthComponent::Get(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Note that we currently run this while deploying as well, 
		// so splines are prepared when deplyoment ends.
		if (HealthComp.IsDead())
			return false;
		if (Time::GameTimeSeconds < Cooldown)
			return false;
		if (!JetskiComp.RailPosition.IsValid())
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HealthComp.IsDead())
			return true;
		if (Time::GameTimeSeconds < Cooldown)
			return true;
		if (!JetskiComp.RailPosition.IsValid())
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JetskiComp.SplinePositions.Empty();
		JetskiComp.AheadSplines.Empty();

		TListedActors<ACoastJetskiSplineActor> Splines;
		for (ACoastJetskiSplineActor JetskiSpline : Splines)
		{
			// Match jet ski splines start/end to rail. Should only need doing once
			if (JetskiSpline.Rail != JetskiComp.RailPosition.CurrentSpline)
				JetskiSpline.MatchToRail(JetskiComp.RailPosition.CurrentSpline); 

			if (JetskiComp.RailPosition.CurrentSplineDistance < JetskiSpline.StartAlongRail)
				JetskiComp.AheadSplines.Add(JetskiSpline);
			else if (JetskiComp.RailPosition.CurrentSplineDistance < JetskiSpline.EndAlongRail)
				JetskiComp.SplinePositions.Add(JetskiSpline.Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation));
			// Note that we don't track splines behind us
		}	
		if (JetskiComp.SplinePositions.Num() == 0)
		{
			// Let's hope the splines haven't streamed in yet
			Cooldown = Time::GameTimeSeconds + 1.0;	
			return;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float RailDist = JetskiComp.RailPosition.CurrentSplineDistance;
		for (int i = JetskiComp.AheadSplines.Num() - 1; i >= 0; i--)
		{
			 if (RailDist > JetskiComp.AheadSplines[i].StartAlongRail)
			 {
				// We've passed the start of spline, this is now an actively tracked spline
				JetskiComp.SplinePositions.Add(JetskiComp.AheadSplines[i].Spline.GetSplinePositionAtSplineDistance(0.0));
				JetskiComp.AheadSplines.RemoveAtSwap(i);
			 }	
		}

		for (int i = JetskiComp.SplinePositions.Num() - 1; i >= 0; i--)
		{
			FSplinePosition& Pos = JetskiComp.SplinePositions[i];
			float SplineForwardOffset = Pos.WorldForwardVector.DotProduct(Owner.ActorLocation - Pos.WorldLocation);
			float MaxSpeed = JetskiComp.Train.ActorVelocity.DotProduct(Pos.WorldForwardVector) * 3.0;
			if (!Pos.Move(Math::Clamp(SplineForwardOffset, 0.0, MaxSpeed * DeltaTime)))
			{
				// We've left this spine behind
				JetskiComp.SplinePositions.RemoveAtSwap(i);
			}
		}

#if EDITOR
		//JetskiComp.bHazeEditorOnlyDebugBool = true;
		if (JetskiComp.bHazeEditorOnlyDebugBool)
		{
			FVector Loc = Owner.ActorLocation + FVector(0.0, 0.0, 50.0);
			for (ACoastJetskiSplineActor Spline : JetskiComp.AheadSplines)
			{
				Debug::DrawDebugLine(Loc, Spline.Spline.GetWorldLocationAtSplineFraction(0.0), FLinearColor::Green, 5.0);	
			}

			for (FSplinePosition Pos : JetskiComp.SplinePositions)
			{
				Debug::DrawDebugLine(Loc, Pos.WorldLocation, FLinearColor::Yellow, 10.0);	
				Debug::DrawDebugLine(Pos.WorldLocation, Pos.WorldLocation + FVector(0.0, 0.0, 1000.0), FLinearColor::Yellow, 5.0);	
			}
		}
#endif		
	}
}

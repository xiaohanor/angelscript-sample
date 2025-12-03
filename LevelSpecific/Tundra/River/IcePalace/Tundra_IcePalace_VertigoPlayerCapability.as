asset VertigoPlayerPerchSettings of UPlayerPerchSettings
{
    VertigoPlayerPerchSettings.bOverride_MaxSpeed = true;
    VertigoPlayerPerchSettings.MaxSpeed = 250;

	VertigoPlayerPerchSettings.bOverride_MaxSprintSpeed = true;
	VertigoPlayerPerchSettings.MaxSprintSpeed = 250;
}

class UTundra_IcePalace_VertigoPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UTundra_IcePalace_VertigoPlayerComponent VertigoComp;

	FHazeRuntimeSpline Spline;
	TArray<float> Distances;
	float CurrentAlpha;
	bool bHasSetupSeqForScrubbing = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		VertigoComp = UTundra_IcePalace_VertigoPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(VertigoComp.bCapabilityActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(VertigoComp.bCapabilityActive)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SetSplinePoints();		

		for(int i = 0; i < VertigoComp.VertigoCameraPoints.Num(); i++)
		{
			Distances.Add(Spline.GetSplineDistanceAtSplinePointIndex(i));
		}

		Player.PlayCameraShake(VertigoComp.VertigoCameraShake, this);
		Player.ApplySettings(VertigoPlayerPerchSettings, this, EHazeSettingsPriority::Override);
		Player.BlockCapabilities(n"Sprint", this);
		Player.BlockCapabilities(n"Dash", this);
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopCameraShakeByInstigator(this);
		bHasSetupSeqForScrubbing = false;
		Player.ClearSettingsByInstigator(this);
		Player.UnblockCapabilities(n"Sprint", this);
		Player.UnblockCapabilities(n"Dash", this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SetSplinePoints();

		float CurrentPlayerDistance = Spline.GetClosestSplineDistanceToLocation(Player.ActorLocation);
		
		float Min = 0;
		float Max = 0;
		int Index = 0;

		for(int i = 0; i < Distances.Num(); i++)
		{
			if(CurrentPlayerDistance < Distances[i])
			{
				Min = Distances[i - 1];
				Max = Distances[i];
				Index = i;
				break;
			}
			else
			{
				Min = Distances[Distances.Num() - 2];
				Max = Distances[Distances.Num() - 1];
				Index = Distances.Num() - 1;
			}
		}
		
		float Addition = Distances.FindIndex(Min);
		float TargetAlpha = Math::NormalizeToRange(CurrentPlayerDistance, Min, Max);
		TargetAlpha += Addition;
		CurrentAlpha = Math::FInterpTo(CurrentAlpha, TargetAlpha, DeltaTime, 3);
		
		if(!bHasSetupSeqForScrubbing)
		{
			bHasSetupSeqForScrubbing = true;
			CurrentAlpha = TargetAlpha;
			VertigoComp.VertigoSeq.SetupForScrubbing(CurrentAlpha);
		}

		ScrubVertigoSequence(CurrentAlpha);
	}

	void ScrubVertigoSequence(float Time)
	{
		FMovieSceneSequencePlaybackParams Params;
		Params.Time = Time;
		Params.PositionType = EMovieScenePositionType::Time;
		Params.UpdateMethod = EUpdatePositionMethod::Scrub;
		VertigoComp.VertigoSeq.GetSequencePlayer().SetPlaybackPosition(Params);
	}

	void SetSplinePoints()
	{
		TArray<FVector> Points;
		for(int i = 0; i < VertigoComp.VertigoCameraPoints.Num(); i++)
		{
			Points.Add(VertigoComp.VertigoCameraPoints[i].ActorLocation);
		}
		Spline.SetPoints(Points);
	}
};
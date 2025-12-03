class ABattlefieldHoverboardGrindRespawnPoint : ARespawnPoint
{
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AHazeActor RespawnGrindActor;

	UPROPERTY(EditInstanceOnly, Category = "Setup", Meta = (EditCondition = "MioRespawnGrindActor != nullptr", EditConditionHides))
	bool bSplineIsBackwards = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		
		if(RespawnGrindActor != nullptr)
		{
			UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(RespawnGrindActor);
			if(SplineComp != nullptr)
			{
				auto SplinePos = GetRespawnSplinePosition();
				if(SplinePos.IsSet())
				{
					ActorLocation = SplinePos.Value.WorldLocation;
					ActorRotation = SplinePos.Value.WorldRotation.Rotator();
				}
			}
		}
	}

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		Super::OnRespawnTriggered(Player);
		
		auto SplineComp = UHazeSplineComponent::Get(RespawnGrindActor);
		if(SplineComp == nullptr)
			return;

		auto GrindSplineComp = UBattlefieldHoverboardGrindSplineComponent::Get(RespawnGrindActor);
		if(GrindSplineComp == nullptr)
			return;
		auto SplinePos = GetRespawnSplinePosition();
		if(SplinePos.IsSet())
		{
			auto GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);

			FBattlefieldHoverboardGrindingActivationParams RespawnGrindParams;
			RespawnGrindParams.EnteredGrindSplineComp = GrindSplineComp;
			RespawnGrindParams.SpeedAtActivation = 0.0;
			RespawnGrindParams.StartSplinePos = SplinePos.Value;
			RespawnGrindParams.bActivatedFromRespawn = true;
			GrindComp.RespawnActivationParams.Set(RespawnGrindParams);
		}
	}

	private TOptional<FSplinePosition> GetRespawnSplinePosition() const
	{
		TOptional<FSplinePosition> SplinePosition;

		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(RespawnGrindActor);
		if(SplineComp != nullptr)
		{
			auto SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(ActorLocation);
			if(bSplineIsBackwards)
				SplinePos.ReverseFacing();

			SplinePosition.Set(SplinePos);
		}
		return SplinePosition;
	}
};
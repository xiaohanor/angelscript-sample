class USanctuaryBossMedallion2DPlaneEventCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossMedallion2DPlane Plane;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plane = Cast<ASanctuaryBossMedallion2DPlane>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Game::Mio.IsAnyCapabilityActive(MedallionTags::MedallionCoopFlyingActive))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Game::Mio.IsAnyCapabilityActive(MedallionTags::MedallionCoopFlyingActive))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateTriggerSplineEvents(Plane.GetFlyingSpline());
	}
	
	void UpdateTriggerSplineEvents(ASanctuaryBossMedallionSpline CurrentSpline)
	{
		if (!HasControl())
			return;
		if (!Plane.OnSplineEvent.IsBound())
			return;

		float PlaneCurrentDistance = Plane.AccSplineDistance.Value;
		for (int i = CurrentSpline.EventComponents.Num() -1; i >= 0; --i)
		{
			USanctuaryMedallionSplineEventComponent EventComp = CurrentSpline.EventComponents[i];
			
			// Cull some checks
			if (EventComp.DistanceAlongSpline > PlaneCurrentDistance + KINDA_SMALL_NUMBER)
			{
				CurrentSpline.EventComponents[i].bPlanePassed = false;
				continue;
			}
			if (EventComp.bPlanePassed)
				continue;

			bool bTriggerPlane = !EventComp.bPlanePassed && EventComp.DistanceAlongSpline < PlaneCurrentDistance;
			if (bTriggerPlane)
				NetSplineEvent(EventComp.EventType, EventComp.EventData);

			CurrentSpline.EventComponents[i].bPlanePassed = CurrentSpline.EventComponents[i].bPlanePassed || bTriggerPlane;
		}
	}

	UFUNCTION(NetFunction)
	void NetSplineEvent(ESanctuaryMedallionSplineEventType Type, FSanctuaryMedallionSplineEventData Data)
	{
		Plane.OnSplineEvent.Broadcast(Type, Data);
	}
};
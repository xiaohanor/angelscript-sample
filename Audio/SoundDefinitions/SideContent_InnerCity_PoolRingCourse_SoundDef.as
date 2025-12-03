
UCLASS(Abstract)
class USideContent_InnerCity_PoolRingCourse_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnCourseReset(FPoolRingEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnCourseCompleted(FPoolRingEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnCourseFailed(FPoolRingEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnRingActivated(FPoolRingEventParams Params){}

	/* END OF AUTO-GENERATED CODE */

	APoolRingCourseManager Manager;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Manager = Cast<APoolRingCourseManager>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	APoolRingActor GetClosestRing() const 
	{
		float bClosestRingDistance = MAX_flt;
		APoolRingActor ClosestRing = nullptr;

		for (auto Player: Game::Players)
		{
			for (auto Ring : Manager.LinkedRings)
			{
				auto Distance = Player.ActorLocation.DistSquared(Ring.ActorLocation);
				if (Distance < bClosestRingDistance)
				{
					bClosestRingDistance = Distance;
					ClosestRing = Ring;
				}
			}
		}

		if (ClosestRing != nullptr)
			return ClosestRing;

		return Manager.LinkedRings[0];
	}
}
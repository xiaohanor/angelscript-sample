
UCLASS(Abstract)
class UWorld_Island_Rift_Platform_IslandSpinningDanger_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> SpinningDangers;

	ASplineActor Spline;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter LaserMultiEmitter;

	TArray<FAkSoundPosition> LaserSoundPositions;
	default LaserSoundPositions.SetNum(2);

	TArray<FAkSoundPosition> SplineSoundPositions;
	default SplineSoundPositions.SetNum(2);

	private TMap<AHazeActor, UStaticMeshComponent> DangerLaserPanels;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{	
		Spline = Cast<ASplineActor>(HazeOwner);
	}

	// UFUNCTION(BlueprintOverride)
	// bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
	// 									FName& BoneName, bool& bUseAttach)
	// {
	// 	if(EmitterName == n"LaserMultiEmitter")
	// 	{
	// 		bUseAttach = false;
	// 		return false;
	// 	}
	// 	else
	// 	{
	// 		ComponentName = n"Spline";
	// 	}

	// 	return true;
	// }	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::GetPlayers())
		{	
			auto ClosestDanger = GetClosestLaserPanelForPlayer(Player);

			FVector ClosestPlayerPos;
			const float Dist = ClosestDanger.GetClosestPointOnCollision(Player.ActorLocation, ClosestPlayerPos);
			if(Dist < 0)
				ClosestPlayerPos = ClosestDanger.WorldLocation;

			LaserSoundPositions[Player.Player].SetPosition(ClosestPlayerPos);

			// Use spline position if on a spline, else just use closest player pos
			if(Spline != nullptr)
				SplineSoundPositions[Player.Player].SetPosition(Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation));
			else
				SplineSoundPositions[Player.Player].SetPosition(ClosestPlayerPos);
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SplineSoundPositions);
		LaserMultiEmitter.AudioComponent.SetMultipleSoundPositions(LaserSoundPositions);
	}

	private UStaticMeshComponent GetClosestLaserPanelForPlayer(AHazePlayerCharacter Player)
	{
		float ClosestDistSqrd = MAX_flt;
		AHazeActor ClosestDanger = nullptr;

		for(auto& SpinningDanger : SpinningDangers)
		{
			const float DistSqrd = SpinningDanger.ActorLocation.DistSquared(Player.ActorLocation);
			if(ClosestDanger == nullptr || DistSqrd < ClosestDistSqrd)
			{
				ClosestDanger = SpinningDanger;
				ClosestDistSqrd = DistSqrd;				
			}	
		}		

		UStaticMeshComponent LaserMeshComp = nullptr;
		if(DangerLaserPanels.Find(ClosestDanger, LaserMeshComp))
		{
			return LaserMeshComp;	
		}
		else
		{
			LaserMeshComp = UStaticMeshComponent::Get(ClosestDanger, n"Audio");
			DangerLaserPanels.Add(ClosestDanger, LaserMeshComp);
			return LaserMeshComp;
		}
	}
}
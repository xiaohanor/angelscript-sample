
UCLASS(Abstract)
class UWorld_RedSpace_Shared_Platforms_RedSpaceCube_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	bool bHasChildActors = false;

	TArray<UStaticMeshComponent> StaticMeshes;
	ARedSpaceCube RedSpaceCube;

	UFUNCTION(BlueprintEvent)
	void StartMoving(bool bMovingWithTimeLike) {};

	UFUNCTION(BlueprintEvent)
	void StartRotating(bool bRotatingWithTimeLike) {};

	UFUNCTION(BlueprintEvent)
	void StartScaling() {};

	TArray<FAkSoundPosition> SoundPositions;
	default SoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		RedSpaceCube = Cast<ARedSpaceCube>(HazeOwner);
		
		if (bHasChildActors)
		{
			TArray<AActor> AttachedActors;
			RedSpaceCube.GetAttachedActors(AttachedActors, false, false);

			if (AttachedActors.Num() > 0)
			{
				for (auto Actor: AttachedActors)
				{
					auto StaticMesh = UStaticMeshComponent::Get(Actor);
					if (StaticMesh != nullptr)
					{
						StaticMeshes.Add(StaticMesh);
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(RedSpaceCube.bMove && RedSpaceCube.bMoveFromStart)		
			StartMoving(RedSpaceCube.bMoveWithTimeLike);					

		if (RedSpaceCube.bRotate && RedSpaceCube.bRotateFromStart)
			StartRotating(RedSpaceCube.bRotateWithTimeLike);

		if (RedSpaceCube.bScale && RedSpaceCube.bScaleFromStart)
			StartScaling();		
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (StaticMeshes.Num() == 0)
		{
			for(auto Player : Game::GetPlayers())
			{
				FVector PlayerPos;
				const float Dist = RedSpaceCube.CubeMesh.GetClosestPointOnCollision(Player.ActorLocation, PlayerPos);
				if(Dist < 0)
					PlayerPos = RedSpaceCube.CubeMesh.WorldLocation;

				SoundPositions[int(Player.Player)].SetPosition(PlayerPos);
			}
		}
		else
		{
			// TArray<FVector> ClosestPositions;
			// ClosestPositions.SetNum(2);
			TArray<float> ClosestDistanceSqr;
			ClosestDistanceSqr.SetNum(2);

			for (int i=0; i < 2; ++i)
			{
				ClosestDistanceSqr[i] = MAX_flt;
			}

			for(auto Player : Game::GetPlayers())
			{
				FVector OutPosition;
				for (auto StaticMesh: StaticMeshes)
				{
					// Let's say the mesh can be removed before the SD.
					if (StaticMesh == nullptr)
						continue;

					int PlayerInt = int(Player.Player);

					auto Distance = StaticMesh.GetClosestPointOnCollision(Player.ActorLocation, OutPosition);

					// Get the best location for each player. Ignore invalid values from non collision objects.
					if (Distance >= 0 && Distance < ClosestDistanceSqr[PlayerInt])
					{
						ClosestDistanceSqr[PlayerInt] = Distance;
						SoundPositions[PlayerInt].SetPosition(OutPosition);
					}
				}
			}
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Moving Alpha"))
	float GetMovingAlpha()
	{	
		return RedSpaceCube.CachedMoveAlpha;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Rotation Alpha"))
	float GetRotationAlpha()
	{
		return RedSpaceCube.CachedRotationAlpha;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Scale Alpha"))
	float GetScaleAlpha()
	{
		return RedSpaceCube.CachedScaleAlpha;
	}
}
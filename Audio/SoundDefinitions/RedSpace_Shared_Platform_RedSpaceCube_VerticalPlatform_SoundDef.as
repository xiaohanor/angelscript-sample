
UCLASS(Abstract)
class URedSpace_Shared_Platform_RedSpaceCube_VerticalPlatform_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

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
		for(auto Player : Game::GetPlayers())
		{
			FVector PlayerPos;
			const float Dist = RedSpaceCube.CubeMesh.GetClosestPointOnCollision(Player.ActorLocation, PlayerPos);
			if(Dist < 0)
				PlayerPos = RedSpaceCube.CubeMesh.WorldLocation;

			SoundPositions[int(Player.Player)].SetPosition(PlayerPos);
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

UCLASS(Abstract)
class URedSpace_Platform_Shared_RedSpaceCube_Group_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ARedSpaceCubeGroup CubeGroup;

	TArray<FAkSoundPosition> SoundPositions;
	default SoundPositions.SetNum(2);

	TArray<FVector> PreviousPlayerSoundPositions;
	default PreviousPlayerSoundPositions.SetNum(2);

	const float INTERPOLATION_SPEED = 2000;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		CubeGroup = Cast<ARedSpaceCubeGroup>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto Player : Game::GetPlayers())
		{
			PreviousPlayerSoundPositions[int(Player.Player)] = CubeGroup.Cubes[0].CubeMesh.WorldLocation;		
		}
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Move Alpha"))
	float GetPrimaryCubeMoveAlpha()
	{
		return CubeGroup.Cubes[0].CachedMoveAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::GetPlayers())
		{
			float ClosestPlayerDistSqrd = MAX_flt;
			ARedSpaceCube ClosestPlayerCube = nullptr;

			for(auto Cube : CubeGroup.Cubes)
			{
				const float CubePlayerDistSqrd = Cube.CubeMesh.WorldLocation.DistSquared(Player.ActorLocation);

				if(CubePlayerDistSqrd < ClosestPlayerDistSqrd)
				{
					ClosestPlayerDistSqrd = CubePlayerDistSqrd;
					ClosestPlayerCube = Cube;
				}		
			}

			FVector ClosestCubePlayerPos;
			const float Dist = ClosestPlayerCube.CubeMesh.GetClosestPointOnCollision(Player.ActorLocation, ClosestCubePlayerPos);
			if(Dist < 0)
				ClosestCubePlayerPos = ClosestPlayerCube.CubeMesh.WorldLocation;

			const FVector PreviousPlayerSoundPosition = PreviousPlayerSoundPositions[int(Player.Player)];
			if(!PreviousPlayerSoundPosition.IsZero())
			{
				const FVector LerpedPlayerSoundPosition = Math::VInterpConstantTo(PreviousPlayerSoundPosition, ClosestCubePlayerPos, DeltaSeconds, INTERPOLATION_SPEED);
				ClosestCubePlayerPos = LerpedPlayerSoundPosition;
			}

			SoundPositions[int(Player.Player)].SetPosition(ClosestCubePlayerPos);
			PreviousPlayerSoundPositions[int(Player.Player)] = ClosestCubePlayerPos;
		}	

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
	}
}
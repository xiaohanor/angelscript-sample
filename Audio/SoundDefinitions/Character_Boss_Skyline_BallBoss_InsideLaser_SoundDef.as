
UCLASS(Abstract)
class UCharacter_Boss_Skyline_BallBoss_InsideLaser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASkylineBallBossInsideLaser Laser;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve DistanceCurve; 

	TArray<UStaticMeshComponent> LaserMeshes;
	default LaserMeshes.SetNum(3);

	TArray<FAkSoundPosition> LaserPositions;
	default LaserPositions.SetNum(3);

	UPROPERTY(BlueprintReadOnly)
	float ClosestMioDistance = 0.0;

	// /Script/Engine.StaticMesh'/Game/Environment/LevelSpecific/Skyline/BallBoss_01/BallBoss_01_Laser_A.BallBoss_01_Laser_A'
	const float LASER_MESH_RADIUS = 900;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Laser = Cast<ASkylineBallBossInsideLaser>(HazeOwner);

		LaserMeshes[0] = UStaticMeshComponent::Get(Laser, n"LaserMesh1");
		LaserMeshes[1] = UStaticMeshComponent::Get(Laser, n"LaserMesh2");
		LaserMeshes[2] = UStaticMeshComponent::Get(Laser, n"LaserMesh3");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector MioLocation = Game::GetMio().ActorLocation;
		float ClosestMioDistanceSqrd = MAX_flt;

		for(int i = 0; i < 3; ++i)
		{
			FVector MioLocationOnShockwave = LaserMeshes[i].WorldTransform.InverseTransformPosition(MioLocation);
			MioLocationOnShockwave.Y = 0.0;		
																						
			FVector MioLocationOnShockwaveEdge = MioLocationOnShockwave.GetSafeNormal() * LASER_MESH_RADIUS;
			MioLocationOnShockwaveEdge.Z = Math::Abs(MioLocationOnShockwaveEdge.Z);
			FVector MioLocationOnShockwaveEdgeWorldSpace = LaserMeshes[i].WorldTransform.TransformPosition(MioLocationOnShockwaveEdge);		
			LaserPositions[i].SetPosition(MioLocationOnShockwaveEdgeWorldSpace);

			const float MioDstSqrd = MioLocationOnShockwaveEdgeWorldSpace.DistSquared(MioLocation);
			if(MioDstSqrd < ClosestMioDistanceSqrd)
			{
				ClosestMioDistanceSqrd = MioDstSqrd;
			}
		}	

		ClosestMioDistance = Math::Sqrt(ClosestMioDistanceSqrd);
		DefaultEmitter.SetMultiplePositions(LaserPositions);
	}

}
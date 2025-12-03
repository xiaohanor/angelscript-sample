
UCLASS(Abstract)
class UCharacter_Boss_Skyline_BallBoss_Laser_Shockwave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */
	
	ASkylineBallBossShockwave LaserShockwave;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve DistanceCurve; 

	///Script/Engine.StaticMesh'/Game/Effects/Meshes/SM_Shockwave_02.SM_Shockwave_02'
	const float LASER_MESH_RADIUS = 104.5;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LaserShockwave = Cast<ASkylineBallBossShockwave>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector MioLocation = Game::GetMio().GetActorLocation();
		FVector MioLocationOnShockwave = LaserShockwave.ShockwaveMeshComp.WorldTransform.InverseTransformPosition(MioLocation);
		MioLocationOnShockwave.Z = 0.0;
		
		FVector MioLocationOnShockwaveEdge = MioLocationOnShockwave.GetSafeNormal() * LASER_MESH_RADIUS;
		FVector MioLocationOnShockwaveEdgeWorldSpace = LaserShockwave.ShockwaveMeshComp.WorldTransform.TransformPosition(MioLocationOnShockwaveEdge);		
		DefaultEmitter.SetEmitterLocation(MioLocationOnShockwaveEdgeWorldSpace);
	}

}
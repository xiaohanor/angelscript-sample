
UCLASS(Abstract)
class UWorld_Meltdown_Shared_Ambience_Event_ChaseGlitch_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Started(){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownWorldSpinChaseActor ChaseActor;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ChaseActor = Cast<AMeltdownWorldSpinChaseActor>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector ClosestChaseZoePos;
		const float Dist = ChaseActor.Mesh.GetClosestPointOnCollision(Game::Zoe.ActorLocation, ClosestChaseZoePos);
		if(Dist < 0)
			ClosestChaseZoePos = ChaseActor.Mesh.WorldLocation;

		DefaultEmitter.SetEmitterLocation(ClosestChaseZoePos, true);
	}
}
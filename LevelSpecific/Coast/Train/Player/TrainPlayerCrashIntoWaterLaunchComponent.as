class UTrainPlayerCrashIntoWaterLaunchComponent : UActorComponent
{
	AActor ActorToLaunchTo = nullptr;
	bool bBlockCollisionWhenLaunched = false;
	float CollisionBlockDuration;
};